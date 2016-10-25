#!/usr/bin/env perl

# @file second-to-hms.pl
# @brief Convert from and to human readable time
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2009, Sa Majeste la Reine du Chef du Canada /
# Copyright 2009, Her Majesty in Right of Canada

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
printCopyright "second-to-hms.pl", 2009;
$ENV{PORTAGE_INTERNAL_CALL} = 1;

sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: $0 [options] [IN [OUT]]

  Convert from seconds to HH:MM:SS or vice-versa.

Options:

  -r(everse)    Convert to seconds
  -m(inutes)    Convert to minutes
  -ho(urs)      Convert to hours

  -h(elp)       print this help message
  -v(erbose)    increment the verbosity level by 1 (may be repeated)
  -d(ebug)      print debugging information
";
   exit @_ ? 1 : 0;
}


use Getopt::Long;
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
my $verbose = 1;
my $debug = undef;
my $minutes;
my $hours;
GetOptions(
   reverse     => \my $hmsToSeconds,
   minutes     => sub { $minutes = 1; $portage_utils::DHMS_minutes = 1 },
   hours       => sub { $hours = 1; $portage_utils::DHMS_hours = 1 },

   help        => sub { usage },
   h           => sub { usage }, # disambiguate -h to mean -help, not -hours
   verbose     => sub { ++$verbose },
   quiet       => sub { $verbose = 0 },
   debug       => \$debug,
) or usage "Error: Invalid option(s).";


#perl -ple 'BEGIN{sub pod {@parts = gmtime($1); return sprintf("%dd%dh%dm%ds",@parts[7,2,1,0]);}}; s/([0-9.]+)s/&pod($1)/e' < LOG.timing

my $in = shift || "-";
my $out = shift || "-";

0 == @ARGV or usage "Error: Superfluous argument(s): @ARGV";

open(IN, "<$in") or die "Error: Can't open $in for reading: $!\n";
open(OUT, ">$out") or die "Error: Can't open $out for writing: $!\n";


while (<IN>) {
   if ($hmsToSeconds) {
      s/(?:([0-9]+)d)?(?:([0-9]+)h)?(?:([0-9]+)m)?(?:([0-9]+(?:\.[0-9]*)?)s)/&portage_utils::DHMS2Seconds($1, $2, $3, $4) . ($minutes || $hours ? "" : "s")/eg;
   }
   elsif ( $minutes || $hours ) {
      s/(?!m)([0-9]+(?:\.[0-9]*)?)s/&portage_utils::DHMS2Seconds(0,0,0,$1)/eg;
   }
   else {
      if (s/(?!m)([0-9]+(?:\.[0-9]*)?)s/&portage_utils::seconds2DHMS($1)/eg) {
         print STDERR "$_" if ($debug);
      }
   }

   print OUT;
}
