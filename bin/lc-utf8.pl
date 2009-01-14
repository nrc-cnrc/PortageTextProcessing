#!/usr/bin/perl -s

# @file lc-utf8.pl 
# @brief Lowercase mapping for utf-8
# 
# @author Eric Joanis, based on lc-latin.pl by George Foster
# 
# COMMENTS: 
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2008, Sa Majeste la Reine du Chef du Canada /
# Copyright 2008, Her Majesty in Right of Canada

require 5.004;
use locale;
use POSIX qw(locale_h);
setlocale(LC_CTYPE, "fr_CA.utf8");
use open IO=>qq{:locale};

$HELP = "
lc-utf8.pl [in [out]]

Lowercase mapping for iso-utf8.  This should work regardless of how you have
your locale set up.  Relies on Perl - utf8_casemap can also be used instead, if
this script does not work on your system and you have ICU.

";

if ($help || $h) {
    print $HELP;
    exit 0;
}
 
$in = shift || "/dev/stdin";
$out = shift || "/dev/stdout";
 
if (!open(IN, "< :encoding(utf8)", $in)) {die "Can't open $in for reading";}
if (!open(OUT, "> :encoding(utf8)", $out)) {die "Can't open $out for writing";}

while (<IN>) {print OUT lc;}
