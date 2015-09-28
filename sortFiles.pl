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
