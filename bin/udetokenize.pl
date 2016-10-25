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
setDetokenizationLang($lang);

my $in  = shift || "-";
my $out = shift || "-";

0 == @ARGV or usage "Error: Superfluous argument(s): @ARGV";



zopen(*IN,  "<$in")  or die "Error: Cannot open $in for reading";
zopen(*OUT, ">$out") or die "Error: Cannot open $out for writing";
binmode(IN,  ":encoding(UTF-8)");
binmode(OUT, ":encoding(UTF-8)");

my $first_sentence = 1;  # The first sentence will be part of a new paragraph in deparaline mode.
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

   if ($deparaline) {
      chomp($out_sentence);
      if ($first_sentence) {
         print OUT $out_sentence;
         $first_sentence = 0;
      }
      elsif ($out_sentence =~ m/^\s*$/) {
         print OUT "\n";
         # Next sentence will be the beginning of a new paragraph.
         $first_sentence = 1;
      }
      else {
         print OUT " ", $out_sentence;
         $first_sentence = 0;
      }
   }
   else {
      print OUT $out_sentence . "\n";
   }
}
print OUT "\n" unless $first_sentence;

