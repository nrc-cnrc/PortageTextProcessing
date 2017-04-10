#!/usr/bin/env perl

# @file udetokenize.pl 
# @brief Transform tokenized UTF-8 text in normal text.
#
# We now support English, French, Spanish and Danish text tokenized with
# utokenize.pl.
#
# @author original detokenize.pl: SongQiang Fang and George Foster
#              UTF-8 adaptation and improved handling of French: Eric Joanis
#              Spanish handling by Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2004 - 2016, Sa Majeste la Reine du Chef du Canada /
# Copyright 2004 - 2016, Her Majesty in Right of Canada


use strict;
use warnings;
use utf8;

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
printCopyright("udetokenize.pl", 2004);
$ENV{PORTAGE_INTERNAL_CALL} = 1;


use ULexiTools;

sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: $0 [-lang=L] [-latin1] [-chinesepunc] [-stripchinese]
       [INPUT [OUTPUT]]

Detokenize tokenized text encoded in utf-8.

Warning: ASCII quotes are handled assuming there is only one level of quotation.

Options:

-lang=L        Specify two-letter language code: en, es, fr, or da [en]
-latin1        Replace utf-8 characters that map to cp-1252 but not to
               iso-8859-1 by their closest utf-8 equivalents that do
-chinesepunc   Normalize Chinese punctuation to characters that map back to
               cp-1252, or to iso-8859-1 if -latin1 is also specified
-stripchinese  Strip any remaining Han characters after detokenizing
-deparaline    Reconstruct one paragraph per line.

Notes:
 - to simulate the behaviour of newdetok.pl, use:
      udetokenize.pl -latin1 -chinesepunc -stripchinese
";
   exit @_ ? 1 : 0;
}

use Getopt::Long;
Getopt::Long::Configure("no_ignore_case");
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
my $verbose = 1;
GetOptions(
   help        => sub { usage },
   h           => sub { usage },

   "lang=s"       => \my $lang,
   latin1         => \my $latin1,
   chinesepunc    => \my $chinesepunc,
   stripchinese   => \my $stripchinese,
   deparaline     => \my $deparaline,
) or usage "Error: Invalid option(s).";

$lang = "en" unless defined $lang;
$latin1 = 0 unless defined $latin1;
$chinesepunc = 0 unless defined $chinesepunc;
$stripchinese = 0 unless defined $stripchinese;
$deparaline = 0 unless defined $deparaline;

my $in  = shift || "-";
my $out = shift || "-";

0 == @ARGV or usage "Error: Superfluous argument(s): @ARGV";

detokenize_file($in, $out, $lang, $latin1, $chinesepunc,
                $stripchinese, $deparaline) == 0
   or die "Error: udetokenize.pl encountered a fatal error\n";
