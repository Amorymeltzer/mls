#!/usr/bin/env perl
# makeMLSTable.pl by Amory Meltzer
# TRansform CSV data into a sortable html table

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );

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

open my $in, '<', "$input" or die $ERRNO;
while (<$in>) {
  chomp;
  my @tmp = split /,/;
  $tmp[0] =~ s/\"//g;		# No quotes in names
  $tmp[-1] =~ s/\r//g;		# No stupid ^M crap
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
close $in or die $ERRNO;


open my $out, '>', "$output" or die $ERRNO;
# Sortify
print $out "      <script src='tablesort.min.js'></script>\n";
print $out "      <script src='tablesort.number.js'></script>\n\n";
print $out "      <table id='mls-table'>\n";

# Header row
print $out "	<thead>\n";
print $out "	 <tr>\n";

foreach my $col (0..scalar @header - 1) {
  # Don't sort blank columns
  if ($header[$col] eq q{}) {
    print $out "	    <th class='no-sort'>$header[$col]</th>\n";
  } elsif ($col > 0) {
    print $out "	    <th data-sort-method='number'>$header[$col]</th>\n";
  } else {
    print $out "	    <th>$header[$col]</th>\n";
  }
}

print $out "	 </tr>\n";
print $out "	</thead>\n";


# Data
print $out "	<tbody>\n";

foreach my $name (@names) {
  # Don't sort blank row before totals
  if ($name eq q{}) {
    print $out "	  <tr class='no-sort'>\n";
  } else {
    print $out "	  <tr>\n";
  }

  # Split on space in order to get last name for sorting
  my @lname = split / /, $name;

  foreach my $col (0.. scalar @{$data{$name}} - 1) {
    # Sort players by last name
    if ($col == 0 && $lname[-1]) {
      print $out "<td data-sort='$lname[-1]'>@{$data{$name}}[$col]</td>\n";
    } else {
      print $out "<td>@{$data{$name}}[$col]</td>\n";
    }
  }

  print $out "	  </tr>\n";
}

# Footer totals row
# Don't sort totals
print $out "	  <tr class='no-sort'>\n";
foreach my $col (0..scalar @total - 1) {
  print $out "	    <td style='font-weight:bold;'>$total[$col]</td>\n";
}

print $out "	  </tr>\n";
print $out "	</tbody>\n";
print $out "   </table>\n\n";

# More sortification
print $out "      <script>\n";
print $out "	new Tablesort(document.getElementById('mls-table'));\n";
print $out "      </script>\n";


close $out or die $ERRNO;
