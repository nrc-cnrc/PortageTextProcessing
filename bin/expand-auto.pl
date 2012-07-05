#!/usr/bin/env perl
# $Id$

# @file expand-auto.pl
# @brief Like expand, but with automatically calculated tab stops.
#
# @author Eric Joanis
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2010, Sa Majeste la Reine du Chef du Canada /
# Copyright 2010, Her Majesty in Right of Canada


use strict;
use warnings;

sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: $0 [INPUT FILE(S)]

  Like expand, but with automatically calculated tab stops, such that
  columns are separated by three spaces.
  Caveat: holds all input in memory -- don't use with large files!

  -skip X  ignore first X lines of input.
  -tab T   expand tabs to leave T blank characters between colunns [3]

";
   exit 1;
}

my $skip_head = 0;
my $tab_width = 3;
use Getopt::Long;
GetOptions(
   "skip=i"    => \$skip_head,
   "tab=i"     => \$tab_width,
   help        => sub { usage },
) or usage;

sub max($$) {
   $_[0] < $_[1] ? $_[1] : $_[0];
}

my @rows;
my @column_widths;

while (<>) {
   my @tokens = split /\t/;
   push @rows, \@tokens;
   next if ($. <= $skip_head);
   if (@tokens > 1) {
      for (my $i = 0; $i <= $#tokens; ++$i) {
         $column_widths[$i] = max(length($tokens[$i]), ($column_widths[$i]||0));
      }
   }
}

# Set the space between columns at $tab_width space characters
foreach (@column_widths) {
   $_ += $tab_width;
}

foreach (@rows) {
   for (my $i = 0; $i < $#$_; ++$i) {
      printf "%-$column_widths[$i]s", $_->[$i];
   }
   if ($#$_ >= 0) {
      print $_->[$#$_];
   }
}
