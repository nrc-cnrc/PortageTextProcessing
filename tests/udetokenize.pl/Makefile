#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make
# @file Makefile
# @brief Unittest for udetokenize.pl
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2013, Sa Majeste la Reine du Chef du Canada /
# Copyright 2013, Her Majesty in Right of Canada


-include Makefile.params

.DEFAULT_GOAL := all
.PHONY: all
all:  unittest


TEMP_FILES=paraline.*
include ../Makefile.incl


.PHONY:  unittest
unittest:  paraline

paraline:  paraline.detok  ref/paraline
	diff $+ --brief

paraline.tok:  src/paraline
	utokenize.pl -paraline -ss -p < $< > $@

paraline.detok:  paraline.tok
	udetokenize.pl -deparaline < $< > $@

