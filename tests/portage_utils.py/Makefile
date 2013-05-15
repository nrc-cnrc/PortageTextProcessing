#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make

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


TEMP_FILES=test* unittest*
include ../Makefile.incl

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
testsuite: unittest8
testsuite: unittest9


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
	[[ `file --mime $<` =~ "text/plain" ]] || ! echo "File is not plain text." >&2
	diff $+ -q
unittest5.txt: test
	cat $< \
	| python -c "exec('from portage_utils import open\nf=open(\"$@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"


# Test writing to a compress gz file
unittest6: unittest6.gz test
	[[ `file $<` =~ "gzip compressed data" ]] || ! echo "File is not of gzip format." &>2
	zcmp $+
unittest6.gz: test
	cat $< \
	| python -c "exec('from portage_utils import open\nf=open(\"$@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"


# Test writing to a compress gz file
unittest7: unittest7.gz test
	sleep 1 # Occasionally, the file is still empty by the time we get here
	[[ `file $<` =~ "gzip compressed data" ]] || ! echo "File is not of gzip format." &>2
	zcmp $+
unittest7.gz: test
	cat $< \
	| python -c "exec('from portage_utils import open\nf=open(\"| gzip > $@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"


# Test writing to no file which should produce an error message.
unittest8: test
	cat $< \
	| python -c "exec('from portage_utils import open\nf=open(\"\", \"w\")\nfor line in open(\"-\"): f.write(line)')" 2>&1 \
	| grep "Fatal error: You must provide a filename" --quiet


.PHONY: unittest9
unittest9:  unittest9a unittest9b

# Testing partially reading a gzip file and not getting a Broken pipe message.
unittest9a:  %:  ${PORTAGE}/test-suite/systems/toy-regress-en2fr/models/tm/cpt.merged.hmm3-kn3-zn.tm-train.en2fr.gz
	python -c "exec('from portage_utils import open\nfor line in open(\"$<\", \"r\", False):\n  if True: break\n')" 2>&1 | egrep '(zcat|gzip): stdout: Broken pipe'

unittest9b:  %:  ${PORTAGE}/test-suite/systems/toy-regress-en2fr/models/tm/cpt.merged.hmm3-kn3-zn.tm-train.en2fr.gz
	! { set -o pipefail; python -c "exec('from portage_utils import open\nfor line in open(\"$<\", \"r\", True):\n  if True: break\n')" 2>&1 | egrep '(zcat|gzip): stdout: Broken pipe'; }

