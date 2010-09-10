#!/usr/bin/perl 
# $Id$

# @file second-to-hms.pl
# @brief Convert from and to human readable time
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologiesm
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2009, Sa Majeste la Reine du Chef du Canada /
# Copyright 2009, Her Majesty in Right of Canada

use strict;
use warnings;

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
   exit 1;
}


use Getopt::Long;
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
my $verbose = 1;
my $debug = undef;
GetOptions(
   reverse     => \my $hmsToSeconds,
   minutes     => \my $minutes,
   hours       => \my $hours,

   help        => sub { usage },
   h           => sub { usage }, # disambiguate -h to mean -help, not -hours
   verbose     => sub { ++$verbose },
   quiet       => sub { $verbose = 0 },
   debug       => \$debug,
) or usage;

sub seconds2DHMS {
   print STDERR "$1\n" if ($debug);

   my @parts = gmtime($1);
   my $r = "";
   my $f = undef; # Use to skip printing zeros.
   if ($parts[7] > 0) {
      $r .= sprintf("%dd", $parts[7]);
      $f = 1;
   }
   if ($f or $parts[2] > 0) {
      $r .= sprintf("%dh", $parts[2]);
      $f = 1;
   }
   if ($f or $parts[1] > 0) {
      $r .= sprintf("%dm", $parts[1]);
      $f = 1;
   }
   # Always print the seconds.
   $r .= sprintf("%ds", $parts[0]);

   return $r;
}

# Converts DHMS into seconds
# params 1: days
# params 2: hours
# params 3: minutes
# params 4: seconds
sub DHMS2Seconds($$$$) {
   my ($d, $h, $m, $s) = @_;
   my $r = 0;
   $r += $d * 86400 if (defined($d));
   $r += $h * 3600 if (defined($h));
   $r += $m * 60 if (defined($m));
   $r += $s if (defined($s));
   if ( $minutes ) {
      return sprintf("%.1f", ${r} / 60) . "m";
   } elsif ( $hours ) {
      return sprintf("%.1f", ${r} / 3600) . "h";
   } else {
      return "${r}s";
   }
}


#perl -ple 'BEGIN{sub pod {@parts = gmtime($1); return sprintf("%dd%dh%dm%ds",@parts[7,2,1,0]);}}; s/([0-9.]+)s/&pod($1)/e' < LOG.timing

my $in = shift || "-";
my $out = shift || "-";

0 == @ARGV or usage "Superfluous parameter(s): @ARGV";

open(IN, "<$in") or die "Can't open $in for reading: $!\n";
open(OUT, ">$out") or die "Can't open $out for writing: $!\n";


while (<IN>) {
   if ($hmsToSeconds) {
      s/(?:([0-9]+)d)?(?:([0-9]+)h)?(?:([0-9]+)m)?(?:([0-9]+(?:\.[0-9]*)?)s)/&DHMS2Seconds($1, $2, $3, $4)/eg;
   }
   elsif ( $minutes || $hours ) {
      s/(?!m)([0-9]+(?:\.[0-9]*)?)s/&DHMS2Seconds(0,0,0,$1)/eg;
   }
   else {
      if (s/(?!m)([0-9]+(?:\.[0-9]*)?)s/&seconds2DHMS($1)/eg) {
         print STDERR "$_" if ($debug);
      }
   }

   print OUT;
}
