#!/usr/bin/env perl

# @file normalize-unicode.pl 
# @brief Normalize unicode input into canonical representations.
#
# Particularly useful in Arabic where the same text can be encoded in many
# ways, which are string-wise different, but canonically equivalent.
#
# @author Eric Joanis
#
# COMMENTS:
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2006, Sa Majeste la Reine du Chef du Canada /
# Copyright 2006, Her Majesty in Right of Canada

use strict;
use warnings;

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
printCopyright("normalize-unicode.pl", 2006);
$ENV{PORTAGE_INTERNAL_CALL} = 1;

sub usage {
    local $, = "\n";
    print STDERR @_, "";
    $0 =~ s#.*/##;
    print STDERR "
Usage: $0 [-v] UNICODEDATA UTF8InputText(s) > CanonicalUTF8Output

  Normalize the UTF8InputText to its canonical representation, as described in
  UNICODEDATA.  UNICODEDATA should be the official UnicodeData.txt file as
  found on the Unicode home page: http://www.unicode.org/Public/UNIDATA/
  UnicodeData.txt, or a subset thereof.  All non-canonical characters found in
  the input are converted into their canonical equivalent.

  The program will look for UNICODEDATA first in the local directory, then in
  \$PORTAGE/models/unicode.  Provided subsets: UnicodeData-Arabic.txt, (alias:
  ar), and UnicodeData-Arabic-full.txt, (alias: ar-full).  (Refer to
  \$PORTAGE/models/unicode/README for details.)

Options:

  -v(erbose):   output the list of non-canonical characters found.
  -d(ebug):     print debugging information
  -h(elp):      print this help message

";
    exit 1;
}

use Getopt::Long;
# Note to programmer: Getopt::Long automatically accepts unambiguous
# abbreviations for all options.
GetOptions(
    help        => sub { usage },
    verbose     => \my $verbose,
    debug       => \my $debug,
) or usage;

@ARGV > 0 or usage "Missing UnicodeData.txt file name";
my $unicode_data = shift || "-";

if ( $unicode_data eq "ar"  ) { $unicode_data = "UnicodeData-Arabic.txt" }
if ( $unicode_data eq "ar-full" ) { $unicode_data = "UnicodeData-Arabic-full.txt" }

if ( ! -e $unicode_data ) {
   if ( ! exists $ENV{PORTAGE} ) {
      die "Can't find $unicode_data file in local directory, and \$PORTAGE " .
          "is not \ndefined, so there is nowhere else to look.\n"
   } elsif ( -e "$ENV{PORTAGE}/models/unicode/$unicode_data" ) {
      $unicode_data = "$ENV{PORTAGE}/models/unicode/$unicode_data";
   } else {
      die "Can't find $unicode_data file in either local directory or in\n" .
          "\$PORTAGE/models/unicode directory.\n";
   }
}

# hex2utf8($hex_char) returns the UTF-8 character number UCS $hex_char
sub hex2utf8 ($) {
   use encoding 'utf-8';
   return chr(hex($_[0]));
}

# utf82hex($utf8_char) returns the UCS hex representation of $utf8_char
sub utf82hex ($) {
   use encoding 'utf-8';
   return sprintf "%04X", ord($_[0]);
}

open UNICODEDATA, $unicode_data or die "Can't open $unicode_data: $!\n";
my %canonical;
while (<UNICODEDATA>) {
   my @tokens = split ';', $_, 7;
   my $hex_char = $tokens[0];
   my $equivalence = $tokens[5];
   next unless $equivalence;
   my $utf8_char = hex2utf8($hex_char);
   my @equiv_chars = map {
      #/^[0-9a-f]{4}$/i and print "$_ -> ", hex2utf8($_), "\n";
      /^[0-9a-f]{4}$/i ? (hex2utf8 $_) : ();
   } split ' ', $equivalence;
   my $equiv_string = join "", @equiv_chars;
   utf8::upgrade($equiv_string);
   $canonical{$utf8_char} = $equiv_string;
   $debug and print "$hex_char = $utf8_char -> $equivalence = $equiv_string\n";
}

my $non_canonical_chars = join "", keys %canonical;
$debug and print "NON canonical chars = $non_canonical_chars\n";
my $non_canonical_RE = qr/[\Q$non_canonical_chars\E]/;

my %normalize_freq;
# normalize_char($utf8_char) returns a string containing the canonical
# representation of $utf8_char
sub normalize_char($) {
   my $char = shift;
   if ( exists $canonical{$char} ) {
      $normalize_freq{$char}++;
      return $canonical{$char};
   } else {
      return $char;
   }
}

foreach (sort keys %canonical) {
   while ( $canonical{$_} =~ s/($non_canonical_RE)/normalize_char($1)/eg ) {
      $debug and 
         print "Recursive defn required for ", utf82hex($_),
               " = $_ -> $canonical{$_}\n";
   }
}
      
#while ( my ($char, $equiv) = each %canonical ) {
#   while ( $equiv =~ s/($non_canonical_RE)/normalize_char($1)/eg ) {
#      $debug and 
#         print "Recursive defn required for ", utf82hex($char),
#               " = $char -> $equiv = $canonical{$char}\n";
#      };
#      $canonical{$char} = $equiv;
#   }
#}

%normalize_freq = ();
while (<>) {
   utf8::upgrade($_);
   $debug and print;
   s/($non_canonical_RE)/normalize_char($1)/eg;
   print;
}

if ( $verbose ) {
   foreach (sort keys %normalize_freq) {
      print STDERR utf82hex($_), " converted $normalize_freq{$_} times\n";
      $debug and print utf82hex($_),
         " = $_ converted $normalize_freq{$_} times to $canonical{$_}\n";
   }
}
