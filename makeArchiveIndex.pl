#!/usr/bin/env perl
# makeArchiveIndex.pl by Amory Meltzer
# Build the archive link index

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );

if (@ARGV != 2) {
  print "Usage: makeArchiveIndex.pl mls_data.csv archive_index.html\n";
  exit;
}

my $input = $ARGV[0];
my $output = $ARGV[1];


# Parse filenames for seasons, tournaments
my $filename = $input;
$filename =~ s/^(?:archive\/)?mls_(\w\w?\d\d)$/$1/;
my %seasons = (
	       s => 'Spring',
	       u => 'Summer',
	       f => 'Fall');
my $season = ($filename =~ /^t/) ? 'Tournament ' : q{};
$season .= $seasons{substr $filename, -3, 1};
my $date = '20'.substr $filename, -2, 2;

open my $arci, '>>', "$output" or die $ERRNO;
print $arci "      <p><a href=\"./mls_$filename.index.html\">";
print $arci "$season $date</a></p>\n";
close $arci or die $ERRNO;
