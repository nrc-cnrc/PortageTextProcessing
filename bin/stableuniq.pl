#!/usr/bin/perl -sw

# stableuniq.pl
# 
# PROGRAMMER: Aaron Tikuisis
# 
# COMMENTS:
# 
# Groupe de technologies langagieres interactives / Interactive Language Technologies Group
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2005, Sa Majeste la Reine du Chef du Canada /
# Copyright 2005, Her Majesty in Right of Canada

use strict;

my $HELP =
"Usage: $0 [INPUT [OUTPUT]]

Outputs unique lines from INPUT (or standard input) to OUTPUT (or standard output).  INPUT
is not required to be sorted, and lines are not reordered (as opposed to using sort and
uniq to find unique lines).

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

open(IN, "<$in") or die "Cannot open $in for input";
open(OUT, ">$out") or die "Cannot open $out for output";

while (my $line = <IN>)
{
    print OUT $line if not exists $existing{$line};
    $existing{$line} = 1;
} # while
