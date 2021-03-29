#!/usr/bin/env perl

# @file parallel-uniq.pl
# @brief Remove duplicate lines from parallel files, where a duplicate is a
# line which is identical to another in *both* files at the same time.
#
# @author Eric Joanis
#
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
printCopyright "parallel-uniq.pl", 2005;
$ENV{PORTAGE_INTERNAL_CALL} = 1;


sub usage {
    local $, = "\n";
    print STDERR @_, "";
    $0 =~ s#.*/##;
    print STDERR "
Usage: $0 [-h(elp)] [-v(erbose)] <file1> <file2>

  Remove duplicate lines from parallel files, where a duplicate is a line
  which is identical to another in *both* files at the same time.

  Writes the result to file1.uniq and file2.uniq.

Options:

  -h(elp):      print this help message
  -v(erbose):   increment the verbosity level by 1 (may be repeated)
  -d(ebug):     print debugging information

";
    exit @_ ? 1 : 0;
}

use Getopt::Long;
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
my $verbose = 1;
GetOptions(
    help        => sub { usage },
    verbose     => sub { ++$verbose },
    quiet       => sub { $verbose = 0 },
    debug       => \my $debug,
) or usage "Error: Invalid option(s).";

@ARGV > 1 or usage "Error: Missing file name(s)";

my $file1 = shift;
my $file2 = shift || "-";

0 == @ARGV or usage "Error: Superfluous argument(s): @ARGV";

if ( $debug ) {
    no warnings;
    print STDERR "
    file1       = $file1
    file2       = $file2
    verbose     = $verbose
    debug       = $debug

";
}

open(FILE1, "$file1") or die "Error: Can't open $file1 for reading: $!\n";
open(FILE2, "$file2") or die "Error: Can't open $file2 for reading: $!\n";
open(OUT1, ">$file1.uniq") or die "Error: Can't create $file1.uniq: $!\n";
open(OUT2, ">$file2.uniq") or die "Error: Can't create $file2.uniq: $!\n";

# hash of hashes: $seen{$line1}{$line2} exists if $line1 exists in $file1 at
# the same position as $line2 in $file2.
my %seen;

my $line = 0;
while (<FILE1>) {
    $line++;
    my $line1 = $_;
    my $line2 = <FILE2>;
    if ( ! defined $line2 ) {
        print STDERR "$0: $file2 shorter than $file1: unexpected EOF at line $line\n";
        last;
    }
    if ( ! exists $seen{$line1}{$line2} ) {
        # This is not a duplicate line
        $seen{$line1}{$line2} = 1;
        print OUT1 $line1;
        print OUT2 $line2;
    }
}

if (defined <FILE2>) {
    print STDERR "$0: $file1 shorter than $file2: unexpected EOF at line $line\n";
}

