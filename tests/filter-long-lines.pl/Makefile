#!/usr/bin/make -f
# vim:noet:ts=3

# Makefile - Unit-test for filter-long-lines.pl.
#
# PROGRAMMER: Darlene Stewart
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2010, Sa Majeste la Reine du Chef du Canada /
# Copyright 2010, Her Majesty in Right of Canada

FILTER_LONG_LINES = filter-long-lines.pl -d

.SECONDARY:

all: test

clean:
	${RM} f*.tok.filt10 log

########################################
# Compare a run to a reference
test: f1.tok f2.tok f3.tok
	${FILTER_LONG_LINES} -l=10 $+ 2> log
	diff -q $(word 1, $+).filt10 ref/$(word 1, $+).filt10
	diff -q $(word 2, $+).filt10 ref/$(word 2, $+).filt10
	diff -q $(word 3, $+).filt10 ref/$(word 3, $+).filt10
