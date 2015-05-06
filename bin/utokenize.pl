#!/usr/bin/perl -sw

# @file utokenize.pl
# @brief Tokenize and sentence split UTF-8 text.
#
# @author George Foster, with minor modifications by Aaron Tikuisis,
#             UTF-8 adaptation by Michel Simard,
#             Spanish handling by Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2004-2013, Sa Majeste la Reine du Chef du Canada /
# Copyright 2004-2013, Her Majesty in Right of Canada

use utf8;

use strict;


BEGIN {
   # If this script is run from within src/ rather than being properly
   # installed, we need to add utils/ to the Perl library include path (@INC).
   if ( $0 !~ m#/bin/[^/]*$# ) {
      my $bin_path = $0;
      $bin_path =~ s#/[^/]*$##;
      unshift @INC, "$bin_path/../utils", $bin_path;
   }
}
use portage_utils;
printCopyright("utokenize.pl", 2004);
$ENV{PORTAGE_INTERNAL_CALL} = 1;

use ULexiTools;

my $HELP = "
Usage: utokenize.pl [-v] [-p] -ss|-noss [-notok] [-lang=l] [in [out]]

  Tokenize and sentence-split text in UTF-8.

Options:

-v         Write vertical output, with each token followed by its index
           relative to the start of its paragraph, <sent> markers after
           sentences, and <para> markers after each paragraph.
-p         Print an extra newline after each paragraph (has no effect if -v)
-ss        Perform sentence-splitting.
-noss      Don't perform sentence-splitting; input is treated as one-sentence
           per line.
           Note 1: one of -ss or -noss is required.
           Note 2: -p and -paraline cannot be combined with -noss (paragraphs
           are not defined with -noss).
-notok     Don't tokenize the output. [do tokenize]
-pretok    Already tokenized. Don't re-tokenize the input. [do tokenize]
-lang      Specify two-letter language code: en, fr, es, or da [en]
-paraline  File is in one-paragraph-per-line format [no]
-xtags     Handle XML tags from TMX and SDLXLIFF file formats [don't]

Caveat:

  With -ss, consecutive non-blank lines are considered as a paragraph: newlines
  within the paragraph are removed and sentence splitting is performed.  To
  increase sentence splitting accuracy, try to preserve existing paragraph
  boundaries in your text, separating them with a blank line (i.e., two
  newlines), or using -paraline if your input contains one paragraph per line.

  To preserve existing line breaks, e.g., if your input is already
  one-sentence-per-line, use -noss, otherwise your sentence breaks will be
  modified in ways that are almost certainly undesirable.

  Without -xtags, basic tag handling is still available: strings that match
  / <[^>]+>/ will be left untouched.  With -xtags, mid-token tags are also
  supported, and attempts are made to do tokenization as if the tags were not
  really there, while not actually stripping any tags out.

Newline and paragraph semantics:

  With -noss, a newline marks a sentence boundary and the output has exactly
  the same number of lines as the input.  There is no concept of paragraph.

  With -ss, a newline is just whitespace by default, and a sequence of one or
  more blank lines marks a paragraph boundary.  Empty lines at the beginning of
  the input are removed.

  With -ss and -paraline, a newline in the input marks a paragraph boundary.
  Each sentence is output on its own line.
   - Without -p, empty lines are deleted, so you just get a sequence of
     sentences without indication of the original paragraph structure.
   - With -p, empty input lines are kept, so that you can reconstruct the input
     paragraph structure from the output, including empty paragraphs: two
     consecutive newlines in the output mark a paragraph boundary from the
     input.

";

our ($help, $h, $lang, $v, $p, $ss, $noss, $paraline, $notok, $pretok, $xtags);

if ($help || $h) {
   print $HELP;
   exit 0;
}
$lang = "en" unless defined $lang;
setTokenizationLang($lang);

$v = 0 unless defined $v;
$p = 0 unless defined $p;
$ss = 0 unless defined $ss;
$noss = 0 unless defined $noss;
$notok = 0 unless defined $notok;
$pretok = 0 unless defined $pretok;
$paraline = 0 unless defined $paraline;
$xtags = 0 unless defined $xtags;
 
my $in = shift || "-";
my $out = shift || "-";

my $psep = $p ? "\n\n" : "\n";

zopen(*IN, "<$in") || die "Error: utokenize.pl: Can't open $in for reading";
zopen(*OUT, ">$out") || die "Error: utokenize.pl: Can't open $out for writing";
binmode IN, ":encoding(UTF-8)";
binmode OUT, ":encoding(UTF-8)";

if ( !$ss && !$noss ) {
   die "Error: utokenize.pl: One of -ss and -noss is now required; the old default (-ss) frequently caused unexpected behaviour, so we disabled it.\n";
}
if ( $notok && $pretok ) {
   die "Error: utokenize.pl: Specify only one of -notok or -pretok.\n";
}
if ( $ss && $noss ) {
   die "Error: utokenize.pl: Specify only one of -ss or -noss.\n";
}
if ( $noss && ($paraline || $p) ) {
   die "Error: utokenize.pl: -paraline and -p are meaningless with -noss.\n";
}
if ( $noss && $notok ) {
   warn "Warning: utokenize.pl: Just copying the input since -noss and -notok are both specified.\n";
}
if ( $noss && $pretok ) {
   warn "Warning: utokenize.pl: Just copying the input since -noss and -pretok are both specified.\n";
}

# Enable immediate flush when piping
select(OUT); $| = 1;

while (1)
{
   my $para;
   if ($noss || ($paraline && $p)) {
      unless (defined($para = <IN>)) {
         last;
      }
   } else {
      unless ($para = get_para(\*IN, $paraline)) {
         last;
      }
   }

   my @token_positions = tokenize($para, $pretok, $xtags);
   my @sent_positions = split_sentences($para, @token_positions) unless ($noss);

   if ($notok || $pretok) {
      if ($noss) {
         # A bit weird, but the user asked to neither split nor tokenize.
         print OUT $para;
      }
      else {
         # User asked for sentence splitting only, no tokenization.
         my $sentence_start = 0;
         for (my $i = 0; $i < $#sent_positions+1; ++$i) {
            # sent_position indicate the beginning of the next sentence, since
            # we want index to be the end of the sentence, we need the previous
            # tuple's index.
            my $index = $sent_positions[$i]-2;

            my $sentence_end = $token_positions[$index] + $token_positions[$index+1];
            my $sentence = get_sentence($para, $sentence_start, $sentence_end);
            $sentence =~ s/\s*\n\s*/ /g; # remove sentence-internal newlines
            print OUT $sentence;
            print OUT " $sentence_start,$sentence_end" if ($v);
            print OUT ($v ? "<sent>" : "");
            print OUT "\n" unless ($i == $#sent_positions);
            $sentence_start = $token_positions[$sent_positions[$i]];
         }
         print OUT ($v ?  "<para>\n" : $psep);
      }
   }
   else {
      for (my $i = 0; $i < $#token_positions; $i += 2) {
         if (!$noss && $i == $sent_positions[0]) {
            print OUT ($v ? "<sent>\n" : "\n");
            shift @sent_positions;
         }

         print OUT get_collapse_token($para, $i, @token_positions, $notok || $pretok), " ";

         if ($v) {
            print OUT "$token_positions[$i],$token_positions[$i+1]\n";
         }
         print OUT $psep if ($noss && $i < $#token_positions - 2 && substr($para, $token_positions[$i], $token_positions[$i+2] - $token_positions[$i]) =~ /\n/);
      }
      print OUT ($v ?  "<para>\n" : $psep);
   }
}

