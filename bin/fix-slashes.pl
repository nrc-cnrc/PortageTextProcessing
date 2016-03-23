#!/usr/bin/env perl
#
# @file fix-slashes.pl
# @brief Heuristically add whitespace around slashes ('/') seperating words.
#
# @author Darlene Stewart
#
# COMMENTS:
#
# Traitement multilingue de textes / Multilingual Text Processing
# Tech. de l'information et des communications / Information and Communications Tech.
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2010-2014, Conseil national de recherches du Canada /
# Copyright 2010-2014, National Research Council of Canada


use warnings;

if (@ARGV && $ARGV[0] eq "-h") {
   print STDERR "
Usage: $0 < IN > OUT

   Add whitespace around slashes ('/') separating words of at least three characters.
   Skip anything that looks like a url.
   We make it at least three characters in an attempt to avoid breaking up
   specifications of units (e.g. km/hr).
";
   exit;
}

my $word = "(?:(?:[[:alpha:]][[:alpha:]\-]{2,})|(?:[[:alpha:]][[:alpha:]\-]*'[[:alpha:]]+))";

binmode( STDIN,  ":encoding(UTF-8)" );
binmode( STDOUT, ":encoding(UTF-8)" );

while (my $line = <STDIN>) {
    chop $line;
    while ($line =~ m/(?:^|[ ("'])(?!www\.)(${word}\)?(((\/ *)|( \/))\(?${word})+)(?:[ ).?;,:"']|$)/g) {
       my ($pre, $match, $post) = ($`, $&, $');
       $match =~ s/ *\/ */ \/ /g;
       $line = $pre . $match . $post;
    }
    $line =~ s/CAN \/ /CAN\//g;  # Patch CAN document #s, e.g. CAN/CSA B44-2000
    print $line, "\n";
}

