#!/usr/bin/env perl
# multipleWorksheets.pl by Amory Meltzer
# Prepare XLS/X files with multiple worksheets for xlscat
# Probably better to just end run around xlscat in the long run, eh?

use strict;
use warnings;
use diagnostics;

use Spreadsheet::Read;
use Excel::Writer::XLSX;


my %seasons = (
	       spring => 's',
	       summer => 'u',
	       fall => 'f');

my $book = ReadData ($ARGV[0]);

# Date parsing
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime;
$year += 1900;			# Convert to 4-digit year

# Attempt to divine current season
my $curSeason = ($mon < 8 && $mon > 4) ? 'summer' : 'fall';
$curSeason = ($mon < 3 || $mon > 4) ? $curSeason : 'spring';

# Iterate over each sheet
my $sheetNum = $book->[0]{'sheets'};
for (1..$sheetNum) {
  my $i = $_;
  # Inverted from how I think about rows/columns.  Value essentially means how
  # far they go, i.e. a maxrow of 5 means rows extend 5 places to column E
  my $rowN = $book->[$i]{'maxrow'};
  my $colN = $book->[$i]{'maxcol'};

  # Name each file according to worksheet name
  my $outfile = createName($book->[$i]{'label'});
  my $workbook = Excel::Writer::XLSX->new( "$outfile" );
  my $sheet = $workbook->add_worksheet( "$outfile" );

  # Formatting options
  $sheet->keep_leading_zeros();
  my $formatNum = $workbook->add_format();
  $formatNum->set_num_format( '0.000' );

  # Build!
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
      } elsif ($c != 13) {
	# Zero-fill, unless it's a purposeful blank column
	$sheet->write($r-1, $c-1, '0');
      }
    }
  }
  # All done
  print "Created $outfile\n";
}


# Get the appropriate name
sub createName
  {
    my $label = shift;
    my $name = 'mls_';

    # Tournament
    if ($label =~ m/tournament/i) {
      $name .= 't';
      $name = 'archive/'.$name;
    }
    # Season
    my $re = join q{|}, keys %seasons;
    my ($season) = $label =~ /($re)/i;
    $name .= $seasons{lc $season};
    $name = 'archive/'.$name if lc $season ne $curSeason;
    # Year
    my ($curYear) = $label =~ /(\d+)/;
    $name .= substr $curYear, 2;
    # Extension
    $name .= '.xlsx';

    $name = 'archive/'.$name if $curYear != $year;

    return $name;
  }
