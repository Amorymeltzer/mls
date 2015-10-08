#!/usr/bin/env perl
# multipleWorksheets.pl by Amory Meltzer
# Prepare XLS/X files with multiple worksheets for xlscat
# Probably better to just end run around xlscat in the long run, eh?

use strict;
use warnings;
use diagnostics;

use Spreadsheet::Read;
use Excel::Writer::XLSX;


my $book = ReadData ($ARGV[0]);

my $sheetNum = $book->[0]{'sheets'};
for (my $i = 1; $i<=$sheetNum; $i++) {
  # Inverted from how I think about rows/columns.  Value essentially means how
  # far they go, i.e. a maxrow of 5 means rows extend 5 places to column E
  my $rowN = $book->[$i]{'maxrow'};
  my $colN = $book->[$i]{'maxcol'};

  my $outfile = $book->[$i]{'label'}.'.xlsx';
  my $workbook = Excel::Writer::XLSX->new( "$outfile" );
  my $sheet = $workbook->add_worksheet( "$outfile" );
  $sheet->keep_leading_zeros();
  my $formatNum = $workbook->add_format();
  $formatNum->set_num_format( '0.000' );

  # Build!
  for (my $r = 1; $r<=$rowN; $r++) {
    for (my $c = 1; $c<=$colN; $c++) {
      if ($book->[$i]{'cell'}[$c][$r]) {
	if ($colN-$c<=4) {
	  $sheet->write($r-1, $c-1, $book->[$i]{'cell'}[$c][$r], $formatNum);
	} else {
	  $sheet->write($r-1, $c-1, $book->[$i]{'cell'}[$c][$r]);
	}
      } elsif ($c != 13) {
	$sheet->write($r-1, $c-1, '0');
      }
    }
  }

}
