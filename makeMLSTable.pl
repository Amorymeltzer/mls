#!/usr/bin/env perl
# makeMLSTable.pl by Amory Meltzer
# TRansform CSV data into a sortable html table

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );

if (@ARGV == 0 || @ARGV > 3) {
  print "Usage: makeMLSTAble.pl mls_data.csv <output.html> <archive_or_no>\n";
  exit;
}

my $input = $ARGV[0];
my $output = $ARGV[1] // 'table.html';
my $archive = $ARGV[2] // 0;

my %data;			# Hash of arrays of data
my @names;			# MLS stars
my @header;			# Header array
my @total;			# Footer total array


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

# Get proper date when updating
my @months = qw (January February March April May June July August September
		 October November December);
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime;
$year += 1900;			# Convert to 4-digit year

open my $out, '>', "$output" or die $ERRNO;
# Handle archiveness
my $archivePre = q{};
$archivePre ='../' if $archive;

if ($archive) {
  print $out '<small>← <a href="../archive">Return to the archive index</a></small>';
  print $out "<h3>\n";
  print $out '<a id="mls-stats-old" class="anchor"';
  print $out 'href="#mls-stats-old" aria-hidden="true">';
  print $out '<span class="octicon octicon-link"></span>';
  print $out '</a>MLS stats, Old 2015 (old)</h3>';
} else {
  print $out "<h3>\n";
  print $out '<a id="mls-stats-ongoing" class="anchor"';
  print $out 'href="#mls-stats-ongoing" aria-hidden="true">';
  print $out '<span class="octicon octicon-link"></span>';
  print $out '</a>MLS stats, Fall 2015 (ongoing)</h3>';
}

# Sortify
print $out '      <p>Click on the column headers to sort the table.';
print $out "  Data are current as of $months[$mon] $mday, $year.</p>\n\n";


print $out '      <script src=\'';
print $out $archivePre;
print $out "tablesort.min.js'></script>\n";
print $out '      <script src=\'';
print $out $archivePre;
print $out "tablesort.number.js'></script>\n\n";
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
