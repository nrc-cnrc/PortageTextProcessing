#!/usr/bin/perl -sw

# $Id$
#
# @file udetokenize.pl 
# @brief Transform tokenized English back to normal English text, with some
# support of French text too.  This version is intended to detokenize utf-8
# text from French<->English SMT, rather than from Chinese or Arabic -> English
# SMT.
#
# @author original detokenize.pl: SongQiang Fang and George Foster
#              UTF-8 adaptation and improved handling of French: Eric Joanis
#              Spanish handling by Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright (c) 2004 - 2009, Sa Majeste la Reine du Chef du Canada /
# Copyright (c) 2004 - 2009, Her Majesty in Right of Canada


use strict;
use utf8;

use ULexiTools;

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


# This is a utf8 handling script => io should be in utf8 format
# ref: http://search.cpan.org/~tty/kurila-1.7_0/lib/open.pm
use open IO => ':encoding(utf-8)';
use open ':std';  # <= indicates that STDIN and STDOUT are utf8

my $HELP = "
Usage: udetokenize.pl [-lang=L] [-latin1] [-chinesepunc] [-stripchinese]
       [INPUT] [OUTPUT]

Detokenize tokenized text encoded in utf-8.

Warning: ASCII quotes are handled assuming there is only one level of quotation.

Options:

-lang=L        Specify two-letter language code: en, es, or fr [en]
-latin1        Replace utf-8 characters that map to cp-1252 but not to
               iso-8859-1 by their closest utf-8 equivalents that do
-chinesepunc   Normalize Chinese punctuation to characters that map back to
               cp-1252, or to iso-8859-1 if -latin1 is also specified
-stripchinese  Strip any remaining Han characters after detokenizing

Notes:
 - to simulate the behaviour of newdetok.pl, use:
      udetokenize.pl -latin1 -chinesepunc -stripchinese
";

my $in=shift || "-";
my $out=shift || "-";

our ($help, $h, $lang, $latin1, $chinesepunc, $stripchinese);
$lang = "en" unless defined $lang;
setDetokenizationLang($lang);

if ($help || $h) {
   print $HELP;
   exit 0;
}


open(IN,  "<$in")  or die " Can not open $in for reading";
open(OUT, ">$out") or die " Can not open $out for writing";

while(<IN>)
{
   my $sentence = $_;
   chomp $sentence;

      if ( $chinesepunc ) {
         # Normalize Chinese brackets and punctuation
         # Note: this section is hard to read because of the encoding - to
         # inspect code point by code point, you can run:
         # iconv -f utf-8 -t ascii --unicode-subst '[[[U%x]]]' udetokenize.pl
      foreach ($sentence) {
            tr/〔〕【】『』〖〗︶︻︼/()[]“”[])[]/;
            tr/﹝﹞﹙﹚﹛﹜/()(){}/;
            tr/。、《》〈〉「」/.,«»‹›“”/;
            tr/﹃﹄〃﹁﹂/“””“”/;
            tr/‵′‶″〝〞‵/`´“”“”`/;
            tr/﹖﹗︰﹪﹡﹟〜/?!:%*#~/;
            tr/―﹣‾/—\-\-/;
            tr/･·・/•••/;
            tr/﹑﹒﹕､﹔﹐/, :,;,/;
            tr/※¿¡‖//d;
         }
         # Changed from Howard's script - we use the cp-1252 characters instead,
         # unless -latin1 is specified:
         #   tr/‵′″―《》〈〉「」『』〝〞﹁﹂﹃﹄〃‵/''"-"""""""""""""""'/g;
         # Not in Howard's script, but done here: tr/‶/“/g;

         # The following things from Howard's script are not done here, but
         # are done below if the -latin1 switch is specified.
         # Not done from Howard's script because we want to preserve right
         # French and English punctuation: tr/«»“”·‘’—–‰/"""" ''--%/g;
         # Also not done: s/[•･·]//g; # we use • (\xb7) for all three
         # Not done to preserve rich punctuation in F/E: $line =~ s/…/ ... /g;
      }

   my $out_sentence = detokenize($sentence);

   if ( $chinesepunc ) {
      foreach ($out_sentence) {
         s/‥/../g;
      }
   }

   if ( $latin1 ) {
      foreach ($out_sentence) {
         s/€/Euro/g;
         s/…/.../g;
         s/‥/../g;
         s/‰/%0/g;
         s/Œ/OE/g;
         s/—/--/g;
         s/™/TM/g;
         s/œ/oe/g;
         tr/‚ƒ„†‡ˆŠ‹Ž/,f"**^S<Z/;
         tr/‘’“”•–˜š›žŸ/''""·\-~s>zY/;
      }
   }

   if ( $stripchinese || $chinesepunc ) {
      $out_sentence =~ s/\p{Han}//g if $stripchinese;
      $out_sentence =~ s/[\pZ\pC]+/ /g;
   }

   print OUT $out_sentence . "\n";
}

