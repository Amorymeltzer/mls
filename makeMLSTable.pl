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

my %data;			# Hold arrays of data
my @names;

my $input = $ARGV[0];
my $output = $ARGV[1] // 'table.html';

open my $in, '<', "$input" or die $!;
while (<$in>) {
  chomp;
  my @tmp = split /,/;
  $data{$tmp[0]} = [@tmp];
  @names = (@names,$tmp[0]);
}
close $in or die $!;

foreach my $name (sort @names) {
  foreach my $col (0.. scalar @{$data{$name}} - 1) {
    print "@{$data{$name}}[$col]\t";
  }
  print "\n";
}
