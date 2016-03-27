#!/usr/bin/env perl
# makeArchiveIndex.pl by Amory Meltzer
# Build the archive link index

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );

if (!@ARGV) {
  print "Usage: $PROGRAM_NAME list_of_files\n";
  exit;
}

# Keys access array of game dates
my %hash;
# ./mls_f15_09.09.csv
foreach (@ARGV) {
  s/^\.\/mls_(.*)\.csv$/$1/;

  my @tmp = split /_/;

  if (!$hash{$tmp[0]}) {
    $hash{$tmp[0]} = [$tmp[1]];
  } else {
    push @{$hash{$tmp[0]}}, $tmp[1];
  }
}


foreach my $key (sort keys %hash) {
  print "$key: @{$hash{$key}}\n";	# Quotes ensure the list is formatted for bash
}























exit;






if (@ARGV != 2) {
  print "Usage: makeArchiveIndex.pl mls_data.csv archive_index.html\n";
  exit;
}

my $input = $ARGV[0];
my $output = $ARGV[1];


# Parse filenames for seasons, tournaments
my $filename = $input;
$filename =~ s/^(?:archive\/)?mls_(t?[suf]1\d)$/$1/;
my %seasons = (
	       s => 'Spring',
	       u => 'Summer',
	       f => 'Fall');
my $season = ($filename =~ /^t/) ? 'Tournament ' : q{};
$season .= $seasons{substr $filename, -3, 1};
my $date = '20'.substr $filename, -2, 2;

# Simply append file name to the archive index
open my $arci, '>>', "$output" or die $ERRNO;
print $arci "<p><a href=\"./mls_$filename.html\">";
print $arci "$season $date</a></p>\n";
close $arci or die $ERRNO;
