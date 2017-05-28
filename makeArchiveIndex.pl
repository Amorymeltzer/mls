#!/usr/bin/env perl
# makeArchiveIndex.pl by Amory Meltzer
# Build the archive link index

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );

if (!@ARGV) {
  print "Usage: $PROGRAM_NAME list_of_files\n";
  print "Should only be run via build_site.sh\n";
  exit;
}

# Keys access array of game dates
my %seas;
foreach (@ARGV) {
  s/^\.\/mls_(.*)\.csv$/$1/;

  my @tmp = split /_/;

  # Put tournaments on the mainpage, treat 'em like a pseudo season
  if ($tmp[0] =~ /^t/) {
    $tmp[1] = $tmp[0];
  }

  if (!$seas{$tmp[0]}) {
    $seas{$tmp[0]} = [$tmp[1]];
  } else {
    push @{$seas{$tmp[0]}}, $tmp[1];
  }
}


my %seasons = (
	       s => 'Spring',
	       u => 'Summer',
	       f => 'Fall');

open my $arcindex, '>', 'templates/arc.list' or die $ERRNO;
print $arcindex "<h3>\n";
print $arcindex '<a id="archive" class="anchor" href="#archive" aria-hidden="true">';
print $arcindex "<span class=\"octicon octicon-link\"></span></a>Individual season data</h3>\n";
print $arcindex '<p>';

print $arcindex '<a href="/mls/life">Lifetime stats</a>';
print $arcindex ' &bull; ';

my @indices = sort seasonSort keys %seas;
foreach my $key (@indices) {
  # List games chronologically
  @{$seas{$key}} = sort @{$seas{$key}};
  # Parse filenames for seasons, tournaments
  my ($filename) = $key =~ s/^(?:archive\/)?mls_(t?[suf]1\d)$/$1/r;
  my $season = ($filename =~ /^t/) ? 'Tournament ' : q{};
  $season .= $seasons{substr $filename, -3, 1};
  my $date = '20'.substr $filename, -2, 2;

  print $arcindex "<a href=\"/mls/$key\">$season $date</a>";
  print $arcindex ' &bull; ' if $key ne $indices[-1];

  # Only print index for full-on seasons
  if ($season !~ /tournament/i) {
    open my $out, '>', "templates/$key.list" or die $ERRNO;
    print $out "<h3>\n";
    print $out '<a id="archive" class="anchor" href="#archive" aria-hidden="true">';
    print $out "<span class=\"octicon octicon-link\"></span></a>Individual game data</h3>\n";
    print $out '<p>';

    my @games = sort @{$seas{$key}};
    foreach (@games) {
      my ($show) = s/\./\//r;	# More reasonable formatting
      print $out "<a href=\"./$_\">$show/$date</a>";
      print $out ' &bull; ' if $_ ne $games[-1];
    }
    print $out '</p>';
    close $out or die $ERRNO;
  }
}
print $arcindex '</p>';
close $arcindex or die $ERRNO;



# Special sort to ensure the most recent seasons are listed first
sub seasonSort
  {
    my @input = ($a, $b);

    my @seasonOrder = qw (f u s);
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
    $y <=> $x || $seasonOrderMap{$v} cmp $seasonOrderMap{$w} || $aLength <=> $bLength;
  }
