#!/usr/bin/perl 
# $Id$

# sort-by-length.pl - sort a text file by sentence length
#
# PROGRAMMER: Eric Joanis
#
# COMMENTS:
#
# Eric Joanis
# Groupe de technologies langagières interactives / Interactive Language Technologies Group
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2005, Conseil national de recherches du Canada / Copyright 2005, National Research Council of Canada

use strict;
use warnings;

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
    map { [$_, $lines[$_], length $lines[$_]] } # 0: line no; 1: line, 3: len
    (0 .. $#lines);

