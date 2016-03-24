#!/usr/bin/env perl
# makeMLSTable.pl by Amory Meltzer
# Transform CSV data into a sortable html table

use strict;
use warnings;
use diagnostics;

use English qw( -no_match_vars );
use Getopt::Std;

# Parse commandline options
my %opts = ();
getopts('ualh',\%opts);

if ($opts{h} || @ARGV == 0 || @ARGV > 2) {
  usage();
  exit;
}

my $input = $ARGV[0];
my $output = $ARGV[1] // 'table.table';
my $archive = $opts{a} // 0;	# Treat old ones slightly differently



my %data;			# Hash of arrays of data
my %titleTips;			# Title text for header row
my @names;			# MLS allstars
my @header;			# Column headers
my @total;			# Totals

# Store last updated date
my $dateFile = '.updatedDate.txt';


open my $in, '<', "$input" or die $ERRNO;
while (<$in>) {
  chomp;
  my @tmp = split /,/;
  $tmp[0] =~ s/\"//g;		# No quotes around names
  $tmp[-1] =~ s/\r//g;		# No stupid ^M crap
  if ($tmp[0] =~ /Player/) {
    @header = @tmp;

    # Try to catch some potential errors
    if ($header[-1] ne 'OPS') {
      warn "Warning: Potential extra columns detected!!\n";
    }
    if ($NR != 1) {
      warn "Warning: Potential extra rows detected!\n"
    }
    next;
  } elsif ($tmp[0] =~ /Total/) {
    @total = @tmp;
    last;
  }

  # Build hash of data arrays
  $data{$tmp[0]} = [@tmp];
  @names = (@names,$tmp[0]);
}
close $in or die $ERRNO;

# Good check, turned off for now (need to decide PA or AB) FIXME TODO
# if ($total[2]+$total[9]+$total[11] != $total[1]) {
#   warn "Warning: AB+BB+SAC and PA are NOT equal\nMissing data?\n";
# }

# Get proper date when updating, default to old date
my $updatedDate;
if ($opts{u} && !$archive) {
  my @months = qw (January February March April May June July August September
		   October November December);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime;
  $year += 1900;		# Convert to 4-digit year
  $updatedDate = "$months[$mon] $mday, $year";

  # Save for next time
  open my $dOut, '>', "$dateFile" or die $ERRNO;
  print $dOut $updatedDate;
  close $dOut or die $ERRNO;
} else {
  open my $dOut, '<', "$dateFile" or die $ERRNO;
  while (<$dOut>) {
    chomp;
    $updatedDate = $_;
  }
  close $dOut or die $ERRNO;
}


# Allow for noncanonical filenames (masterdata, per-game stats) FIXME TODO
my $filename = $input;
my %seasons = (
	       s => 'Spring',
	       u => 'Summer',
	       f => 'Fall');
my ($season,$date) = (q{},q{});	# WOW this is ugly FIXME TODO
if ($input =~ m/mls_t?[suf]\d\d\.csv/) {
  $filename =~ s/^(?:archive\/)?mls_(t?[suf]1\d)\.csv$/$1/;
  $season = ($filename =~ /^t/) ? 'Tournament ' : q{};
  $season .= $seasons{substr $filename, -3, 1};
  $date = '20'.substr $filename, -2, 2;
}
# Need to get date and season info right for table html FIXME TODO



# Build hash of header row titletips
while (<DATA>) {
  chomp;
  my @titles = split;
  my $title = shift @titles;
  $titleTips{$title} = join q{ }, @titles;
}

open my $out, '>', "$output" or die $ERRNO;

if ($archive) {
  print $out '<span class="header-nav">← <a href="../archive">Return to the archive index</a>';
  print $out ' | <a href="../">return home</a></span>';
} else {
  $filename = 'latest';
}
print $out "<h3>\n";
print $out "<a id=\"mls-stats-$filename\" class=\"anchor\" ";
print $out "href=\"#mls-stats-$filename\" aria-hidden=\"true\">";
print $out '<span class="octicon octicon-link"></span>';

my $status = $opts{l} ? 'latest season' : 'ongoing';
$status = 'archived' if $archive;
print $out "</a>MLS stats, $season $date ($status)</h3>\n";

# Sortify
print $out '<p>Click on the column headers to sort the table.';
if (!$archive) {
  print $out "  Data are current as of $updatedDate.";
}
print $out "</p>\n\n";

# Handle archive relativity
my $archivePre = q{};
$archivePre ='../' if $archive;

print $out '<script src=\'';
print $out $archivePre;
print $out "tablesort.min.js'></script>\n";
print $out '<script src=\'';
print $out $archivePre;
print $out "tablesort.number.js'></script>\n\n";
print $out "<table id='mls-table'>\n";

# Header row
print $out "<thead>\n";
print $out "<tr>\n";

foreach my $col (0..scalar @header - 1) {
  print $out '<th';
  # Don't sort blank columns
  if ($header[$col] eq q{}) {
    print $out ' class=\'no-sort\'';
  } elsif ($col > 0) {
    print $out ' data-sort-method=\'number\'';
  }
  if ($titleTips{$header[$col]}) {
    print $out " title='$titleTips{$header[$col]}'";
  }
  print $out ">$header[$col]</th>\n";
}

print $out "</tr>\n";
print $out "</thead>\n";


# Data
print $out "<tbody>\n";

foreach my $name (@names) {
  # Don't sort blank row before totals
  if ($name eq q{}) {
    print $out "<tr class='no-sort'>\n";
  } else {
    print $out "<tr>\n";
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

  print $out "</tr>\n";
}

# Footer totals row
# Don't sort totals
print $out "<tr class='no-sort'>\n";
foreach my $col (0..scalar @total - 1) {
  print $out "<td style='font-weight:bold;'>$total[$col]</td>\n";
}

print $out "</tr>\n";
print $out "</tbody>\n";
print $out "</table>\n\n";

# More sortification
print $out "<script>\n";
print $out "new Tablesort(document.getElementById('mls-table'));\n";
print $out "</script>\n";

close $out or die $ERRNO;


#### Usage statement ####
# Use POD or whatever?
# Escapes not necessary but ensure pretty colors
# Final line must be unindented?
sub usage
  {
    print <<"USAGE";
Usage: $PROGRAM_NAME [-uah] mls_data.csv [output.html]
      -u Update the last-modified date of the index page
      -a Indicate input is an archived file, treat differently
      -l Offseason message
      -h Print this help message
USAGE
  }



## The lines below do not represent Perl code, and are not examined by the
## compiler.  Rather, they are brief descriptions of the statics, provided in
## order to make reading the stats tables easier.
__END__
Player Minor league science, Major league style
  PA Plate appearances
  AB At Bats
  R Runs
  H Hits
  2B Doubles
  3B Triples
  HR Home Runs
  RBI Runs Batted In
  BB Walks (bases-on-balls)
  K Strikeouts
  SAC Sacrifice flies
  AVG Batting average - H/AB
  OBP On-Base Percentage - (H+BB)/PA
  SLG Sugging percentage - Total bases/AB
  OPS On-base Plus Slugging - OBP+SLG
