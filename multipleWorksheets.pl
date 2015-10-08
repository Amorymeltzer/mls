#!/usr/bin/env perl
# multipleWorksheets.pl by Amory Meltzer
# Prepare XLS/X files with multiple worksheets for xlscat
# Probably better to just end run around xlscat in the long run, eh?

use strict;
use warnings;
use diagnostics;

use Spreadsheet::Read;


my $book = ReadData ($ARGV[0]);
print "$book->[0]{'sheets'}\n";
print "$book->[1]{'label'}\n";
print "$book->[2]{'label'}\n";
print "$book->[3]{'label'}\n";

my $sheetNum = $book->[0]{'sheets'};
for (my $i = 1; $i<=$sheetNum; $i++) {
  print "$i\t$book->[$i]{'label'}\n";
  print "$book->[$i]{'maxrow'}\t";
  print "$book->[$i]{'B3'}\t";
  print "$book->[$i]{'maxcol'}\n";

}
