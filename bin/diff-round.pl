#!/usr/bin/perl
# $Id$

# diff-round.pl - diff two ff files, i.e., files of floating point numbers, where
#                 rounding differences are not real differences
# 
# PROGRAMMER: Eric Joanis
# 
# COMMENTS:
#
# Groupe de technologies langagières interactives / Interactive Language Technologies Group
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2006, Conseil national de recherches du Canada / Copyright 2006, National Research Council of Canada

use strict;
use warnings;

sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: diff-round.pl [-h(elp)] [-prec P] infile1 infile2

  Assuming infile1 and infile2 are files with one number per line, compare them
  ignoring differences past the P'th significant digit.
  More precisely, ignore differences where |a-b| < max(|a|,|b|) / 10^P.

Options:
  -prec P       precision to retain before comparing [6]
  -h(elp):      print this help message
";
   exit 1;
}

use Getopt::Long;
my $prec = 6;
GetOptions(
   help         => sub { usage },
   "prec=i"     => \$prec,
) or usage;

2 == @ARGV or usage "Must specify exactly two input files.";

open F1, $ARGV[0] or die "Can't open $ARGV[0]: $!";
open F2, $ARGV[1] or die "Can't open $ARGV[1]: $!";

sub max($$) {
   $_[0] < $_[1] ? $_[1] : $_[0];
}

while (<F1>) {
   my $L1 = $_; chomp $L1;
   my $L2 = <F2>; chomp $L2;
   die "Unexpected end of $ARGV[1] before end of $ARGV[0] at line $.\n"
      unless defined $L2;

   # Optimization: don't do the fancy (and expensive) math if the lines are
   # identical
   next if $L1 eq $L2;

   if ( abs($L1 - $L2) * 10**$prec > max(abs($L1), abs($L2)) ) {
      print "$.	< $L1	> $L2\n"
   }
}
die "Unexpected end of $ARGV[0] before end of $ARGV[1] at line $.\n"
   unless eof(F2);


