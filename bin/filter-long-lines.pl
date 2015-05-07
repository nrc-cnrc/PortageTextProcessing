#!/usr/bin/env perl

# @file filter-long-lines.pl 
# @brief Filter out long lines (> L tokens) from multiple line-aligned files. 
# Write output to files <fileN>.filt<L>.
# 
# @author Darlene Stewart based on George Foster's strip-parallel-blank-lines.pl
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2010, Sa Majeste la Reine du Chef du Canada /
# Copyright 2010, Her Majesty in Right of Canada

use strict;
use warnings;

BEGIN {
   # If this script is run from within src/ rather than being properly
   # installed, we need to add utils/ to the Perl library include path (@INC).
   if ( $0 !~ m#/bin/[^/]*$# ) {
      my $bin_path = $0;
      $bin_path =~ s#/[^/]*$##;
      unshift @INC, "$bin_path/../utils";
   }
}

use portage_utils;
printCopyright("filter-long-lines.pl", 2010);
$ENV{PORTAGE_INTERNAL_CALL} = 1;

my $HELP = "
filter-long-lines.pl [-length=LEN] FILE1 [FILE2 [FILE3]]

  Filter out lines longer than LEN tokens from multiple line-aligned files.
  If the ith line is longer than LEN tokens in any of the input files, then
  the ith input line is omitted from all the output files.
  
  Output is written to files <FILEn>.filt<LEN>
  
  Options:
  
  -length=LEN  Filter lines greater than LEN tokens in length. [300]
  -v           Be verbose.
  -d           Print debugging information.
  -h           Print this help message and exit.

";

# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
use Getopt::Long;
my $verbose = 0;

Getopt::Long::GetOptions(
   'help'           => sub { print $HELP; exit 0 },
   "verbose+"       => \$verbose,
   "debug"          => \my $debug,

   "length=i"       => \my $long,
) or (die $HELP, "Error: filter-long-lines.pl aborted due to bad option.\n");

$long = 300 unless defined $long;
$long > 0 or die $HELP, "Error: length must be a positive integer.\n";

@ARGV <= 3 or die $HELP, "Error: Too many arguments.\n";
@ARGV > 0 or die $HELP, "Error: Too few arguments. Input file FILE1 required.\n";

my ($in1, $in2, $in3) = ("", "", "");
$in1 = shift;
$in2 = shift;
$in3 = shift;

sub getOutputFilename($$) {
   my ($out, $len) = @_;
   if ($out =~ s/\.gz$//) {
      $out .= ".filt${len}" . ".gz";
   } else {
      $out .= ".filt${len}";
   }
   return $out;
}

zopen(*IN1, "$in1") or die "Error: Cannot open $in1 for reading\n";
my $out1 = getOutputFilename($in1, $long);
zopen(*OUT1, ">$out1") or die "Error: Cannot open $out1 for writing\n";

if ($in2) {
   zopen(*IN2, "$in2") or die "Error: Cannot open $in2 for reading\n";
   my $out2 = getOutputFilename($in2, $long);
   zopen(*OUT2, ">$out2") or die "Error: Cannot open $out2 for writing\n";
}
if ($in3) {
   zopen(*IN3, "$in3") or die "Error: Cannot open $in3 for reading\n";
   my $out3 = getOutputFilename($in3, $long);
   zopen(*OUT3, ">$out3") or die "Error: Cannot open $out3 for writing\n";
}

my ($line1, $line2, $line3);
my ($len1, $len2, $len3) = (0, 0, 0);
my (@line);
my ($print_cnt, $skip_cnt) = (0, 0);
while ($line1 = <IN1>) {
   @line = split(' ',$line1);
   $len1 = @line;
   if ($in2) {
      if (not $line2 = <IN2>) {die "Error: file $in2 is too short!\n"};
      @line = split(' ',$line2);
      $len2 = @line;
   }
   if ($in3) {
      if (not $line3 = <IN3>) {die "Error: file $in3 is too short!\n"};
      @line = split(' ',$line3);
      $len3 = @line;
   }
   if ($len1 > $long || $len2 > $long || $len3 > $long) {
      ++$skip_cnt;
      if ($debug) {
         print STDERR "Skipping line ", $skip_cnt+$print_cnt, "; # tokens: $len1, $len2, $len3\n";
      }
   } else {
      ++$print_cnt;
      print OUT1 $line1;
      if ($in2) {
         print OUT2 $line2;
      }
      if ($in3) {
         print OUT3 $line3;
      }
   }
}

if ($in2 && <IN2>) { die "Error: file $in2 is too long!\n"; }
if ($in3 && <IN3>) { die "Error: file $in3 is too long!\n"; }

if ($verbose || $debug) {
   print STDERR "Read ", $skip_cnt+$print_cnt, " lines.\n";
   print STDERR "Found $skip_cnt lines with > $long tokens.\n";
   print STDERR "Wrote $print_cnt lines.\n";
}
