#!/usr/bin/perl -sw

# $Id$
#
# udetokenize.pl - Transform tokenized English back to normal English text,
#                  with some support of French text too.  This version is
#                  intended to detokenize utf-8 text from French<->English SMT,
#                  rather than from Chinese or Arabic -> English SMT.
#
# Programmers: original detokenize.pl: SongQiang Fang and George Foster
#              UTF-8 adaptation and improved handling of French: Eric Joanis
#
# Technologies langagieres interactives / Interactive Language Technologies
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright (c) 2004 - 2008, Sa Majeste la Reine du Chef du Canada /
# Copyright (c) 2004 - 2008, Her Majesty in Right of Canada


use strict;
use utf8;

my $HELP = "
Usage: udetokenize.pl [-lang=l] [-latin1] [-chinese-punch]
       [input file] [output file]

Detokenize tokenized text encoded in utf-8.

Warning: ASCII quotes are handled assuming there is only one level of quotation.

Options:

-lang          Specify two-letter language code: en or fr [en]
               Works well for English, not bad for French.
-latin1        Replace characters that map to cp-1252 but not to iso-8859-1 by
               their closest equivalents that do
-chinesepunc   Normalize Chinese punctuation to characters that map back to
               cp-1252, or to iso-8859-1 if -latin1 is also specified
-stripchinese  Strip any remaining Han characters after detokenizing

Notes:
 - to simulate the behaviour of newdetok.pl, use:
      udetokenize.pl -latin1 -chinesepunc -stripchinese
";

my $in=shift || "-";
my $out=shift || "-";
$in = "/dev/stdin" if $in eq "-";
$out = "/dev/stdout" if $out eq "-";

our ($help, $h, $lang, $latin1, $chinesepunc, $stripchinese);
$lang = "en" unless defined $lang;
if ($help || $h) {
   print $HELP;
   exit 0;
}

my $apos = qr/['´’]/;

open IN, "< :utf8", $in or die " Can not open $in for reading";
open OUT,"> :utf8", $out or die " Can not open $out for writing";
my $space=" ";
my ($word_pre, $word_before, $word_after);
my @double_quote=();
my @single_quote=();
my @out_sentence;
while(<IN>)
{
   chomp $_;
   my @tokens = split /[ ]+/;
   @out_sentence =();#initialize the containers
   @double_quote =();# assume  a pair of quotations only bound to one line of sentence.
   @single_quote =();# it's because in the machine output, quotation without paired is normal.
   # this assumption could be taken off if the text file was grammartically correct.
   while( defined (my $word_pre=shift @tokens) )
   {
      if ($word_pre eq "..") {$word_pre = "...";}

      if ( $chinesepunc ) {
         # Normalize Chinese brackets and punctuation
         # Note: this section is hard to read because of the encoding - to
         # inspect code point by code point, you can run:
         # iconv -f utf-8 -t ascii --unicode-subst '[[[U%x]]]' udetokenize.pl
         foreach ($word_pre) {
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
            s/‥/../g;
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

      if( $#out_sentence == -1 ){ # first word just push in
         push ( @out_sentence, $word_pre);
         if( is_quote( $word_pre )){
            check_quote( $word_pre);
         }
      } else {  # if it is not first word, considering the situations(punctuations, brackets, quotes, normal words)
         $word_before= $out_sentence[-1];
         if( is_punctuation($word_pre) ){ # don't add space before the word
            push ( @out_sentence, $word_pre);
         }
         elsif( is_quote( $word_pre) ){ # process quote according it is start or end
            process_quote($word_pre, $word_before);
         }
         elsif( is_bracket( $word_pre)){ # process bracket according it is start or end
            process_bracket($word_pre, $word_before);
         }
         elsif (is_poss($word_pre)) {
            process_poss( $word_pre, $word_before);
         }
         elsif (is_fr_hyph_ending($word_pre)) {
            push ( @out_sentence, $word_pre);
         }
         else{
            process_word( $word_pre, $word_before);
         }
      }

   }
   if ( $latin1 ) {
      foreach (@out_sentence) {
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
      my $out_string = join("", @out_sentence);
      $out_string =~ s/\p{Han}//g if $stripchinese;
      $out_string =~ s/[\pZ\pC]+/ /g;
      print OUT $out_string, "\n";
   } else {
      print OUT @out_sentence, "\n";
   }
   $#out_sentence=-1;
}

sub process_word
{
   my( $ch_pre, $ch_before)= @_;
   if( ($ch_pre eq "%") ){# take care of (%)
      push ( @out_sentence, $ch_pre);
   }
   elsif( is_punctuation($ch_before) || is_right_bracket($ch_before)){
      push ( @out_sentence, $space);
      push ( @out_sentence, $ch_pre);
   }
   elsif( is_left_bracket($ch_before)){
      push ( @out_sentence, $ch_pre);
   }
   elsif( is_quote($ch_before)){
      process_quote_before($ch_pre,$ch_before);
   }
   elsif (is_prefix($ch_before)) {
      push ( @out_sentence, $ch_pre);
   }
   else{
      push ( @out_sentence, $space);
      push ( @out_sentence, $ch_pre);
   }
}

sub process_bracket #ch1, ch2
{

   my $ch_pre=shift;
   my $ch_before=shift;
   if( is_right_bracket($ch_pre)){
      push ( @out_sentence, $ch_pre);
   }
   else{
#     if( is_punctuation($ch_before)){
#        push ( @out_sentence, $ch_pre);
#     }
      if( is_quote($ch_before)){
         process_quote_before($ch_pre,$ch_before);
      }
      else{
         push ( @out_sentence, $space);
         push ( @out_sentence, $ch_pre);
      }
   }
}

sub process_quote_before # ch1
{
   my $ch_pre= shift;
   my $ch_before= shift;
   if ( is_double_quote($ch_before)){
      if(&double_quote_not_empty){
         push ( @out_sentence, $ch_pre);
      }
      else{
         push ( @out_sentence, $space);
         push ( @out_sentence, $ch_pre);
      }
   }
   elsif ( is_single_quote($ch_before)){
      if(&single_quote_not_empty){
         push ( @out_sentence, $ch_pre);
      }
      else{
         push ( @out_sentence, $space);
         push ( @out_sentence, $ch_pre);
      }
   }
}

sub process_quote #ch1 ,ch2
{
   my $ch_pre=shift;
   my $ch_before=shift;
   if ( is_double_quote($ch_pre)){# in end place, just push in
      if( &double_quote_not_empty ){
         push ( @out_sentence, $ch_pre);
         pop @double_quote;
      }
      else{# in start place, push a space first (changed on Dec 13 2004)
         push (@double_quote, $ch_pre);
         push ( @out_sentence, $space);
         push ( @out_sentence, $ch_pre);
      }
#     else{# in start place, push a space first if the word before it is not special ch(punctuation,bracket)
#
#        push (@double_quote, $ch_pre);
#        if( is_special( $ch_before)){
#           push ( @out_sentence, $ch_pre);
#        }
#        else{
#           push ( @out_sentence, $space);
#           push ( @out_sentence, $ch_pre);
#        }
#     }
   }
   elsif( is_single_quote($ch_pre)){
      if( $ch_before=~/s$/){# in the situations like ( someones ' something). It is not true always, but mostly.
         push ( @out_sentence, $ch_pre);
      }
      else{
         if( &single_quote_not_empty){
            push ( @out_sentence, $ch_pre);
            pop @single_quote;
         }
         else{# in start place, push a space first (changed on Dec 13 2004)
            push (@single_quote, $ch_pre);
            push ( @out_sentence, $space);
            push ( @out_sentence, $ch_pre);
         }
#        else{
#           push (@single_quote, $ch_pre);
#           if( is_special( $ch_before)){
#              push ( @out_sentence, $ch_pre);
#           }
#           else{
#              push ( @out_sentence, $space);
#              push ( @out_sentence, $ch_pre);
#           }
#        }
      }
   }
}
sub check_quote #$ch
{
   my $ch_pre=shift;
   if ( is_double_quote( $ch_pre )){
      if( &double_quote_not_empty){
         pop @double_quote;
      }
      else{
         push (@double_quote, $ch_pre);
      }
   }
   elsif( is_single_quote($ch_pre)){
      if( &single_quote_not_empty ){
         pop @single_quote;
      }
      else{
         push (@single_quote, $ch_pre);
      }
   }
}
sub is_quote # ch
{
   my $ch_pre=shift;
   return is_double_quote($ch_pre) || is_single_quote($ch_pre);
}
sub is_double_quote # $ch
{
   my $ch_pre=shift;
   # « and » (French angled double quotes) left out intentionally, since
   # they are not glued to the text in French.
   # “ and ” (English angled double quotes) also left out: we
   # treat them as brackets instead, since they are left/right specific
   return ((defined $ch_pre)&&($ch_pre eq "\""));
}

sub is_single_quote # $ch
{
   my $ch_pre=shift;
   # `, ´, ‘ and ’ (back and forward tick, English angled single quotes) left
   # out: we treat them as brackets instead, since they are left/right specific
   return ((defined $ch_pre)&&($ch_pre eq "'"));
}
sub double_quote_not_empty
{
   return ( $#double_quote>= 0);
}

sub single_quote_not_empty
{
   return ( $#single_quote>= 0);
}
sub is_special # $var1
{
   my $ch=shift;
   return (is_bracket($ch) || is_punctuation($ch) );
}
sub is_punctuation # $var1
{
   my $ch_pre=shift;
   return ( $lang eq "fr" ? ($ch_pre =~ m/^(?:[,.!?;…]|\.\.\.)$/)
                          : ($ch_pre =~ m/^[,.:!?;]$/));
}
sub is_bracket # $ch
{
   my $ch_pre=shift;
   return ( is_left_bracket($ch_pre) || is_right_bracket($ch_pre) );
}
sub is_left_bracket # $ch
{
   my $ch=shift;
   # Includes left double and single quotes, since they require the same
   # treatment as brackets
   # Excludes < and ‹ since we don't split them in utokenize.pl
   return ( $ch =~ m/^[[({“‘`]$/);
}
sub is_right_bracket #ch
{
   my $ch=shift;
   # Includes right double and single quotes, since they require the same
   # treatment as brackets
   # Excludes > and › since we don't split them in utokenize.pl
   return ( $ch =~ m/^[])}”’´]$/);
}

sub is_prefix # ch
{
   my $ch=shift;
   return ($lang eq "fr" &&
           $ch =~ /^[cdjlmnst]$apos|[a-z]*qu$apos/oi);
}

# handling plural possessive in English
sub process_poss # ch1, ch2
{
   my $ch_pre=shift;
   my $ch_before=shift;
   if (is_poss($ch_pre)) {
      if ($ch_before =~ /^${apos}s/oi) {
         push ( @out_sentence, substr($ch_pre, 0, 1));
      }
      else {
         push ( @out_sentence, $ch_pre );
      }
   }
}

sub is_poss # ch
{
   my $ch=shift;
   return ($lang eq "en" &&
           $ch =~ /^${apos}s/oi);
}

sub is_fr_hyph_ending #ch
{
   my $ch=shift;
   return ($lang eq "fr" &&
           $ch =~ /^-(?:t-)?(?:je|tu|ils?|elles?|on|nous|vous|moi|toi|lui|eux|en|y|ci|ce|les?|leurs?|la|l[àÀ]|donc)/oi);
}

