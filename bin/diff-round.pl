#!/usr/bin/perl
# $Id$
#
# diff-round.pl - diff two ff files, i.e., files of floating point numbers,
#                 where rounding differences are not real differences
#
# PROGRAMMER: Eric Joanis
#
# Technologies langagieres interactives / Interactive Language Technologies
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2006, Sa Majeste la Reine du Chef du Canada /
# Copyright 2006, Her Majesty in Right of Canada

use strict;
use warnings;

sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: diff-round.pl [-h(elp)] [-prec P] infile1 infile2

  Assuming infile1 and infile2 are files of numbers with the same layout,
  compare them ignoring differences past the P'th significant digit.
  More precisely, ignore differences where |a-b| < max(|a|,|b|) / 10^P.
  Compressed files are decompressed automatically as necessary.

Options:
  -prec P   number of identical digits to required for equality [6]
  -h(elp):  print this help message
  -sort:    sort the files before doing the diff, e.g., to compare two
            phrase tables or ttables containing the same phrase/word pairs.
  -q:       don't print individual differences, just a global summary

Exit status:
   0 if no differences were found (within P)
   1 if a difference was found
   2 if the files don't have the same length
   3 if there was some problem running the program.
";
   exit 3;
}

use Getopt::Long;
my $prec = 6;
GetOptions(
   help     => sub { usage },
   "prec=f" => \$prec,
   z        => sub { print STDERR
                  "-z no longer required: automatically enabled as needed\n";
               },
   sort     => \my $sort,
   quiet    => \my $quiet,
) or usage;
my $pow_prec = 1/(10**$prec);

2 == @ARGV or usage "Must specify exactly two input files.";

# Will hold the maximum numerical difference found
my $max_diff = 0;

if ( $sort ) {
   open F1, "gzip -cqfd $ARGV[0] | LC_ALL=C sort |"
      or die "Can't create pipe for sorting $ARGV[0]: $!";
   open F2, "gzip -cqfd $ARGV[1] | LC_ALL=C sort |"
      or die "Can't create pipe for sorting $ARGV[1]: $!";
} else {
   open F1, "gzip -cqfd $ARGV[0] |"
      or die "Can't create pipe for decompressing $ARGV[0]: $!";
   open F2, "gzip -cqfd $ARGV[1] |"
      or die "Can't create pipe for decompressing $ARGV[1]: $!";
} 
#else {
#   open F1, $ARGV[0] or die "Can't open $ARGV[0]: $!";
#   open F2, $ARGV[1] or die "Can't open $ARGV[1]: $!";
#}

sub max($$) {
   $_[0] < $_[1] ? $_[1] : $_[0];
}

# is_num($token) returns whether $token is a valid C number
# Precondition: $token is already stripped of leading and trailing whitespace
sub is_num($) {
   use POSIX;
   local $! = 0;
   my ($value, $n_unparsed) = POSIX::strtod($_[0]);
   return !(($_[0] eq '') || ($n_unparsed != 0) || $!);
}

# diff_epsilon($a, $b) returns true iff $a and $b differ by more than their
# $prec'th significant digit.
sub diff_epsilon ($$) {
   return 0 if $_[0] eq $_[1];
   return 1 if (!is_num($_[0]) || !is_num($_[1]));
   my $max = max(abs($_[0]), abs($_[1]));
   if ( $max > 0 ) {
      my $rel_diff = abs($_[0] - $_[1]) / $max;
      $max_diff = $rel_diff if ($rel_diff > $max_diff);
      return ($rel_diff > $pow_prec);
   } else {
      return 0;
   }
}

my $found_diff = 0;
while (<F1>) {
   my $L1 = $_; chomp $L1;
   my $L2 = <F2>; chomp $L2 if defined $L2;
   if ( ! defined $L2 ) {
      warn "Unexpected end of $ARGV[1] before end of $ARGV[0] at line $.\n";
      exit 2;
   }

   # Optimization: don't do the fancy (and expensive) math if the lines are
   # identical
   next if $L1 eq $L2;

   # Split each line into space separated tokens
   my @L1 = split /\s+/, $L1;
   my @L2 = split /\s+/, $L2;

   if ( $#L1 != $#L2 ) {
      print "$. << $L1   >> $L2\n" unless $quiet;
      $found_diff = 1;
   } else {
      for my $i (0 .. $#L1) {
         if ( diff_epsilon($L1[$i], $L2[$i]) ) {
            print $., ($#L1 > 0 ? "($i)" : ""), " < $L1[$i]   > $L2[$i]\n"
               unless $quiet;
            $found_diff = 1;
         }
      }
   }

   #if ( abs($L1 - $L2) * 10**$prec > max(abs($L1), abs($L2)) ) {
   #   print "$.	< $L1	> $L2\n"
   #}
}
if ( ! eof(F2) ) {
   warn "Unexpected end of $ARGV[0] before end of $ARGV[1] at line $.\n";
   exit 2;
}

print STDERR "$ARGV[0] and $ARGV[1] differ\n"
   if $quiet and $found_diff;
print STDERR "Maximum relative numerical difference: $max_diff\n"
   unless $quiet && !$max_diff;
print STDERR "Threshold used: $pow_prec\n"
   unless $quiet;

exit ($found_diff ? 1 : 0);
