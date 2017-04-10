#!/usr/bin/env perl

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
# Copyright 2004-2016, Sa Majeste la Reine du Chef du Canada /
# Copyright 2004-2016, Her Majesty in Right of Canada

use utf8;

use strict;
use warnings;


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

sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: $0 [-v] [-p] -ss|-noss [-notok] [-lang=l] [in [out]]

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

   "lang=s"   => \my $lang,
   v          => \my $v,
   p          => \my $p,
   ss         => \my $ss,
   noss       => \my $noss,
   notok      => \my $notok,
   pretok     => \my $pretok,
   paraline   => \my $paraline,
   xtags      => \my $xtags,
) or usage "Error: Invalid option(s).";

$lang = "en" unless defined $lang;
$v = 0 unless defined $v;
$p = 0 unless defined $p;
$ss = 0 unless defined $ss;
$noss = 0 unless defined $noss;
$notok = 0 unless defined $notok;
$pretok = 0 unless defined $pretok;
$paraline = 0 unless defined $paraline;
$xtags = 0 unless defined $xtags;
 
my $in  = shift || "-";
my $out = shift || "-";

0 == @ARGV or usage "Error: Superfluous argument(s): @ARGV";

tokenize_file($in, $out, $lang, $v, $p, $ss, $noss, $notok,
              $pretok, $paraline, $xtags) == 0
   or die "Error: utokenize.pl encountered a fatal error\n";
