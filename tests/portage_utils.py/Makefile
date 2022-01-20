#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make

# @file Makefile
# @brief Testsuite for testing portage_utils.py, primarily the open() method.
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
all: open_testsuite split_testsuite


TEMP_FILES=test* open_unittest*
include ../Makefile.incl

test:
	echo -e "This is a test àçéïôù.\nThen there is a second line.\nBut it ends on the third line." > $@

test.gz: test
	cat $< | gzip > $@

.PHONY: open_testsuite
open_testsuite: open_unittest0
open_testsuite: open_unittest1
open_testsuite: open_unittest2
open_testsuite: open_unittest3
open_testsuite: open_unittest4
open_testsuite: open_unittest5
open_testsuite: open_unittest6
open_testsuite: open_unittest7
open_testsuite: open_unittest8
open_testsuite: open_unittest9
open_testsuite: open_newlines_encodings

# Test reading standard in.
open_unittest0: test
	cat $< \
	| python3 -c "exec('from portage_utils import open\nfor line in open(\"-\"): print(line, end=\"\")')" \
	| diff - $<


# Test reading a plain text file.
open_unittest1: test
	echo -e 'from portage_utils import open\nfor line in open("$<"): print(line, end="")' \
	| python3 \
	| diff - $<


# Test reading a compressed gz file.
open_unittest2: test.gz
	echo -e 'from portage_utils import open\nfor line in open("$<", mode="rt"): print(line, end="")' \
	| python3 \
	| diff - $(basename $<)


# Test reading from a piped command.
open_unittest3: test.gz
	echo -e 'from portage_utils import open\nfor line in open("zcat $< |"): print(line, end="")' \
	| python3 \
	| diff - $(basename $<)


# Test writing to standard out.
open_unittest4: test
	cat $< \
	| python3 -c "exec('from portage_utils import open\nf=open(\"-\", \"w\")\nfor line in open(\"-\"): f.write(line)')" \
	| diff - $<


# Test writing to a plain text file.
open_unittest5: open_unittest5.txt test
	[[ `file --mime $<` =~ "text/plain" ]] || ! echo "File is not plain text." >&2
	diff $+ -q
open_unittest5.txt: test
	cat $< \
	| python3 -c "exec('from portage_utils import open\nf=open(\"$@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"


# Test writing to a compress gz file
open_unittest6: open_unittest6.gz test
	[[ `file $<` =~ "gzip compressed data" ]] || ! echo "File is not of gzip format." &>2
	zcmp $+
open_unittest6.gz: test
	cat $< \
	| python3 -c "exec('from portage_utils import open\nf=open(\"$@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"


# Test writing to a compress gz file
open_unittest7: open_unittest7.gz test
	sleep 1 # Occasionally, the file is still empty by the time we get here
	[[ `file $<` =~ "gzip compressed data" ]] || ! echo "File is not of gzip format." &>2
	zcmp $+
open_unittest7.gz: test
	cat $< \
	| python3 -c "exec('from portage_utils import open\nf=open(\"| gzip > $@\", \"w\")\nfor line in open(\"-\"): f.write(line)')"


# Test writing to no file which should produce an error message.
open_unittest8: test
	cat $< \
	| python3 -c "exec('from portage_utils import open\nf=open(\"\", \"w\")\nfor line in open(\"-\"): f.write(line)')" 2>&1 \
	| grep "Fatal error: You must provide a filename" --quiet


.PHONY: open_unittest9
open_unittest9:  open_unittest9a open_unittest9b

big.gz:
	seq 1 1000000 | gzip > $@

# Testing partially reading a gzip file and not getting a Broken pipe message.
open_unittest9a:  %:  big.gz
	-python3 -c "exec('from portage_utils import open\nfor line in open(\"$<\", \"r\", False):\n  if True: break\n')" 2>&1 | egrep '(zcat|gzip): stdout: Broken pipe'

open_unittest9b:  %:  big.gz
	! { set -o pipefail; python3 -c "exec('from portage_utils import open\nfor line in open(\"$<\", \"r\", True):\n  if True: break\n')" 2>&1 | egrep '(zcat|gzip): stdout: Broken pipe'; }


.PHONY: split_testsuite
split_testsuite: split_unittest1 split_unittest2

# test split functionality on string containing a non-breaking space.
.PHONY: split_unittest1
split_unittest1:
	echo "from portage_utils import split; print(split(u' a b\tc\t d\N{no-break space}dd \t\n'))" \
	| python3 \
	| diff - <(echo "['a', 'b', 'c', 'd\xa0dd']")

# test split functionality on string containing no tokens (i.e. only whitespace)
.PHONY: split_unittest2
split_unittest2:
	echo "from portage_utils import split; print(split(u'\n'))" \
	| python3 \
	| diff - <(echo "[]")

# Test a multiplicity and newlines and encoding options
open_newlines_encodings:
	python3 $@.py | diff - ref/$@.out
