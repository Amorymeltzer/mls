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

open my $arcindex, '>', 'arc.list' or die $ERRNO;
print $arcindex "<h3>\n";
print $arcindex '<a id="archive" class="anchor" href="#archive" aria-hidden="true">';
print $arcindex "<span class=\"octicon octicon-link\"></span></a>Archived data</h3>\n";
print $arcindex '<p>';

foreach my $key (sort seasonSort keys %seas) {
  # List games chronologically
  @{$seas{$key}} = sort @{$seas{$key}};
  print "$key: @{$seas{$key}}\n";

  # Parse filenames for seasons, tournaments
  my ($filename) = $key =~ s/^(?:archive\/)?mls_(t?[suf]1\d)$/$1/r;
  my $season = ($filename =~ /^t/) ? 'Tournament ' : q{};
  $season .= $seasons{substr $filename, -3, 1};
  my $date = '20'.substr $filename, -2, 2;

  #  print $arcindex "<p><a href=\"/$key\">$season $date</a></p>";
  print $arcindex " \&mdash\; <a href=\"/$key\">$season $date</a>";

  # Only print index for full-on seasons
  if ($season !~ /tournament/i) {
    open my $out, '>', "$key.list" or die $ERRNO;
    print $out "<h3>\n";
    print $out '<a id="archive" class="anchor" href="#archive" aria-hidden="true">';
    print $out "<span class=\"octicon octicon-link\"></span></a>Archived data</h3>\n";
    print $out '<p>';

    foreach (sort @{$seas{$key}}) {
      my ($show) = s/\./\//r;	# More reasonable formatting
      #  print $out "<p><a href=\"./$_\">$show/$date</a></p>";
      print $out " \&mdash\; <a href=\"./$_\">$show/$date</a>";
    }
    print $out '</p>';
    close $out or die $ERRNO;
  }
}
print $arcindex '</p>';
close $arcindex or die $ERRNO;





# Special sorting subroutine to ensure Spring comes before sUmmer which
# comes before Fall
# Most recent seasons first, for now FIXME TODO
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
    $y <=> $x || $seasonOrderMap{$v} cmp $seasonOrderMap{$w} || $aLength <=> $bLength;
  }
