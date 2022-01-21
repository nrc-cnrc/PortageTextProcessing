#!/usr/bin/make -f
# vim:noet:ts=3

# Makefile - Unit-test for clean-utf8-text.pl & clean_utf8.py
#
# PROGRAMMER: Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2021, Sa Majeste la Reine du Chef du Canada /
# Copyright 2021, Her Majesty in Right of Canada

.SECONDARY:

all: test

TEMP_FILES=
include ../Makefile.incl

########################################
# Compare a run to a reference
test: test_perl test_python_stdin test_python_file

test_perl:
	diff <(clean-utf8-text.pl -wide-punct  < clean_utf8.txt) ref/clean_utf8.txt --brief

test_python_stdin:
	diff <(clean_utf8.py --phrase-table --wide-punct < clean_utf8.txt) ref/clean_utf8.txt --brief

test_python_file:
	diff <(clean_utf8.py --phrase-table --wide-punct clean_utf8.txt) ref/clean_utf8.txt --brief
