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

";
    exit 1;
}

# Read the whole input, be it stdin or any number of files specified on the
# command line
my @lines = <>; 
# Print it by sorted order of length using a Schwarzian transform.
print
    map { $_->[0] }
    sort { $a->[1] <=> $b->[1] }
    map { [$_, length $_] }
    @lines;

