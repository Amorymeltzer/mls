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
foreach (@ARGV) {
  s/^\.\/mls_(.*)\.csv$/$1/;

  my @tmp = split /_/;

  if (!$hash{$tmp[0]}) {
    $hash{$tmp[0]} = [$tmp[1]];
  } else {
    push @{$hash{$tmp[0]}}, $tmp[1];
  }
}


my %seasons = (
	       s => 'Spring',
	       u => 'Summer',
	       f => 'Fall');

open my $arcindex, '>', 'arc.list' or die $ERRNO;
print $arcindex "<h3>\n";
print $arcindex '<a id="archive" class="anchor" href="#archive" aria-hidden="true">';
print $arcindex "<span class=\"octicon octicon-link\"></span></a>Archived data</h3>\n";

foreach my $key (sort seasonSort keys %hash) {
  print "$key: @{$hash{$key}}\n"; # Quotes ensure the list is formatted for bash
  @{$hash{$key}} = sort @{$hash{$key}};
  print "$key: @{$hash{$key}}\n"; # Quotes ensure the list is formatted for bash

  # Parse filenames for seasons, tournaments
  my ($filename) = $key =~ s/^(?:archive\/)?mls_(t?[suf]1\d)$/$1/r;
  my $season = ($filename =~ /^t/) ? 'Tournament ' : q{};
  $season .= $seasons{substr $filename, -3, 1};
  my $date = '20'.substr $filename, -2, 2;

  open my $out, '>', "$key.list" or die $ERRNO;
  print $out "<h3>\n";
  print $out '<a id="archive" class="anchor" href="#archive" aria-hidden="true">';
  print $out "<span class=\"octicon octicon-link\"></span></a>Archived data</h3>\n";

  print $arcindex "<p><a href=\"/$key\">$season $date</a></p>";

  foreach (sort @{$hash{$key}}) {
    my ($show) = s/\./\//r;			# More reasonable formatting
    print $out "<p><a href=\"./$_\">$show/$date</a></p>";
  }

  close $out or die $ERRNO;
}
print $arcindex '<p><a href="/tournaments">Tournaments</a></p>';
close $arcindex or die $ERRNO;





# Special sorting subroutine to ensure Spring comes before sUmmer which
# comes before Fall
sub seasonSort
  {
    my @input = ($a, $b);

    my @seasonOrder = qw (s u f);
    my %seasonOrderMap = map { $seasonOrder[$_] => $_ } 0..$#seasonOrder;
    my ($v,$w) = ($a,$b);
    $v =~ s/^t//;
    $w =~ s/^t//;
    my $x = substr $v, 1, 2;
    my $y = substr $w, 1, 2;
    $v =~ s/\d//g;
    $w =~ s/\d//g;
    my $aLength = length $a;
    my $bLength = length $b;

    # Year, season, tournaments
    $x <=> $y || $seasonOrderMap{$v} cmp $seasonOrderMap{$w} || $aLength <=> $bLength;
  }
