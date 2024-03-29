#!/usr/bin/env perl

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
  -utf8    process the text in UTF-8

";
   exit @_ ? 1 : 0;
}

my $skip_head = 0;
my $tab_width = 3;
my $utf8 = 0;
BEGIN {
   # Open parsing in a BEGIN block so $utf8 is available to use pragma below
   use Getopt::Long;
   GetOptions(
      "skip=i"    => \$skip_head,
      "tab=i"     => \$tab_width,
      utf8        => \$utf8,
      help        => sub { usage },
   ) or usage "Error: Invalid option(s).";
}

# If -utf8 occurs on the command line, set all files to utf-8 by default
# use open ':std', ':encoding(UTF-8)'; would be simpler, but it cannot be inside an if
# statement since it is lexically scoped.
use if $utf8, 'open', ':std', ':encoding(UTF-8)';

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
