#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make
# $Id$

# @file Makefile
# @brief Testsuite for testing portage_utils.pyc and its open.
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, Her Majesty in Right of Canada



-include Makefile.params

SHELL := bash

.PHONY: all
all: testsuite


.PHONY: clean
clean:
	${RM} test* unittest*

test:
	echo -e "This is a test.\nThen there is a second line.\nBut it ends on the third line." > $@

test.gz: test
	cat $< | gzip > $@

.PHONY: testsuite
testsuite: unittest0
testsuite: unittest1
testsuite: unittest2
testsuite: unittest3
testsuite: unittest4
testsuite: unittest5
testsuite: unittest6
testsuite: unittest7


# Test reading standard in.
unittest0: test
	cat $< \
	| python -c "exec('from portage_utils import open\nfor line in open(\"-\"): print line,')" \
	| diff - $<


# Test reading a plain text file.
unittest1: test
	echo -e 'from portage_utils import open\nfor line in open("$<"): print line,' \
	| python \
	| diff - $<


# Test reading a compressed gz file.
unittest2: test.gz
	echo -e 'from portage_utils import open\nfor line in open("$<"): print line,' \
	| python \
	| diff - $(basename $<)


# Test reading from a piped command.
unittest3: test.gz
	echo -e 'from portage_utils import open\nfor line in open("zcat $< |"): print line,' \
	| python \
	| diff - $(basename $<)



# Test writing to standard out.
unittest4: test
	cat $< \
	| python -c "exec('from portage_utils import open\nf=open(\"-\", \"w\")\nfor line in open(\"-\"): f.write(line)')" \
	| diff - $<


# Test writing to a plain text file.
unittest5: unittest5.txt test
	diff $+ -q
unittest5.txt: test
	cat $< \
	| python -c "exec('from portage_utils import open\nf=open(\"$@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"


# Test writing to a compress gz file
unittest6: unittest6.gz test.gz
	zcmp $+
unittest6.gz: test
	cat $< \
	| python -c "exec('from portage_utils import open\nf=open(\"$@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"


# Test writing to a compress gz file
unittest7: unittest7.gz test
	zcmp $+
unittest7.gz: test
	cat $< \
	| python -c "exec('from portage_utils import open\nf=open(\"| gzip > $@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"

