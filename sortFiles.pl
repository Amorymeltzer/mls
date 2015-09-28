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

my %hash;

foreach my $file (@ARGV) {
  my $key = $file;
  $key =~ s/\.\/(?:archive\/)?mls_(\w\w?\d\d).xlsx?$/$1/;
  $hash{$key} = $file;
}

my @files;
foreach my $key (sort seasonSort keys %hash) {
  push @files, $hash{$key};
}

# Quotes ensure the list is formatted for bash
print "@files";

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

    $x <=> $y || $seasonOrderMap{$v} cmp $seasonOrderMap{$w} || $aLength <=> $bLength;
  }
