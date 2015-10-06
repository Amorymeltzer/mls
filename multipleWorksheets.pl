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

my %sheets = %{$book->[0]{'sheet'}};
my @keys = keys %sheets;
print "@keys\n";
