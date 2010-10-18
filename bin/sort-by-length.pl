#!/usr/bin/perl 
# $Id$

# @file sort-by-length.pl 
# @brief sort a text file by sentence length.
#
# @author Eric Joanis
#
# COMMENTS:
#
# Eric Joanis
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2005, Sa Majeste la Reine du Chef du Canada /
# Copyright 2005, Her Majesty in Right of Canada

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
printCopyright "sort-by-length.pl", 2005;
$ENV{PORTAGE_INTERNAL_CALL} = 1;


sub usage {
    local $, = "\n";
    print STDERR @_, "";
    $0 =~ s#.*/##;
    print STDERR "
Usage: $0 [<input file(s)>]

  Sort the input in increasing length of lines.

Options:

  -h(elp)   Print this help message
  -n        Print line numbers

";
    exit 1;
}

use Getopt::Long;
GetOptions(
    help        => sub { usage },
    n           => \my $print_numbers,
) or usage;

# Read the whole input, be it stdin or any number of files specified on the
# command line
my @lines = <>; 
# Print it by sorted order of length using a Schwarzian transform.
print
    map { $print_numbers ? "$_->[0]\t$_->[1]" : $_->[1] }
    sort { $a->[2] <=> $b->[2] }
    map { [$_+1, $lines[$_], length $lines[$_]] } # 0: line no; 1: line, 3: len
    (0 .. $#lines);

