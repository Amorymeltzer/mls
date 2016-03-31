#!/usr/bin/env perl
# multipleWorksheets.pl by Amory Meltzer
# Prepare XLS/X files with multiple worksheets for xlscat
# Probably better to just end run around xlscat in the long run, eh?

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );
use Spreadsheet::Read;


if (@ARGV != 1) {
  print "Usage: multipleWorksheets.pl MLS_Stats.xlsx\n";
  exit;
}

my $book = ReadData ($ARGV[0]);

# Season lookup.  Would be easy to substring, but this also means I get all
# seasons as a nice keys array
my %seasons = (
	       spring => 's',
	       summer => 'u',
	       fall => 'f');

# Date parsing
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime;
$year += 1900;			# Convert to 4-digit year

# Attempt to divine current season
# Not exact, esp. around June
my $curSeason = ($mon < 8 && $mon > 4) ? 'summer' : 'fall';
$curSeason = ($mon < 3 || $mon > 4) ? $curSeason : 'spring';

# Iterate over each sheet
my $sheetNum = $book->[0]{'sheets'};
my %seasonsList;		# Unique list of seasons that need parsing
# It's silly to run through this multiple times, need to just grab all names
# from initial hash.  Order unimportant so it's doable.
for (1..$sheetNum) {
  my $seas = $book->[$_]{'label'};

  my @tmp = split / /, $seas;
  $seas = "$tmp[0] $tmp[1]";
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
#  my @stats = qw ("Player" AB R H 2B 3B HR RBI BB K SAC AVG OBP SLG OPS);
my @stats = qw ("Player" AB R H 2B 3B HR TB RBI BB K SAC AVG OBP SLG OPS);
# Master lists of stats, players, and dates played
my %masterData;
my @masterPlayers;
my @masterDates;

foreach (sort keys %seasonsList) {
  print "seas: $_\t items: @{$seasonsList{$_}}\n";
  my %playerData;    # Hash holding per-player stat data [total, current game]
  my @players;	     # Player names
  my @dates;	     # Dates of play

  # Ternary ?: ($a = $test ? $b : $c;)
  # a is b if test, c if not
  my $tournament = /Tournament/ ? 1 : 0;

  # Get each individual game info
  while (@{$seasonsList{$_}}) {
    my $date = shift @{$seasonsList{$_}};
    my ($season,$syear) = split / /;
    my $gameDate = "$date.".substr $syear, 2;

    $gameDate = $date if $tournament == 1;

    # Keep track of time
    push @dates, $gameDate;
    push @masterDates, $gameDate if $tournament != 1;

    # Pull out corresponding worksheet for the individual game
    my %gameData;
    if ($tournament == 1) {	# Tourny names are parsed differently
      %gameData = %{$book->[$book->[0]{sheet}{"$date"}]};
    } else {
      %gameData = %{$book->[$book->[0]{sheet}{"$season $syear $date"}]};
    }


    # Inverted from how I think about rows/columns.  Value essentially means
    # how far they go, i.e. maxrow of 5 means rows extend 5 places to column E
    my $rowN = $gameData{'maxrow'};
    #  my $colN = $gameData{'maxcol'};
    my $colN = $gameData{'maxcol'} + 4; # Make room for calculated stats

    ## Dump per-game totals (basically a copy of %gameData)
    ## Could I just use dataDumper? FIXME TODO
    my $gameOutfile = createName($_,$date,$tournament);
    open my $gameCsv, '>', "$gameOutfile" or die $ERRNO;
    print $gameCsv join q{,}, @stats;

    my $offset = 2;
    my $player;
    # Build player-data hash (of hash of arrays)
    for my $r (1..$rowN) {
      for my $c (1..$colN) {
	my $cell = $gameData{'cell'}[$c][$r]; # Just easier to remember
	if ($r == 1) {			      # Hardcoded above in @stats
	  # Good place for a check with length of @stats
				# and $colN FIXME TODO
	  next;
	} elsif ($c == 1) {
	  print $gameCsv "\n\"$cell\"";
	  $player = $cell;	# Define current player for entire row, saves
                                # issue of duplicating and polluting @players

	  # Build player array; really just for sorting purposes when dumping
	  # out the full-scale player database.  Only append if it's a new
	  # player, otherwise we should just clear-out the current game array
	  if (! $playerData{$cell}) {
	    push @players, $cell;
	  } else {
	    @{$playerData{$cell}{$gameDate}} = ();
	  }

	  # Do the same for the master list of players
	  if ($tournament != 1 && !$masterData{$cell}) {
	    push @masterPlayers, $cell;
	  }


	  $offset = 2;		# Reset on new row

	  next;
	}


	#print "$c $gameDate $player $offset $cell\n";
	if ($c >= 12) {
	  # Calculate total first, so we don't overlap
	  $cell = calcStats($c,$player,'total',\%playerData);
	  #  $playerData{$player}{'total'}[$c-2] = $cell;
	  $playerData{$player}{'total'}[$c-$offset] = $cell;
	  #  $masterData{$player}{'total'}[$c-2] = $cell if $tournament != 1;
	  $masterData{$player}{'total'}[$c-$offset] = $cell if $tournament != 1;

	  # Calculate for the given gameDate to append
	  $cell = calcStats($c,$player,$gameDate,\%playerData);
	} else {
	  if ($gameData{'cell'}[$c][$r]) {
	    #  $playerData{$player}{'total'}[$c-2] += $cell;
	    $playerData{$player}{'total'}[$c-$offset] += $cell;
	    #  $masterData{$player}{'total'}[$c-2] += $cell if $tournament != 1;
	    $masterData{$player}{'total'}[$c-$offset] += $cell if $tournament != 1;
	  } else {
	    #  $playerData{$player}{'total'}[$c-2] += 0;
	    $playerData{$player}{'total'}[$c-$offset] += 0;
	    #  $masterData{$player}{'total'}[$c-2] += 0 if $tournament != 1;
	    $masterData{$player}{'total'}[$c-$offset] += 0 if $tournament != 1;
	  }
	}
	push @{$playerData{$player}{$gameDate}}, $cell;
	push @{$masterData{$player}{$gameDate}}, $cell if $tournament != 1;



	print $gameCsv ",$cell";

	if ($c == 7) {		# HR
	  $cell = $playerData{$player}{$gameDate}[2] + $playerData{$player}{$gameDate}[3] + (2 * $playerData{$player}{$gameDate}[4]) + (3 * $playerData{$player}{$gameDate}[5]);

	  $offset = 1;

	  $playerData{$player}{'total'}[$c-$offset] += $cell;
	  $masterData{$player}{'total'}[$c-$offset] += $cell if $tournament != 1;

	  push @{$playerData{$player}{$gameDate}}, $cell;
	  push @{$masterData{$player}{$gameDate}}, $cell if $tournament != 1;

	  print $gameCsv ",$cell";
	}



      }
    }
    close $gameCsv or die $ERRNO;
  }

  # Don't treat tournaments as part of a season
  next if $tournament == 1;

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
  # Non-destructive /r option added in 5.14, probably safe
  my ($seasonSuffix) = $seasonOutfile =~ s/.*mls_(\w\d\d).*/$1/r;
  # Dump per-game values for each stat in each season
  foreach my $i (1..scalar @stats - 1) {
    open my $stat, '>', "$stats[$i]_$seasonSuffix.csv" or die $ERRNO;
    print $stat 'Date,';
    print $stat join q{,}, @players[0..$#players-1]; # Don't include totals
    print $stat "\n";
    # Set baseline of zero for cumulative stats
    #  if ($i < 11) {
    if ($i < 12) {		# TB#####
      my $length = $#players;
      print $stat 'Start,';
      print $stat join q{,}, (0) x $length;
      print $stat "\n";
    }

    foreach my $j (0..scalar @dates - 1) {
      print $stat "$dates[$j]";
      foreach my $dude (@players[0..$#players-1]) {
	# Awkward kludge to add data, destructive but at the end so not an issue
	#  if ($i >= 11) {
	if ($i >= 12) {		# TB#####
	  #  $playerData{$dude}{$dates[$j]}[$i-1] = calcStats($i+1,$dude,$dates[$j],\%playerData);
	  $playerData{$dude}{$dates[$j]}[$i-1] = calcStats($i,$dude,$dates[$j],\%playerData);
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

## Dump lifetime totals (same format as season totals)
open my $masterCsv, '>', 'masterData.csv' or die $ERRNO;
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
  #  if ($i < 11) {
  if ($i < 12) {
    my $length = $#masterPlayers;
    print $stat 'Start,';
    print $stat join q{,}, (0) x $length;
    print $stat "\n";
  }

  foreach my $j (0..scalar @masterDates - 1) {
    print $stat "$masterDates[$j]";
    foreach my $dude (@masterPlayers[0..$#masterPlayers-1]) { # Ignore totals
      # Awkward kludge to add data, destructive but at the end so not an issue
      #  if ($i >= 11) {
      if ($i >= 12) {
	#  $masterData{$dude}{$masterDates[$j]}[$i-1] = calcStats($i+1,$dude,$masterDates[$j],\%masterData);
	$masterData{$dude}{$masterDates[$j]}[$i-1] = calcStats($i,$dude,$masterDates[$j],\%masterData);
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
    $name .= 't' if $tourny == 1;
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
    if ($tourny != 1 && $datum) {
      $name .= "_$datum";
    }

    return "$name.csv";		# Extension
  }


# Calc stats
sub calcStats
  {
    my ($c,$player,$chart,$playerRef) = @_;
    my $cell;			# Hold calculated stat

    ## Repeatedly used for calculations, convenient (
    # PA=AB+BB+SAC
    #  my $PA = ${$playerRef}{$player}{$chart}[0] + ${$playerRef}{$player}{$chart}[7] + ${$playerRef}{$player}{$chart}[9];

    # TB #######
    my $PA = ${$playerRef}{$player}{$chart}[0] + ${$playerRef}{$player}{$chart}[8] + ${$playerRef}{$player}{$chart}[10];
    # TB=H+2B+2*3B+3*4B
    my $TB = ${$playerRef}{$player}{$chart}[2] + ${$playerRef}{$player}{$chart}[3] + (2 * ${$playerRef}{$player}{$chart}[4]) + (3 * ${$playerRef}{$player}{$chart}[5]);

    if ($c == 12) {		# AVG = H/AB
      $cell = ${$playerRef}{$player}{$chart}[2] / ${$playerRef}{$player}{$chart}[0];
    } elsif ($c == 13) {	# OBP = (H+BB)/PA
      #  $cell = (${$playerRef}{$player}{$chart}[2] + ${$playerRef}{$player}{$chart}[7]) / $PA;


      # TB######
      $cell = (${$playerRef}{$player}{$chart}[2] + ${$playerRef}{$player}{$chart}[8]) / $PA;
    } elsif ($c == 14) {	# SLG = Total bases/AB
      $cell = $TB / ${$playerRef}{$player}{$chart}[0];
    } elsif ($c == 15) {	# OPS = OBP+SLG
      #$cell = ${$playerRef}{$player}{$chart}[11] + ${$playerRef}{$player}{$chart}[12];

      # TB#######
      $cell = ${$playerRef}{$player}{$chart}[12] + ${$playerRef}{$player}{$chart}[13];
    }
    #print "$c $player $chart $cell\n";
    return sprintf '%.3f', $cell; # Prettify to three decimals
  }


# American dates are dumb, sort on YY/MM/DD
# Schwartzian transform
sub schwartz
  {
    my $ref = shift;
    @{$ref} =
      map {$_->[0]}
      sort { $a->[1] cmp $b->[1] }
      map {[$_, join('', (split '\.', $_)[2,0,1])]}
      @{$ref};
  }


#### Useful? FIXME TODO
# Any previous seasons should be renamed/archived
sub archiveFiles
  {
    my $name = shift;
    ($name) = split /\./, $name; # Listification takes first item
    # Year
    my $curYear = '20'.substr $name, -2, 2;
    # Season
    my $season = substr $name, -3, 1;
    # Also tournament
    if ($name =~ /t/ || $curYear != $year || $season ne $seasons{$curSeason}) {
      $name = 'archive/'.$name;
    }
    return $name.'.xlsx';
  }
