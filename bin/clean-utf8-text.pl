#!/usr/bin/env perl

# @file clean-utf8-text.pl 
# @brief Clean up spaces, control characters, hyphen and such in utf8 corpora
#
# @author Eric Joanis
#
# Traitement multilingue de textes / Multilingual Text Processing
# Tech. de l'information et des communications / Information and Communications Tech.
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2015, Sa Majeste la Reine du Chef du Canada /
# Copyright 2015, Her Majesty in Right of Canada

use strict;
use warnings;
use utf8; # this script has some literal utf8 characters

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
Usage: $0 [options] < IN > OUT

  Clean up and normalize utf8 text:
   - Replace all control characters by spaces.
   - Normalize all types of spaces (different widths, non-breakable, etc) by
     the standard space character, and remove superfluous spaces.
   - Normalize all types of hyphens to the regular hyphen.
   - Replace ||| by ___|||___, to avoid ambiguity in phrase tables, unless
     -no-phrase-sep is specified.
   - Optionally replace basic wide punctuation characters by their ascii
     equivalent (but use map-chinese-punct.pl for much more complete Chinese
     punctuation mapping).

Options:

  -wide-punct     Map basic wide punctuation marks by their ascii equivalents,
                  adding spaces around them [leave wide punct alone]
  -no-phrase-sep  Don't replace ||| by ___|||___ [do]
  -h(elp)         Print this help message
  -v(erbose)      Increment the verbosity level by 1 (may be repeated)
  -d(ebug)        Print debugging information
";
   exit @_ ? 1 : 0;
}

use Getopt::Long;
Getopt::Long::Configure("no_ignore_case");
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
my $verbose = 1;
GetOptions(
   help            => sub { usage },
   verbose         => sub { ++$verbose },
   quiet           => sub { $verbose = 0 },
   debug           => \my $debug,
   "wide-punct"    => \my $wide_punct,
   "no-phrase-sep" => \my $no_phrase_sep,
) or usage "Error: Invalid option(s).";

0 == @ARGV or usage "Error: Superfluous argument(s): @ARGV";

binmode(STDIN,  ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");

while (<STDIN>) {
   chomp;

   # Convert various non-breaking hyphen encodings to -: \xAD and \x1E for MS
   # Word, \x2011 for Unicode.  Warning: for html documents, \xAD should be
   # stripped, rather than converted to -.
   s/[\x1E\xAD\x{2011}]/-/g;

   # Strip out the MS Word discretional hyphen, \x1F
   s/\x1F//g;

   # Replace various special purpose spaces by regular spaces:
   # U+2060: Word joiner / WJ, "a zero width non-breaking space (only) intended
   #         for disambiguation of functions for byte order mark" (Unicode standard);
   #         typically used to join separate words without displaying a space, but
   #         for Portage separate words do need a space.
   # U+FEFF: BOM, now called zero-width no-break space, used more-or-less like WJ
   #         (deprecated use) or left when concatenating files that have the BOM;
   #         in either case, we want to tokenize on it, so we turn it into a space.
   # U+A0:   The canonical non-break space
   # U+2007: Figure space, has the width of a digit
   # U+202F: Narrow no-break space (e.g., before : ; ! ? » and after « in French)
   # U+2028: Line Separator (LS)
   # U+2029: Paragraph Separator (PS)
   #         LS and PS ought to be turned into a newline, but in Portage we define
   #         \n as the newline, sometimes with user-defined semantics, and this
   #         script gets applied to line-aligned text, so the only legal thing we can
   #         do here is map them to spaces.
   s/[\x{2060}\x{FEFF}\x{00A0}\x{2007}\x{202F}\x{2028}\x{2029}]/ /g;

   # replace remaining control characters by spaces.
   s/[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]/ /g;

   # equivalent to crlf2lf.sh: convert DOS newlines to Linux ones
   s/\x0D$//;

   # If ||| appears stand-alone in text, that causes problems with Portage
   s/(^| )\|\|\|(?= |$)/ ___|||___/g unless $no_phrase_sep;

   # Basic wide punctuation mapping
   if ($wide_punct) {
      s/([，。：）（；？﹗．﹪﹡﹟])/ $1 /g;
      tr/，。：）（；？﹗．﹪﹡﹟/,.:)(;?!.%*\#/;
   }

   # Collapse multiple spaces to a single space
   s/\s+/ /g;

   # Remove leading whitespace
   s/^\s+//g;

   # Remove trailing whitespace
   s/\s+$//g;

   print $_, "\n";
}
