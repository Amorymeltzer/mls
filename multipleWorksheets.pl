#!/usr/bin/env perl
# multipleWorksheets.pl by Amory Meltzer
# Process boxscores into master set of stats

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );
use Spreadsheet::Read;
use Storable qw(dclone);


# Threshold for inclusion in graphs and tables, see &noScrubs
my $threshold = 0.15;
# Number of dates to track running values
# Also used in makeMLSTable.pl, so if this changes update that too
my $lookback = 17;


if (@ARGV != 1) {
  print "Usage: $PROGRAM_NAME MLS_Stats.xlsx\n";
  print "Should only be run via build_site.sh\n";
  exit;
}

print "Parsing $ARGV[0] for data...\n\n";
my $book = ReadData ($ARGV[0]) or die $ERRNO;

# Master lists
my %masterData;	     # Hash holding per-player stat data [total, current game]
my @masterPlayers;   # Player names
my @masterDates;     # Dates of play
my %masterPlayerCount;		# Count times a player is used
my @runningDates;		# Running list of dates, used in conjunction
my %runningDatesLookup;		# with this lookup array to check dates
my %runningData;		# Lazily check if we've seen a player before
                                # FIXME TODO
my $runningData;		# Array since copying a multi-dim hash
                                # requires deep-cloning and references
my @runningPlayers;		# Running list of players
my %runningPlayerCount;		# Did those running players actually play
# Season lookup.  Would be easy to substring, but this also means I get all
# seasons as a nice keys array
my %seasons = (
	       spring => 's',
	       summer => 'u',
	       fall => 'f');
my %seasonsList;		# Unique list of seasons that need parsing

# Grab, parse, and arrange all sheet names taken from the initial hash.  Sort
# required to keep order the same across games, so players who missed games
# don't move around
foreach (sort keys %{$book->[0]{'sheet'}}) {
  #print "$_\n";
  my @tmp = split / /;
  my $seas = "$tmp[0] $tmp[1]";
  my $game = $tmp[2];

  if ($seas =~ /Tournament/) {
    $seas = "$tmp[0] $tmp[1] $tmp[2]";
    $game = $seas;
  } else {
    # Sneak in here to anticipate the full gamut of non-tournament game
    # dates. This is a minor duplicates of the &createName process to make use
    # of the schwartzian transform in order to ensure we get only the most
    # recent games.  Honestly, this wouldn't be a bad idea for @masterDates,
    # but it's not horrific doing it this way.
    my $run = substr $tmp[1], -2;
    $run = "$tmp[2].$run";
    push @runningDates, $run;
  }

  if (!$seasonsList{$seas}) {
    $seasonsList{$seas} = [$game];
  } else {
    push @{$seasonsList{$seas}}, $game;
  }
}

schwartz(\@runningDates);		# Sort running dates
@runningDates = @runningDates[-$lookback..-1];	# Keep only the ones I care about.
                                        # Should probably make this a variable
                                        # somewhere FIXME TODO
# Build lookup list of running dates via hash slice
@runningDatesLookup{@runningDates} = ();


# Murderers' Row
my @lineup = (
	      'Andrew Burch',
	      'Qaiser Patel',
	      'Oliver Patton',
	      'Luke Heuer',
	      'Joe Edwards',
	      'Rich Squitieri',
	      'Nick Mirman',
	      'Derek Bayes',
	      'Nick Hanten',
	      'Nick Hurlburt',
	      'Charlie Henschen',
	      'Scott Richardson',
	      'Amory Meltzer',
	      'Gordon Walker',
	      'Andrew Scott',
	     );
# Stats measured, for building the player hash
my @stats = qw (Player AB R H 2B 3B HR TB RBI BB K SAC AVG OBP SLG ISO OPS GPA wOBA);

print "Data found:\n";
foreach (sort keys %seasonsList) {
  print "$_:\t@{$seasonsList{$_}}\n";
  my %playerData;    # Hash holding per-player stat data [total, current game]
  my @players;	     # Player names
  my @dates;	     # Dates of play
  my %playerCount;   # Count time a player is used

  # 1 if match, nada if not
  my $tournament = /Tournament/;
  # Get each individual game info
  while (@{$seasonsList{$_}}) {
    my $date = shift @{$seasonsList{$_}};
    my ($season,$year) = split / /;
    my $gameDate = "$date.".substr $year, 2;

    $gameDate = $date if $tournament;

    # Keep track of time
    push @dates, $gameDate;
    push @masterDates, $gameDate if !$tournament;

    # Pull out corresponding worksheet for the individual game
    my %gameData;
    if ($tournament) {		# Tourny names are parsed differently
      %gameData = %{$book->[$book->[0]{sheet}{"$date"}]};
    } else {
      %gameData = %{$book->[$book->[0]{sheet}{"$season $year $date"}]};
    }


    # Inverted from how I think about rows/columns.  Value essentially means
    # how far they go, i.e. maxrow of 5 means rows extend 5 places to column E
    my $rowN = $gameData{'maxrow'};
    my $colN = $#stats;		# 1 less than the number of elements in @stats

    ## Dump per-game totals (basically a copy of %gameData)
    my $gameOutfile = createName($_,$date,$tournament);
    open my $gameCsv, '>', "$gameOutfile" or die $ERRNO;
    print $gameCsv join q{,}, @stats;

    # In order to properly correlate two arrays with different indices, one of
    # which changes halfway through, we need a way to keep track.  Starts at
    # 2, changes to 1 halfway through, resets to 2 on a new row.
    my $offset = 2;
    my $player;
    # Build player-data hash (of hash of arrays)
    for my $r (1..$rowN) {
      for my $c (1..$colN) {
	my $cell = $gameData{'cell'}[$c][$r]; # Just easier to remember
	if ($r == 1) {			      # Hardcoded above in @stats
	  # Attempt to detect extra columns
	  if (($c <= 7 and $cell ne $stats[$c-1]) || ($c > 7 and $c < 12 and $cell ne $stats[$c]) || ($c >= 12 and $cell)) {
	    die "FATAL error: Potential extra columns detected in $date!!!\n";
	  }
	  next;
	} elsif ($c == 1) {
	  # Ignore the last row, for now
	  print $gameCsv "\n$cell" if $r != $rowN;
	  # Define current player for entire row, saves issue of duplicating
	  # and polluting @players
	  $player = $cell;

	  # Die angrily if final row isn't totals, can't proceed
	  if ($player ne 'Total:' && $r == $rowN) {
	    die "FATAL error: Totals not found in $date!!!\n";
	  }

	  # Build player array.  Only append if it's a new player, otherwise
	  # we should just clear-out the current game array
	  if (! $playerData{$cell}) {
	    push @players, $cell;
	    # Keep totals last
	    if ($players[-2] && $players[-2] =~ /Total/) {
	      @players[-2,-1] = @players[-1,-2];
	    }
	    $playerCount{$cell} = 1; # First time up
	  } else {
	    @{$playerData{$cell}{$gameDate}} = ();
	    $playerCount{$cell}++; # Add a count if we've seen him
	  }

	  # Do the same for the master list of players
	  if (!$tournament && !$masterData{$cell}) {
	    push @masterPlayers, $cell;
	    # Keep totals last
	    if ($masterPlayers[-2] && $masterPlayers[-2] =~ /Total/) {
	      @masterPlayers[-2,-1] = @masterPlayers[-1,-2];
	    }
	    $masterPlayerCount{$cell} = 1; # First time up
	  } elsif (!$tournament && $masterData{$cell}) {
	    $masterPlayerCount{$cell}++; # Add a count if we've seen him
	  }

	  # Lazy use of %runningData
	  if (!$tournament && !$runningData{$cell}) {
	    push @runningPlayers, $cell if exists $runningDatesLookup{$gameDate};

	    if ($runningPlayers[-2] && $runningPlayers[-2] =~ /Total/) {
	      @runningPlayers[-2,-1] = @runningPlayers[-1,-2] if exists $runningDatesLookup{$gameDate};
	    }
	    $runningPlayerCount{$cell} = 1 if exists $runningDatesLookup{$gameDate}; # First time up
	  } elsif (!$tournament && $runningData{$cell}) {
	    $runningPlayerCount{$cell}++ if exists $runningDatesLookup{$gameDate}; # Add a count if we've seen him
	  }

	  $offset = 2;		# Reset on new row
	  next;
	}

	if ($c >= 12) {
	  # Calculate total first, so we don't overlap
	  $cell = calcStats($c,\@{$playerData{$player}{'total'}});
	  $playerData{$player}{'total'}[$c-$offset] = $cell;

	  # I want to use %masterData for the calculations, but we have to
	  # first establish that data before we can use it.  Not using ternary
	  # 'cause it's too damn ugly
	  if ($masterData{$player}{'total'}[$c-$offset]) {
	    $cell = calcStats($c,\@{$masterData{$player}{'total'}});
	  } else {
	    $cell = calcStats($c,\@{$playerData{$player}{'total'}});
	  }
	  $masterData{$player}{'total'}[$c-$offset] = $cell if !$tournament;

	  # Calculate for the given gameDate to append
	  $cell = calcStats($c,\@{$playerData{$player}{$gameDate}});
	} else {
	  if ($gameData{'cell'}[$c][$r]) {
	    $playerData{$player}{'total'}[$c-$offset] += $cell;
	    $masterData{$player}{'total'}[$c-$offset] += $cell if !$tournament;
	  } else {
	    $playerData{$player}{'total'}[$c-$offset] += 0;
	    $masterData{$player}{'total'}[$c-$offset] += 0 if !$tournament;
	  }
	}
	push @{$playerData{$player}{$gameDate}}, $cell;
	if (!$tournament) {
	push @{$masterData{$player}{$gameDate}}, $cell;
	push @{$runningData{$player}{$gameDate}}, $cell if exists $runningDatesLookup{$gameDate};
      }

	# Ignore the last row, for now
	print $gameCsv ",$cell" if $r != $rowN;

	# Build Total Bases stat.  Basically, after doing the above for HR,
	# run through a special scenario to build up TB and insert it into the
	# array.  Of course, we have to decrement the offset to keep everybody
	# on the same page.
	if ($c == 7) {
	  $offset = 1;
	  # TB=H+2B+2*3B+3*4B
	  $cell = $playerData{$player}{$gameDate}[2] + $playerData{$player}{$gameDate}[3] + (2 * $playerData{$player}{$gameDate}[4]) + (3 * $playerData{$player}{$gameDate}[5]);
	  $playerData{$player}{'total'}[$c-$offset] += $cell;
	  push @{$playerData{$player}{$gameDate}}, $cell;

	  if (!$tournament) {
	    $masterData{$player}{'total'}[$c-$offset] += $cell;
	    push @{$masterData{$player}{$gameDate}}, $cell;
	  }
	  # Ignore the last row, for now
	  print $gameCsv ",$cell" if $r != $rowN;
	}
      }
    }
    # Print out last row.  Act all cocky 'n shit by using @players
    print $gameCsv "\n$players[-1],";
    print $gameCsv join q{,}, @{$playerData{$players[-1]}{$gameDate}};
    print $gameCsv "\n";
    close $gameCsv or die $ERRNO;
  }

  # Don't treat tournaments as part of a season
  next if $tournament;

  @players = noScrubs(\%playerCount,\@players,\@dates,$threshold);
  @players = lineup(\@lineup,\@players);
  ## Dump season totals (identical to old-style format)
  my $seasonOutfile = createName($_,q{},0);
  open my $seasonCsv, '>', "$seasonOutfile" or die $ERRNO;
  print $seasonCsv join q{,}, @stats;
  print $seasonCsv "\n";
  foreach my $dude (@players) {
    print $seasonCsv "$dude,";
    print $seasonCsv join q{,}, @{$playerData{$dude}{'total'}};
    print $seasonCsv "\n";
  }
  close $seasonCsv or die $ERRNO;

  # Sort dates
  schwartz(\@dates);
  my ($seasonSuffix) = $seasonOutfile =~ s/.*mls_(\w\d\d).*/$1/r;
  # Dump per-game values for each stat in each season
  foreach my $i (1..scalar @stats - 1) {
    open my $stat, '>', "$stats[$i]_$seasonSuffix.csv" or die $ERRNO;
    print $stat 'Date,';
    print $stat join q{,}, @players[0..$#players-1]; # Don't include totals
    print $stat "\n";
    # Set baseline of zero for cumulative stats
    if ($i < 12) {
      my $length = $#players;
      print $stat 'Start,';
      print $stat join q{,}, (0) x $length;
      print $stat "\n";
    }

    foreach my $j (0..scalar @dates - 1) {
      # Try to cut down on noise by skipping the first data point of each
      # calculated stat in a given season (skip first 2 in master data)
      next if ($j == 0 and $i >= 12);

      print $stat "$dates[$j]";
      foreach my $dude (@players[0..$#players-1]) {
	# PITA technique to try to get null values for nonexistant games and
	# zero values for missed games or non-calculated stats
	if (!$playerData{$dude}{$dates[$j]}[$i-1]) {
	  if (!$playerData{$dude}{$dates[$j-1]}[$i-1]) {
	    if ($i >= 12) {
	      print $stat q{,NaN};
	    } else {
	      print $stat q{,0};
	      $playerData{$dude}{$dates[$j]}[$i-1] = 0;
	    }
	    next;
	  } else {
	    # Original value if defined, 0 if not
	    $playerData{$dude}{$dates[$j]}[$i-1] ||= 0;
	  }
	}

	# Awkward kludge to add data, destructive but at the end so not an issue
	if ($i >= 12) {
	  # $i is different than $c above thanks to $offset
	  $playerData{$dude}{$dates[$j]}[$i-1] = calcStats($i,\@{$playerData{$dude}{$dates[$j]}});
	} else {
	  $playerData{$dude}{$dates[$j]}[$i-1] += $playerData{$dude}{$dates[$j-1]}[$i-1] if $j != 0;
	}
	print $stat ",$playerData{$dude}{$dates[$j]}[$i-1]";
      }
      print $stat "\n";
    }
    close $stat or die $ERRNO;
  }
}

# Just a sort of visual check that no spelling errors were introduced.  It
# should be obvious if I implement the player pages, but this is nice to have
print "\nMurderer's Row:\n";
foreach (sort @masterPlayers) {
  print "$_\t$masterPlayerCount{$_}\n";
}
my $min=$threshold*$masterPlayerCount{$masterPlayers[-1]};
print "\nMinimum for inclusion in lifetime:\t$min\n";
print "\nRunner's Row:\n";
foreach (sort @runningPlayers) {
  print "$_\t$runningPlayerCount{$_}\n";
}
my $rmin=$threshold*$runningPlayerCount{$runningPlayers[-1]};
print "\nMinimum for inclusion in running:\t$rmin\n";

######### FIXME TODO
# SUBROUTINE EVERYTHING ie master and running shit
######### FIXME TODO

################################################################################
$runningData = dclone(\%masterData);

# Writ of Attainder on Matt Turner, since he mucks up the low end and doesn't
# play anymore.  This should be temporary FIXME TODO
my $index = 0;
for (@runningPlayers) {
  if ($_ eq 'Matt Turner') {
    splice @runningPlayers, $index, 1;
    last;
  } else {
    $index++;
  }
}

@runningPlayers = noScrubs(\%runningPlayerCount,\@runningPlayers,\@runningDates,$threshold);
@runningPlayers = lineup(\@lineup,\@runningPlayers);

# Sort dates again?  Left in because there's a good chance I can/should
# subroutine this, so I'd like to keep it all as it should be FIXME TODO
schwartz(\@runningDates);
# Dump lifetime per-game values for each stat
foreach my $i (1..scalar @stats - 1) {
  open my $stat, '>', "running_$stats[$i].csv" or die $ERRNO;
  print $stat 'Date,';
  print $stat join q{,}, @runningPlayers[0..$#runningPlayers-1]; # Don't include totals
  print $stat "\n";
  # Set baseline of zero for cumulative stats
  if ($i < 12) {
    my $length = $#runningPlayers;
    print $stat 'Start,';
    print $stat join q{,}, (0) x $length;
    print $stat "\n";
  }

  foreach my $j (0..scalar @runningDates - 1) {
    # Try to cut down on noise by skipping the first two data points of each
    # calculated stat (skip just first 1 in each season)
    # Doesn't deal with people who weren't around at first, they'll still have
    # gaps. FIXME TODO
    next if ($j <= 1 and $i >= 12);

    print $stat "$runningDates[$j]";
    foreach my $dude (@runningPlayers[0..$#runningPlayers-1]) { # Ignore totals
      # PITA technique to try to get null values for nonexistant games and
      # zero values for missed games or non-calculated stats
      if (!${$runningData}{$dude}{$runningDates[$j]}[$i-1]) {
	if (!${$runningData}{$dude}{$runningDates[$j-1]}[$i-1]) {
	  if ($i >= 12) {
	    print $stat q{,NaN};
	  } else {
	    print $stat q{,0};
	    ${$runningData}{$dude}{$runningDates[$j]}[$i-1] = 0;
	  }
	  next;
	} else {
	  # Original value if defined, 0 if not
	  ${$runningData}{$dude}{$runningDates[$j]}[$i-1] ||= 0;
	}
      }

      # Awkward kludge to add data, destructive but at the end so not an issue
      if ($i >= 12) {
	# $i is different than $c above thanks to $offset
	${$runningData}{$dude}{$runningDates[$j]}[$i-1] = calcStats($i,\@{${$runningData}{$dude}{$runningDates[$j]}});
      } else {
	${$runningData}{$dude}{$runningDates[$j]}[$i-1] += ${$runningData}{$dude}{$runningDates[$j-1]}[$i-1] if $j != 0;
      }
      print $stat ",${$runningData}{$dude}{$runningDates[$j]}[$i-1]";
    }
    print $stat "\n";
  }
  close $stat or die $ERRNO;
}

## Create and dump running totals
open my $runningCsv, '>', 'mls_running.csv' or die $ERRNO;
print $runningCsv join q{,}, @stats;
print $runningCsv "\n";
foreach my $dude (@runningPlayers) {
  print $runningCsv "$dude,";
  foreach my $i (0..scalar @stats - 1) {
    ${$runningData}{$dude}{'total'}[$i] = 0; # Reset to start new running calc
    foreach my $j (0..scalar @runningDates - 1) {
      if ($i <= 11) {
	# Note the hybrid use of %masterData and @runningDates.  This is just
	# a check to ensure no null values (don't need to muck about with NaN)
	# but given my annoying reliance on %masterData in the =+ calculation,
	# it seems appropxiate FIXME TODO
	if (!$masterData{$dude}{$runningDates[$j]}[$i]) {
	  ${$runningData}{$dude}{'total'}[$i] += 0;
	  next;
	}

	${$runningData}{$dude}{'total'}[$i] += $masterData{$dude}{$runningDates[$j]}[$i];
      } else {
	# Note the index change below

	# Take care of players joining late or leaving early
	if (!${$runningData}{$dude}{$runningDates[$j]}[$i]) {
	  ${$runningData}{$dude}{'total'}[$i-1] = 0;
	  next if $i != $#stats;
	}
	${$runningData}{$dude}{'total'}[$i-1] = calcStats($i,\@{${$runningData}{$dude}{$runningDates[$j]}});
      }
    }
  }
  pop @{${$runningData}{$dude}{'total'}};
  print $runningCsv join q{,}, @{${$runningData}{$dude}{'total'}};
  print $runningCsv "\n";
}
close $runningCsv or die $ERRNO;


################################################################################

@masterPlayers = noScrubs(\%masterPlayerCount,\@masterPlayers,\@masterDates,$threshold);
@masterPlayers = lineup(\@lineup,\@masterPlayers);
## Dump lifetime totals (same format as season totals)
open my $masterCsv, '>', 'mls_master.csv' or die $ERRNO;
print $masterCsv join q{,}, @stats;
print $masterCsv "\n";
foreach my $dude (@masterPlayers) {
  print $masterCsv "$dude,";
  print $masterCsv join q{,}, @{$masterData{$dude}{'total'}};
  print $masterCsv "\n";
}
close $masterCsv or die $ERRNO;


# Sort dates
schwartz(\@masterDates);
# Dump lifetime per-game values for each stat
foreach my $i (1..scalar @stats - 1) {
  open my $stat, '>', "$stats[$i].csv" or die $ERRNO;
  print $stat 'Date,';
  print $stat join q{,}, @masterPlayers[0..$#masterPlayers-1]; # Don't include totals
  print $stat "\n";
  # Set baseline of zero for cumulative stats
  if ($i < 12) {
    my $length = $#masterPlayers;
    print $stat 'Start,';
    print $stat join q{,}, (0) x $length;
    print $stat "\n";
  }

  foreach my $j (0..scalar @masterDates - 1) {
    # Try to cut down on noise by skipping the first two data points of each
    # calculated stat (skip just first 1 in each season)
    # Doesn't deal with people who weren't around at first, they'll still have
    # gaps. FIXME TODO
    next if ($j <= 1 and $i >= 12);

    print $stat "$masterDates[$j]";
    foreach my $dude (@masterPlayers[0..$#masterPlayers-1]) { # Ignore totals
      # PITA technique to try to get null values for nonexistant games and
      # zero values for missed games or non-calculated stats
      if (!$masterData{$dude}{$masterDates[$j]}[$i-1]) {
	if (!$masterData{$dude}{$masterDates[$j-1]}[$i-1]) {
	  if ($i >= 12) {
	    print $stat q{,NaN};
	  } else {
	    print $stat q{,0};
	    $masterData{$dude}{$masterDates[$j]}[$i-1] = 0;
	  }
	  next;
	} else {
	  # Original value if defined, 0 if not
	  $masterData{$dude}{$masterDates[$j]}[$i-1] ||= 0;
	}
      }

      # Awkward kludge to add data, destructive but at the end so not an issue
      if ($i >= 12) {
	# $i is different than $c above thanks to $offset
	$masterData{$dude}{$masterDates[$j]}[$i-1] = calcStats($i,\@{$masterData{$dude}{$masterDates[$j]}});
      } else {
	$masterData{$dude}{$masterDates[$j]}[$i-1] += $masterData{$dude}{$masterDates[$j-1]}[$i-1] if $j != 0;
      }
      print $stat ",$masterData{$dude}{$masterDates[$j]}[$i-1]";
    }
    print $stat "\n";
  }
  close $stat or die $ERRNO;
}


#### Subroutines
# Build an appropriate name
sub createName
  {
    my ($label,$datum,$tourny) = @_;
    my $name = 'mls_';

    # Tournament
    $name .= 't' if $tourny;
    # Season
    my $re = join q{|}, keys %seasons;
    my ($season) = $label =~ /\b($re)\b/i;

    # Error handling if a poorly-named worksheet is encountered
    if (!$season) {
      print "Worksheet '$label' improperly named, skipping...\n";
      return 1;
    }

    $name .= $seasons{lc $season};
    # Year
    my ($curYear) = $label =~ /(\d+)/;
    $name .= substr $curYear, 2;
    # Only append gamedate if appropriate
    if (!$tourny && $datum) {
      $name .= "_$datum";
    }

    return "$name.csv";		# Extension
  }


# Calc stats
sub calcStats
  {
    my ($c,$playerRef) = @_;
    my $cell;

    # Used repeatedly, good to have available, makes below prettier
    # PA=AB+BB+SAC
    my $PA = ${$playerRef}[0] + ${$playerRef}[8] + ${$playerRef}[10];
    # TB=H+2B+2*3B+3*4B, calculated previously
    my $TB = ${$playerRef}[6];

    # Ternary ?: ($a = $test ? $b : $c;)
    # a is b if test, c if not
    if ($c == 12) {		# AVG = H/AB
      $cell = !${$playerRef}[0] ? 0 : ${$playerRef}[2] / ${$playerRef}[0];
    } elsif ($c == 13) {	# OBP = (H+BB)/PA
      $cell = !$PA ? 0 : (${$playerRef}[2] + ${$playerRef}[8]) / $PA;
    } elsif ($c == 14) {	# SLG = Total bases/AB
      $cell = !${$playerRef}[0] ? 0 : $TB / ${$playerRef}[0];
    } elsif ($c == 15) {	# ISO = SLG-AVG
      $cell = ${$playerRef}[13] - ${$playerRef}[11];
    } elsif ($c == 16) {	# OPS = OBP+SLG
      $cell = ${$playerRef}[12] + ${$playerRef}[13];
    } elsif ($c == 17) {	# GPA = (1.8*OBP+SLG)/4
      $cell = (1.8*${$playerRef}[12] + ${$playerRef}[13])/4;
    } elsif ($c == 18) {	# wOBA
      $cell = !$PA ? 0 : calcwOBA(\@{$playerRef}) / $PA;
    }
    return sprintf '%.3f', $cell; # Prettify to three decimals
  }


# Calculate wOBA scores.  Pulled out here to make adjusting weights easier and
# so on.  This uses values from 2010.  Other data sources include:
# Original values from The Book: 0.72 0.90 1.241.56 1.95
# Through 2008: http://tangotiger.net/bdb/lwts_woba_for_bdb.txt
# Through 2010: http://www.beyondtheboxscore.com/2011/1/4/1912914/custom-woba-and-linear-weights-through-2010-baseball-databank-data
# FanGraphs: http://www.fangraphs.com/guts.aspx?type=cn
# Personal calculator: http://www.hardballtimes.com/tht-live/woba-calculator/
# Also: https://docs.google.com/spreadsheets/d/1AOJekprrMTChBvPw9VJMBR1oaBHKYPY9PRmnySB8HcM/pub?gid=0#
# And: http://www.tangotiger.net/bsrexpl.html
# And: http://blog.philbirnbaum.com/2009/10/dont-use-regression-to-calculate-linear.html
sub calcwOBA
  {
    my $hashRef = shift;
    my ($BB,$B1,$B2,$B3,$HR) = qw (0.70 0.89 1.27 1.61 2.07);

    my $hits = ${$hashRef}[2] - ${$hashRef}[3] - ${$hashRef}[4] - ${$hashRef}[5];
    return $BB*${$hashRef}[8] + $B1*$hits + $B2*${$hashRef}[3] + $B3*${$hashRef}[4] + $HR*${$hashRef}[5];
  }


# American dates are dumb, sort on YY/MM/DD
# Schwartzian transform
sub schwartz
  {
    my $ref = shift;
    @{$ref} =
      map {$_->[0]}
      sort { $a->[1] cmp $b->[1] }
      map {[$_, join q{}, (split /\./)[2,0,1]]}
      @{$ref};
  }

# Limit stats to players who have played in a bare minimum of games
sub noScrubs
  {
    my ($countRef,$playerRef,$dateRef,$thresh) = @_;
    my @return;
    my $max = scalar @{$dateRef}; # Number of games in the season

    foreach (@{$playerRef}) {
      push @return, $_ if (${$countRef}{$_} / $max >= $thresh);
    }

    return @return;
  }

# List players according to Joe's masterful lineup
sub lineup
  {
    my ($orderRef,$playerRef) = @_;
    my @return;
    my %orderMap = map { ${$orderRef}[$_] => $_ } 0..$#{$orderRef};
    my %confirm = map { $_ => 1 } @{$playerRef};

    # Place everybody appropriately
    foreach (@{$orderRef}) {
      push @return, $_ if (defined $orderMap{$_} and defined $confirm{$_});
    }

    # Throw anybody new at the end
    foreach (@{$playerRef}) {
      push @return, $_ if !defined $orderMap{$_};
    }

    return @return;
  }
