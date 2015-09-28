#!/usr/bin/env perl
# sortFiles.pl by Amory Meltzer
# Sort files for proper chronology

use strict;
use warnings;
use diagnostics;

if (!@ARGV) {
  print "Usage: sortFiles.pl list_of_files\n";
  exit;
}
my @files = @ARGV;
print "@files\n";

my %hash;

foreach my $i (@files) {
  print "\t$i\n";
  my $tmp = $i;
  $tmp =~ s/\.\/(?:archive\/)?mls_(\w\w?\d\d).xlsx?$/$1/;
  print "\t$tmp\t$i\n";
  $hash{$tmp} = $i;
}

foreach my $key (sort seasonSort keys %hash) {
  print "a\ta\t$key\t$hash{$key}\n";
}

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

    print "\n\na\t$a\nb\t$b\nv\t$v\nw\t$w\nx\t$x\ny\t$y\n\n";

    $x <=> $y || $seasonOrderMap{$v} cmp $seasonOrderMap{$w} || $aLength <=> $bLength;
  }
