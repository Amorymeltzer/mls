#!/usr/bin/env perl
# multipleWorksheets.pl by Amory Meltzer
# Prepare XLS/X files with multiple worksheets for xlscat
# Probably better to just end run around xlscat in the long run, eh?

use strict;
use warnings;
use diagnostics;

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
  $seas = "$tmp[1] $tmp[0]";
  if (!$seasonsList{$seas}) {
    $seasonsList{$seas} = [$tmp[2]];
  } else {
    push @{$seasonsList{$seas}}, $tmp[2];
    # Ensure each season's game are chronological
    @{$seasonsList{$seas}} = sort @{$seasonsList{$seas}};
  }
}


# Stats measured, for building the player hash
my @stats = qw (Player PA AB R H 2B 3B HR RBI BB K SAC "" AVG OBP SLG OPS);

# This ignores tournys, need to handle them above FIXME TODO
foreach (sort keys %seasonsList) {
  print "full: $_\t@{$seasonsList{$_}}\n";
  my %playerData;    # Hash holding per-player stat data [total, current game]
  my @players;	     # Player names

  # Get each individual game info
  while (@{$seasonsList{$_}}) {
    my $date = shift @{$seasonsList{$_}};
    print "$date\n";
    my ($season,$syear) = split / /;
    print "$season\t$syear\t$date\n";

    # Pull out corresponding worksheet for the individual game
    my %gameData = %{$book->[$book->[0]{sheet}{"$syear $season $date"}]};

    ## Parse into CSV
    # Inverted from how I think about rows/columns.  Value essentially means
    # how far they go, i.e. maxrow of 5 means rows extend 5 places to column E
    my $rowN = $gameData{'maxrow'};
    my $colN = $gameData{'maxcol'};

    my $player;
    # Build player-data hash
    for my $r (1..$rowN) {
      for my $c (1..$colN) {
	my $cell = $gameData{'cell'}[$c][$r];
	#print "r: $r\tc: $c\t$cell\n";
	if ($r == 1) {
	  next;
	} elsif ($c == 1) {
	  $player = $cell;
	  if (! $playerData{$cell}{'current'}) {
	    # Player names for individual stat headers, really just for
	    # sorting purposes when dumping out the full-scale player database
	    push @players, $cell;
	  } else {
	    @{$playerData{$cell}{'current'}} = ();
	  }
	  next;
	}
	#  push @{$playerData{$players[-1]}{'current'}}, $cell;
	push @{$playerData{$player}{'current'}}, $cell;
	if ($gameData{'cell'}[$c][$r]) {
	  $playerData{$player}{'total'}[$c-2] += $cell;
	} else {
	  $playerData{$player}{'total'}[$c-2] = 0;
	}
      }
    }
    print "@players\n";
    print "@stats\n";
    print keys %playerData;
    print "\n";
    print "@{$playerData{'Andrew Burch'}{'current'}}\n";
    print "@{$playerData{'Andrew Burch'}{'total'}}\n";


    my $outfile = createName($book->[$book->[0]{sheet}{"$syear $season $date"}]{'label'});
    print "$outfile\n";

    # Sum for season total (dump hash for each player for each season)
    # Need to move this out to *just* season totals but that leads to issues
    # with the @players and @stats FIXME TODO
    open my $csv, '>', "$outfile" or die $1;
    print $csv join(',', @stats);
    print $csv "\n";
    foreach my $dude (@players) {
      print $csv "\"$dude\",";
      print $csv join(',', @{$playerData{$dude}{'total'}});
      print $csv "\n";
    }
    close $csv or die !$;
    # print "\n\n\n\n";
    # use Data::Dumper qw(Dumper);
    # print Dumper \%playerData;
  }
  # Output individual game tables (loop above as below rowN, colN) (dump hash)
  # Append to row for each stat (need to parse names first, use hash)
  # Also handle tournaments somehow (table, no graph)
}

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
# Get the appropriate name
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
    #  $name .= '.xlsx';
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
