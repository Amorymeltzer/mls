#!/usr/bin/env perl
# makeMLSTable.pl by Amory Meltzer
# TRansform CSV data into a sortable html table

use strict;
use warnings;
use diagnostics;

unless (@ARGV  > 0 && @ARGV < 3) {
  print "Usage: makeMLSTAble.pl data.csv <output.html>\n";
  exit;
}

my $input = $ARGV[0];
my $output = $ARGV[1] // 'table.html';
