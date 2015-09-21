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

my %data;			# Hash of arrays of data
my @names;			# MLS stars
my @header;			# Header array
my @total;			# Footer total array

my $input = $ARGV[0];
my $output = $ARGV[1] // 'table.html';

open my $in, '<', "$input" or die $!;
while (<$in>) {
  chomp;
  my @tmp = split /,/;
  if ($tmp[0] =~ /Player/) {
    @header = @tmp;
    next;
  } elsif ($tmp[0] =~ /Total/) {
    @total = @tmp;
    next;
  }
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


open my $out, '>', "$output" or die $!;
# Sortify
print $out "      <script src='tablesort.min.js'></script>\n\n";
print $out "      <table id='mls-table'>\n";

# Header row
print $out "	<thead>\n";
print $out "	 <tr>\n";

foreach my $col (0..scalar @header - 1) {
  print $out "	    <th>$header[$col]</th>\n";
}

print $out "	 </tr>\n";
print $out "	</thead>\n";


# Data
print $out "	<tbody>\n";

foreach my $name (sort @names) {
  print $out "	  <tr>\n";
  foreach my $col (0.. scalar @{$data{$name}} - 1) {
    print $out "<td>@{$data{$name}}[$col]</td>\n";
  }
  print $out "	  </tr>\n";
}

# Footer totals row
foreach my $col (0..scalar @total - 1) {
  print $out "	 <tr>\n";
  print $out "	    <th>$total[$col]</th>\n";
  print $out "	 </tr>\n";
}



close $out or die $!;
