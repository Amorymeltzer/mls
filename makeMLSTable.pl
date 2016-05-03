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
getopts('uagh',\%opts);

if ($opts{h} || @ARGV == 0 || @ARGV > 2) {
  usage();
  exit;
}

my $input = $ARGV[0];
my $output = $ARGV[1] // 'table.table';
my $archive = $opts{a} // 0;	# Treat old ones slightly differently
my $game = $opts{g} // 0;	# Treat old ones slightly differently



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
  $tmp[-1] =~ s/\r//g;		# No stupid ^M crap
  if ($tmp[0] =~ /Player/) {
    @header = @tmp;

    # Try to catch some potential errors
    if ($header[-1] ne 'wOBA') {
      warn "Warning: Potential extra columns detected in $input!!\n";
    }
    if ($NR != 1) {
      warn "Warning: Potential extra rows detected in $input!\n"
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

# Atempt to replace previous good data check with these mediocre data checks
if ($total[3]+$total[10] > $total[1]) {
  warn "Warning: H+K is greater than AB\nIncorrect data in $input?\n";
}
if ($total[2] != $total[8]) {
  warn "Warning: R and RBIs are not equal\nIncorrect data in $input?\n";
}

# Date parsing
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime;
$year += 1900;			# Convert to 4-digit year
my @months = qw (January February March April May June July August September
		 October November December);
my $updatedDate;
# Get proper date when updating, default to old date
if ($opts{u} && !$archive) {
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


# Allow for noncanonical filenames (mls_master, per-game stats)
my $status = q{};		# Likely default
if ($input =~ m/mls_t?[suf]\d\d/) {
  my %seasons = (
		 s => 'Spring',
		 u => 'Summer',
		 f => 'Fall');

  my ($kludge) = $input =~ s/^(?:archive\/)?mls_(t?[suf]1\d(_\d\d\.\d\d)?)\.csv$/$1/r;

  my $season;
  $season = 'Tournament ' if $kludge =~ /^t/;

  $kludge =~ s/t?([suf]\d\d.*)/$1/;

  $season .= $seasons{substr $kludge, 0, 1};
  my $date = '20'.substr $kludge, 1, 2;


  # Attempt to divine current season
  # Not exact, esp. around June
  # Will just zero-out for specific game files, since it's unneeded
  my $curSeason = ($mon < 8 && $mon > 4) ? 'Summer' : 'Fall';
  $curSeason = ($mon < 3 || $mon > 4) ? $curSeason : 'Spring';

  if ($curSeason eq $season && $date eq $year) {
    $status = ' (ongoing)';
  }

  # Natural format for specific game files
  if ($input =~ m/mls_t?[suf]1\d_(\d\d\.\d\d)\.csv/) {
    my @dates = split /\./, $1;
    if ($dates[1] =~ m/^0/) {
      $dates[1] = (split //, $dates[1])[1];
    }
    $season = $months[$dates[0]-1].q{ }.$dates[1].q{,};
    $status = q{};
  }

  $status = "$season $date stats table$status";
} else {
  $status = 'Lifetime stats table';
}


# Build hash of header row titletips
while (<DATA>) {
  chomp;
  my @titles = split;
  my $title = shift @titles;
  $titleTips{$title} = join q{ }, @titles;
}

open my $out, '>', "$output" or die $ERRNO;

print $out "<h3>\n";
print $out '<a id="statstable" class="anchor" href="#statstable" aria-hidden="true">';
print $out '<span class="octicon octicon-link"></span>';
print $out "</a>$status</h3>\n";

# Sortify
print $out '<p>Click on the column headers to sort the table.';
if (!$archive) {
  print $out "  Data are current as of $updatedDate.";
}
print $out "</p>\n\n";

print $out "<script src='/mls/js/tablesort.min.js'></script>\n";
print $out "<script src='/mls/js/tablesort.number.js'></script>\n\n";
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
      -a Indicate input is a season file, treat differently
      -g Indicate input is a game file, treat differently
      -h Print this help message
USAGE
    return;
  }



## The lines below do not represent Perl code, and are not examined by the
## compiler.  Rather, they are brief descriptions of the statics, provided in
## order to make reading the stats tables easier.
__END__
Player Minor league science, Major league style
  AB At Bats
  R Runs
  H Hits
  2B Doubles
  3B Triples
  HR Home Runs
  TB Total Bases
  RBI Runs Batted In
  BB Walks (bases-on-balls)
  K Strikeouts
  SAC Sacrifice flies
  AVG Batting average - H/AB
  OBP On-Base Percentage - (H+BB)/(AB+BB+SAC)
  SLG Sugging - TB/AB
  ISO Isolated Power - SLG-AVG
  OPS On-base percentage Plus Slugging - OBP+SLG
  GPA Gross Production Average - (1.8*OBP+SLG)/4
  wOBA Weighted On-Base Average - Uses linear weights to calculate true value of each offensive action (weights are from MLB 2010 season)
