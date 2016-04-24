#!/usr/bin/env perl
# multipleWorksheets.pl by Amory Meltzer
# Process boxscores into master set of stats

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );
use Spreadsheet::Read;


# Threshold for inclusion in graphs and tables, see &noScrubs
my $threshold = 0.25;


if (@ARGV != 1) {
  print "Usage: $PROGRAM_NAME MLS_Stats.xlsx\n";
  exit;
}

print "Parsing $ARGV[0] for data...\n\n";
my $book = ReadData ($ARGV[0]) or die $ERRNO;

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
  my @tmp = split / /;
  my $seas = "$tmp[0] $tmp[1]";
  my $game = $tmp[2];

  if ($seas =~ /Tournament/) {
    $seas = "$tmp[0] $tmp[1] $tmp[2]";
    $game = $seas;
  }

  if (!$seasonsList{$seas}) {
    $seasonsList{$seas} = [$game];
  } else {
    push @{$seasonsList{$seas}}, $game;
  }
}


# Stats measured, for building the player hash
my @stats = qw ("Player" AB R H 2B 3B HR TB RBI BB K SAC AVG OBP SLG ISO OPS GPA wOBA);
# Master lists
my %masterData;	     # Hash holding per-player stat data [total, current game]
my @masterPlayers;   # Player names
my @masterDates;     # Dates of play
my %masterPlayerCount;		# Count times a player is used

print "Data found:\n";
foreach (sort keys %seasonsList) {
  print "Season: $_\t Items: @{$seasonsList{$_}}\n";
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
    if ($tournament) {	# Tourny names are parsed differently
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
	  warn "Warning: Potential extra columns detected!!\n" if ($c == 1 and $cell ne 'Player');
	  next;
	} elsif ($c == 1) {
	  # Ignore the last row, for now
	  print $gameCsv "\n\"$cell\"" if $r != $rowN;
	  # Define current player for entire row, saves issue of duplicating
	  # and polluting @players
	  $player = $cell;
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
	push @{$masterData{$player}{$gameDate}}, $cell if !$tournament;

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
    print $gameCsv "\n\"$players[-1]\",";
    print $gameCsv join q{,}, @{$playerData{$players[-1]}{$gameDate}};
    close $gameCsv or die $ERRNO;
  }

  # Don't treat tournaments as part of a season
  next if $tournament;

  # Limit season stats to players who have played in a bare minimum of games
  @players = noScrubs(\%playerCount,\@players,\@dates);
  ## Dump season totals (identical to old-style format)
  my $seasonOutfile = createName($_,q{},0);
  open my $seasonCsv, '>', "$seasonOutfile" or die $ERRNO;
  print $seasonCsv join q{,}, @stats;
  print $seasonCsv "\n";
  foreach my $dude (@players) {
    print $seasonCsv "\"$dude\",";
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
      # calculated stat
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

# Limit lifetime stats to players who have played in a bare minimum of games
@masterPlayers = noScrubs(\%masterPlayerCount,\@masterPlayers,\@masterDates);
## Dump lifetime totals (same format as season totals)
open my $masterCsv, '>', 'mls_master.csv' or die $ERRNO;
print $masterCsv join q{,}, @stats;
print $masterCsv "\n";
foreach my $dude (@masterPlayers) {
  print $masterCsv "\"$dude\",";
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
    # Try to cut down on noise by skipping the first data point of each
    # calculated stat
    next if ($j == 0 and $i >= 12);

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


# Calculate wOBA scores
# Pulled out here to make adjusting weights easier and so on
sub calcwOBA
  {
    my $hashRef = shift;
    my ($BB,$B1,$B2,$B3,$HR) = qw (0.72 0.90 1.24 1.56 1.95);

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


sub noScrubs
  {
    my ($countRef,$playerRef,$dateRef) = @_;
    my @return;
    my $max = scalar @{$dateRef}; # Number of games in the season

    foreach (@{$playerRef}) {
      push @return, $_ if (${$countRef}{$_} / $max >= $threshold);
    }

    return @return;
  }
