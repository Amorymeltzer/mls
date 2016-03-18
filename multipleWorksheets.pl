#!/usr/bin/env perl
# multipleWorksheets.pl by Amory Meltzer
# Prepare XLS/X files with multiple worksheets for xlscat
# Probably better to just end run around xlscat in the long run, eh?

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );

use Spreadsheet::Read;
use Excel::Writer::XLSX;


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
  next if $seas =~ /Tournament/;
  my @tmp = split / /, $seas;
  $seas = "$tmp[0] $tmp[1]";
  if (!$seasonsList{$seas}) {
    $seasonsList{$seas} = [$tmp[2]];
  } else {
    push @{$seasonsList{$seas}}, $tmp[2];
    # Ensure each season's game are chronological
    @{$seasonsList{$seas}} = sort @{$seasonsList{$seas}};
  }
}


# Stats measured, for building the player hash
my @stats = qw ("Player" PA AB R H 2B 3B HR RBI BB K SAC "" AVG OBP SLG OPS);
# Master lists of stats, players, and dates played
my %masterData;
my @masterPlayers;
my @masterDates;

# This ignores tournys, need to handle them above FIXME TODO
foreach (sort keys %seasonsList) {
  print "full: $_\t@{$seasonsList{$_}}\n";
  my %playerData;    # Hash holding per-player stat data [total, current game]
  my @players;	     # Player names
  my @dates;	     # Dates of play

  # Get each individual game info
  while (@{$seasonsList{$_}}) {
    my $date = shift @{$seasonsList{$_}};
    print "$date\n";
    my ($season,$syear) = split / /;
    print "$season\t$syear\t$date\n";
    my $gameDate = "$date.".substr $syear, 2;

    # Keep track of time
    push @dates, $gameDate;
    push @masterDates, $gameDate;

    # Pull out corresponding worksheet for the individual game
    my %gameData = %{$book->[$book->[0]{sheet}{"$season $syear $date"}]};

    # Inverted from how I think about rows/columns.  Value essentially means
    # how far they go, i.e. maxrow of 5 means rows extend 5 places to column E
    my $rowN = $gameData{'maxrow'};
    my $colN = $gameData{'maxcol'};

    ## Dump per-game totals (basically a copy of %gameData)
    ## Could I just use dataDumper? FIXME TODO
    my $gameOutfile = createName($_);
    $gameOutfile =~ s/.csv/_$date.csv/; # Incorporate into subroutine FIXME TODO
    print "$gameOutfile\n";
    open my $gameCsv, '>', "$gameOutfile" or die $ERRNO;
    print $gameCsv join q{,}, @stats;

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
	  print $gameCsv "\n\"$cell\",";
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
	  push @masterPlayers, $cell if ! $masterData{$cell};

	  next;
	}

	# Format calculated stats to 3 decimal places.  Temporary kludge to
	# make comparison diffs easier.  Ugly.  FIXME TODO
	$cell = sprintf '%.3f', $cell if $c >= 14;
	print $gameCsv "$cell,";

	push @{$playerData{$player}{$gameDate}}, $cell;
	if ($gameData{'cell'}[$c][$r]) {
	  $playerData{$player}{'total'}[$c-2] += $cell;
	  $masterData{$player}[$c-2] += $cell;
	  # See above
	  $playerData{$player}{'total'}[$c-2] = sprintf '%.3f', $playerData{$player}{'total'}[$c-2] if $c >= 14;
	  $masterData{$player}[$c-2] = sprintf '%.3f', $masterData{$player}[$c-2] if $c >= 14;
	} else {
	  $playerData{$player}{'total'}[$c-2] = 0;
	  $masterData{$player}[$c-2] = 0;
	}
      }
    }
    close $gameCsv or die $ERRNO;


    print "@players\n";
    print "@stats\n";
    print keys %playerData;
    print "\n";
    print "@{$playerData{'Andrew Burch'}{$gameDate}}\n";
    print "@{$playerData{'Andrew Burch'}{'total'}}\n";
    # print "\n\n\n\n";
    # use Data::Dumper qw(Dumper);
    # print Dumper \%playerData;
  }
  ### Append to row for each stat (need to parse names first, use hash)
  ### Also handle tournaments somehow (table, no graph)

  ## Dump season totals (identical to old-style format)
  ## Need to deal with empty column filled with zero... or do I? FIXME TODO
  my $seasonOutfile = createName($_);
  print "$seasonOutfile\n";
  open my $seasonCsv, '>', "$seasonOutfile" or die $ERRNO;
  print $seasonCsv join q{,}, @stats;
  print $seasonCsv "\n";
  foreach my $dude (@players) {
    print $seasonCsv "\"$dude\",";
    print $seasonCsv join q{,}, @{$playerData{$dude}{'total'}};
    print $seasonCsv "\n";
  }
  close $seasonCsv or die $ERRNO;


  # Dump per-game values for each student
  # Not increasing yet, but should be FIXME TODO
  # Also has issue with Total: showing up in some output?  FIXME TODO
  my $seasonSuffix = $seasonOutfile;
  $seasonSuffix =~ s/.*mls_(\w\d\d).*/$1/;
  foreach my $i (1..scalar @stats - 1) {
    next if $stats[$i] =~ m/\"/;	# Deal with blank column, temporary FIXME TODO
    open my $stat, '>', "$stats[$i]_$seasonSuffix.csv" or die $!;
    print $stat 'Date,';
    print $stat join q{,}, @players[0..$#players-1]; # Don't include totals
    print $stat "\n";
    foreach my $j (0..scalar @dates - 1) {
      print $stat "$dates[$j],";
      foreach my $dude (@players[0..$#players-2]) {
	# Awkward kludge to add data, destructive but at the end so not an issue
	$playerData{$dude}{$dates[$j]}[$i-1] += $playerData{$dude}{$dates[$j-1]}[$i-1] if $j != 0;
	print $stat "$playerData{$dude}{$dates[$j]}[$i-1],";
      }
      $playerData{$players[-2]}{$dates[$j]}[$i-1] += $playerData{$players[-2]}{$dates[$j-1]}[$i-1] if $j != 0;
      print $stat "$playerData{$players[-2]}{$dates[$j]}[$i-1]";
      print $stat "\n";
    }
    close $stat or die $ERRNO;
  }
}

## Dump lifetime totals (same format as season totals)
open my $masterCsv, '>', 'masterData.csv' or die $!;
print $masterCsv join q{,}, @stats;
print $masterCsv "\n";
foreach my $dude (@masterPlayers) {
  print $masterCsv "\"$dude\",";
  print $masterCsv join q{,}, @{$masterData{$dude}};
  print $masterCsv "\n";
}
close $masterCsv or die $ERRNO;


exit;















for (1..$sheetNum) {
  my $i = $_;
  # Inverted from how I think about rows/columns.  Value essentially means how
  # far they go, i.e. a maxrow of 5 means rows extend 5 places to column E
  my $rowN = $book->[$i]{'maxrow'};
  my $colN = $book->[$i]{'maxcol'};

  # Name each file according to worksheet name
  my $outfile = createName($book->[$i]{'label'});
  next if $outfile eq '1';	# Skip if the above errors out
  my $workbook = Excel::Writer::XLSX->new( "$outfile" );
  my $sheet = $workbook->add_worksheet( "$outfile" );

  # Formatting options for sabermetrics
  $sheet->keep_leading_zeros();
  my $formatNum = $workbook->add_format();
  $formatNum->set_num_format( '0.000' );

  # Iterate all the the things!
  for (1..$rowN) {
    my $r = $_;
    for (1..$colN) {
      my $c = $_;
      if ($book->[$i]{'cell'}[$c][$r]) {
	if ($colN-$c<=4) {
	  # Only use 0.000 formatting on calculated stats
	  $sheet->write($r-1, $c-1, $book->[$i]{'cell'}[$c][$r], $formatNum);
	} else {
	  $sheet->write($r-1, $c-1, $book->[$i]{'cell'}[$c][$r]);
	}
      } elsif ($c != 13) {  # Zero-fill, unless it's a purposeful blank column
	$sheet->write($r-1, $c-1, '0');
      }
    }
  }
  # Rename if needed
  rename $outfile, archiveFiles($outfile);

  # All done
  print "Created $outfile\n";
}


#### Subroutines
# Build an appropriate name
sub createName
  {
    my $label = shift;
    my $name = 'mls_';

    # Tournament
    $name .= 't' if $label =~ m/tournament/i;
    # Season
    my $re = join q{|}, keys %seasons;
    my $season;
    # Error handling if a poorly-named worksheet is encountered
    if ($label =~ /\b($re)\b/i) {
      ($season) = $label =~ /\b($re)\b/i;
    } else {
      print "Worksheet '$label' improperly named, skipping...\n";
      return 1;
    }
    $name .= $seasons{lc $season};
    # Year
    my ($curYear) = $label =~ /(\d+)/;
    $name .= substr $curYear, 2;
    # Extension
    $name .= '.csv';

    return $name;
  }

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
