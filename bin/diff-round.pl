#!/usr/bin/env perl
#
# @file diff-round.pl 
# @brief diff two ff files, i.e., files of floating point numbers, where
# rounding differences are not real differences
#
# @author Eric Joanis
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2006, Sa Majeste la Reine du Chef du Canada /
# Copyright 2006, Her Majesty in Right of Canada

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
printCopyright "diff-round.pl", 2006;
$ENV{PORTAGE_INTERNAL_CALL} = 1;

# We want locale-insensitive processing
use POSIX qw(locale_h);
use locale;
setlocale(LC_ALL, "POSIX");


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
  -prec P    number of identical digits required for equality [6]
  -h(elp):   print this help message
  -sort:     sort the files before doing the diff, e.g., to compare two
             phrase tables or ttables containing the same phrase/word pairs
  -diffpipe: use diffpipe to handle line insertions and deletions.
  -q:        don't print individual differences, just a global summary
  -min:      use min(|a|,|b|) instead of max when calculating rel diffs
  -abs:      use |a-b| instead of a relative difference

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
   diffpipe => \my $pipe,
   quiet    => \my $quiet,
   min      => \my $use_min,
   abs      => \my $use_abs,
) or usage;
my $pow_prec = 1/(10**$prec);

2 == @ARGV or usage "Must specify exactly two input files.";

if (-d $ARGV[1] && -f $ARGV[0]) {
   $ARGV[1] .= "/" . `basename $ARGV[0]`;
   $ARGV[1] =~ s/\s*$//;
}

if ( $pipe ) {
   my $sort_cmd = ($sort ? " LC_ALL=C sort |" : "");
   exec("diffpipe -w -prec $prec 'gzip -cqfd $ARGV[0] |$sort_cmd' 'gzip -cqfd $ARGV[1] |$sort_cmd'")
      or die "Can't exec diffpipe: $!";
}

# Will hold the maximum numerical difference found
my $max_diff = 0;
# Will be true if an infinite numerical difference was found (i.e., one value
# was 0 and the other wasn't)
my $inf_max_diff = 0;

# make_open_cmd($file) returns a command to unzip $file, if it is a file, or
# leaves it alone if it already is a piped command.
# If $sort is true, also adds a sort command to the pipe.
sub make_open_cmd($) {
   my $file = $_[0];
   if ( $file !~ /\|$/ ) {
      -r $file or -r "$file.gz" or $file eq "-" or die "Can't open $file: $!\n";
      $file = "gzip -cqdf $file |";
   }
   if ( $sort ) {
      $file = "$file LC_ALL=C sort |";
   }
   return $file;
}

open F1, make_open_cmd($ARGV[0])
   or die "Can't create pipe for sorting and/or decompressing $ARGV[0]: $!";
open F2, make_open_cmd($ARGV[1])
   or die "Can't create pipe for sorting and/or decompressing $ARGV[1]: $!";

sub max($$) { $_[0] < $_[1] ? $_[1] : $_[0]; }
sub min($$) { $_[0] > $_[1] ? $_[1] : $_[0]; }

# is_num($token) returns whether $token is a valid C number
# Precondition: $token is already stripped of leading and trailing whitespace
sub is_num($) {
   use POSIX;
   local $! = 0;
   my ($value, $n_unparsed) = POSIX::strtod($_[0]);
   return !(($_[0] eq '') || ($n_unparsed != 0) || $!);
}

# display($val) displays $val in reasonably few characters.
sub display($) {
   my ($val) = @_;
   if ( $val > 0.999 and $val < 1 ) {
      my $res = sprintf "%.40g", $val;
      my ($nines) = $res =~ /(0\.9+)/;
      if ( defined $nines ) {
         my $nine_count = length($nines)-2;
         #print "$res nines $nines nine_count $nine_count\n";
         return sprintf "%.".($nine_count+3)."g", $val;
      } else {
         return sprintf "%7g", $val;
      }
   }
   if ( abs($val) >= 0.001 and abs($val) < 1000000 ) {
      return sprintf "%7g", $val;
   } else {
      return sprintf "%.4g", $val;
   }
}

# diff_epsilon($a, $b) returns true iff $a and $b differ by more than their
# $prec'th significant digit.
sub diff_epsilon ($$) {
   return (0,0) if $_[0] eq $_[1];
   return (1,"n/a") if (!is_num($_[0]) || !is_num($_[1]));
   return (0,0) if $_[0] == $_[1];
   my $denom;
   if ( $use_abs )    { $denom = 1; }
   elsif ( $use_min ) { $denom = min(abs($_[0]), abs($_[1])); }
   else               { $denom = max(abs($_[0]), abs($_[1])); }
   if ( $denom > 0 ) {
      my $rel_diff = abs($_[0] - $_[1]) / $denom;
      $max_diff = $rel_diff if ($rel_diff > $max_diff);
      return (($rel_diff > $pow_prec), display($rel_diff));
   } elsif ( $use_min ) {
      $inf_max_diff = 1;
      return (1,"inf");
   } else {
      return (0,0);
   }
}

my $diff_type = $use_abs ? "abs diff" : "rel diff";
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
   $L1 =~ s/\s+$//; $L1 =~ s/^\s+//;
   $L2 =~ s/\s+$//; $L2 =~ s/^\s+//;
   my @L1 = split /\s+/, $L1;
   my @L2 = split /\s+/, $L2;

   if ( $#L1 != $#L2 ) {
      print "$. << $L1   >> $L2\n" unless $quiet;
      $found_diff = 1;
   } else {
      for my $i (0 .. $#L1) {
         my ($is_diff, $rel_diff) = diff_epsilon($L1[$i], $L2[$i]);
         if ( $is_diff ) {
            if ( ! $quiet ) {
               if ( $rel_diff eq "n/a" ) {
                  print $., ($#L1 > 0 ? "($i)" : ""), " < $L1[$i]   > $L2[$i]\n"
               } else {
                  print $., ($#L1 > 0 ? "($i)" : ""), " < $L1[$i]   > $L2[$i]   $diff_type: $rel_diff\n"
               }
            }
            $found_diff = 1;
         }
      }
   }

   #if ( abs($L1 - $L2) * 10**$prec > min(abs($L1), abs($L2)) ) {
   #   print "$.	< $L1	> $L2\n"
   #}
}
if ( ! eof(F2) ) {
   warn "Unexpected end of $ARGV[0] before end of $ARGV[1] at line $.\n";
   exit 2;
}

print STDERR "$ARGV[0] and $ARGV[1] differ\n"
   if $quiet and $found_diff;
my $relative = $use_abs ? "absolute" : "relative";
print STDERR "Maximum $relative numerical difference: $max_diff\n"
   unless $quiet && !$max_diff;
print STDERR "At least one infinite (zero vs non-zero) difference\n"
   if $inf_max_diff;
print STDERR "Threshold used: $pow_prec\n"
   unless $quiet;

exit ($found_diff ? 1 : 0);
