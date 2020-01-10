#!/usr/bin/env perl

# @file normalize-iu.pl 
# @brief Apply the character normalizations recommended by Inuktut Tusaalanga on Inuktut text
#
# @author Eric Joanis
#
# Traitement multilingue de textes / Multilingual Text Processing
# Centre de recherche en technologies numériques / Digital Technologies Research Centre
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2020, Sa Majeste la Reine du Chef du Canada /
# Copyright 2020, Her Majesty in Right of Canada

use strict;
use warnings;
use utf8;

sub usage {
   local $, = "\n";
   print STDERR @_, "";
   $0 =~ s#.*/##;
   print STDERR "
Usage: $0 [IN [OUT]]

  Systematically apply the character normalizations on Inuktut syllabics text
  implied by the spelling recommendations of Inuktut Tusaalanga (by Pirurvik),
  https://tusaalanga.ca/node/2506 Quirky Characters section at the bottom:
   - Rule 1: ᕿ = q(V) should be one character
   - Rule 2: ᖏ = ng(V) should be one character
   - Rule 3: ᙱ = nng(V) should be one character
   - Rule 4: doubled ᕿ = q(V) should be ᖅᑭ = qk(V)
   - Rule 5: consistently use the syllabic ᕼ in Inuktut words, not the ASCII H
";

#Options:
#
#  -h(elp)       print this help message
#  -v(erbose)    increment the verbosity level by 1 (may be repeated)
#  -d(ebug)      print debugging information
#";
   exit @_ ? 1 : 0;
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
) or usage "Error: Invalid option(s).";

my $in = shift || "-";
my $out = shift || "-";
0 == @ARGV or usage "Error: Superfluous argument(s): @ARGV";

open(IN, "<$in") or die "Error: Can't open $in for reading: $!\n";
open(OUT, ">$out") or die "Error: Can't open $out for writing: $!\n";

binmode(IN,  ":encoding(UTF-8)");
binmode(OUT, ":encoding(UTF-8)");

my $counter=0;
while (<IN>) {
   # Rule 1: ᕿ = q(V) should be one character
   # r + k(V) -> q(V)
   s/ᕐᑭ/ᕿ/g and ++$counter;
   s/ᕐᑯ/ᖁ/g and ++$counter;
   s/ᕐᑲ/ᖃ/g and ++$counter;
   s/ᕐᒃ/ᖅ/g and ++$counter;

   # Rule 2: ᖏ = ng(V) should be one character
   # n + g(V) -> ng(V)
   s/ᓐᒋ/ᖏ/g and ++$counter;
   s/ᓐᒍ/ᖑ/g and ++$counter;
   s/ᓐᒐ/ᖓ/g and ++$counter;
   s/ᓐᒡ/ᖕ/g and ++$counter;
   # ng + g(V) -> ng(V)
   s/ᖕᒋ/ᖏ/g and ++$counter;
   s/ᖕᒍ/ᖑ/g and ++$counter;
   s/ᖕᒐ/ᖓ/g and ++$counter;
   s/ᖕᒡ/ᖕ/g and ++$counter;

   # Rule 3: ᙱ = nng(V) should be one character
   # n + ng(V) -> nng(V)
   s/ᓐᖏ/ᙱ/g and ++$counter;
   s/ᓐᖑ/ᙳ/g and ++$counter;
   s/ᓐᖓ/ᙵ/g and ++$counter;
   s/ᓐᖕ/ᖖ/g and ++$counter;
   # ng + ng(V) -> nng(V)
   s/ᖕᖏ/ᙱ/g and ++$counter;
   s/ᖕᖑ/ᙳ/g and ++$counter;
   s/ᖕᖓ/ᙵ/g and ++$counter;
   s/ᖕᖕ/ᖖ/g and ++$counter;
   # nng + g(V) -> nng(V)
   s/ᖖᒋ/ᙱ/g and ++$counter;
   s/ᖖᒍ/ᙳ/g and ++$counter;
   s/ᖖᒐ/ᙵ/g and ++$counter;
   s/ᖖᒡ/ᖖ/g and ++$counter;
   # Note: the rules above are carefully ordered so that n+n+g(V), n+ng+g(V),
   # ng+n+g(V) and ng+ng+g(V) also all correctly get mapped to nng(V).

   # Rule 4: doubled ᕿ = q(V) should be ᖅᑭ = qk(V)
   # doubled q = q + q(V) -> qk(V)
   s/ᖅᕿ/ᖅᑭ/g and ++$counter;
   s/ᖅᖁ/ᖅᑯ/g and ++$counter;
   s/ᖅᖃ/ᖅᑲ/g and ++$counter;
   s/ᖅᖅ/ᖅᒃ/g and ++$counter;

   # Rule 5: consistently use the syllabic ᕼ in Inuktut words, not the ASCII H
   # ASCII H followed by syllabics character -> syllabic ᕼ
   s/H(?=[\x{1400}-\x{167f}])/ᕼ/g and ++$counter;

   print OUT;
}

$verbose and print STDERR "Substitutions applied: $counter\n";

close(IN);
close(OUT);
