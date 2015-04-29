#!/usr/bin/env perl

# @file map-chinese-punct.pl 
# @brief Map Chinese punctuation characters to western equivalents.
#
# @author Eric Joanis
#
# This code is extracted from udetokenize.pl, which was itself based on an
# older script by Howard Johnson. And then modified to fit slightly different
# purposes.
#
# Traitement multilingue de textes / Multilingual Text Processing
# Tech. de l'information et des communications / Information and Communications Tech.
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2015, Sa Majeste la Reine du Chef du Canada /
# Copyright 2015, Her Majesty in Right of Canada

use strict;
use warnings;
use utf8; # to allow for litteral UTF-8 characters in this script itself

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
printCopyright 2015;
$ENV{PORTAGE_INTERNAL_CALL} = 1;


sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: $0 [options] [IN [OUT]]

  Normalize all the wide punctuation marks from the Chinese utf8 character
  space in into utf8 characters that also exist in occidental character sets.

Options:

  -cp1252   Map chinese punctuations to the closest utf8 character that exists
            in the cp1252 character set, including the so-called smart quotes.
            [default]
  -latin1   Map chinese punctuations to the closest utf8 character that exists
            in the iso-latin1 character set.
  -ascii    Go down to the simplest punctuation set
  -h(elp)   print this help message
";
   exit 1;
}

use Getopt::Long;
Getopt::Long::Configure("no_ignore_case");
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
my $verbose = 1;
GetOptions(
   help        => sub { usage },
   verbose     => sub { ++$verbose },
   quiet       => sub { $verbose = 0 },
   debug       => \my $debug,
   "latin1"    => \my $latin1,
   ascii       => \my $ascii,
   "cp1252"    => \my $cp1252,
) or usage;

if ($ascii) { $latin1 = 1; } # allows cascaded processing

my $in = shift || "-";
my $out = shift || "-";

0 == @ARGV or usage "Superfluous parameter(s): @ARGV";

zopen(*IN, "<$in") or die "Can't open $in for reading: $!\n";
zopen(*OUT, ">$out") or die "Can't open $out for writing: $!\n";
binmode(IN,  ":encoding(UTF-8)");
binmode(OUT, ":encoding(UTF-8)");

while (<IN>) {
   tr/〔〕【】〖〗︶︻︼/()[][])[]/;
   tr/﹝﹞﹙﹚﹛﹜/()(){}/;
   tr/﹃﹄〃﹁﹂『』/“””“”“”/;
   tr/。、《》〈〉「」/.,“”‘’“”/;
   tr/‵′‶″〝〞/`´“”“”/;
   tr/﹖﹗︰：﹪﹡﹟〜/?!::%*#~/;
   tr/―﹣‾/—\-\-/;
   tr/･·・/•••/;
   tr/，﹑﹒﹕､﹔﹐/,,.:,;,/;
   tr/※¿¡‖//d;

   if ($latin1) {
      tr/“”‘’‹›•/""''''·/;
      s/—/--/g;
   }
   
   if ($ascii) {
      tr/«»´„‚·/""'"'./;
   }

   print OUT;
}

close(IN);
close(OUT);
