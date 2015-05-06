#!/usr/bin/perl -sw

# @file stableuniq.pl 
# @brief Output unique lines from INPUT (or standard input) to OUTPUT (or
# standard output).
# 
# @author Aaron Tikuisis
# 
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2005, Sa Majeste la Reine du Chef du Canada /
# Copyright 2005, Her Majesty in Right of Canada

use strict;

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
printCopyright "stableuniq.pl", 2005;
$ENV{PORTAGE_INTERNAL_CALL} = 1;


my $HELP =
"Usage: stableuniq.pl [INPUT [OUTPUT]]

Output unique lines from INPUT (or standard input) to OUTPUT (or standard
output). INPUT is not required to be sorted, and lines are not reordered (as
opposed to using sort and uniq to find unique lines).

";

our ($h, $help);

if (defined $h || defined $help)
{
    print $HELP;
    exit;
}

my %existing = ();

my $in = shift || "-";
my $out = shift || "-";

open(IN, "<$in") or die "Error: Cannot open $in for input";
open(OUT, ">$out") or die "Error: Cannot open $out for output";

while (my $line = <IN>)
{
    print OUT $line if not exists $existing{$line};
    $existing{$line} = 1;
} # while
