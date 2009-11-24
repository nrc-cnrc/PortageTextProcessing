#!/usr/bin/make -f
# $Id$
# vim:noet:ts=3

# @file Makefile
# @frief Tests tmx2lfl.pl
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2009, Sa Majeste la Reine du Chef du Canada /
# Copyright 2009, Her Majesty in Right of Canada

L1 ?= lang1
L2 ?= lang2

.PHONY: all
all: corpus

.PHONY: corpus
corpus: corpus1
corpus: corpus2
corpus: corpus3
corpus: corpus4
corpus: corpus5
corpus: corpus6


.PHONY: clean
clean:
	${RM} test*.utf8.tmx
	${RM} corpus*


test.utf8.tmx: test.tmx
	iconv -f UCS-2 -t UTF-8 < $< > $@


# Generic target/commands for corpus1 corpus2.
corpus%:
	tmx2lfl.pl -output=$@ -txt=.txt $<
	diff -q $@.${L1}     ref/ref.${L1}
	diff -q $@.${L1}.txt ref/ref.${L1}.txt
	diff -q $@.${L2}     ref/ref.${L2}
	diff -q $@.${L2}.txt ref/ref.${L2}.txt
	diff -q $@.id        ref/ref.id


# Extract parallel corpus from a UCS-2 tmx.
.PHONY: corpus1
corpus1: test.tmx


# Extract parallel corpus from a UTF-8 tmx.
.PHONY: corpus2
corpus2: test.utf8.tmx


# Create a tmx with three language specifiers on the utf-8 tmx.
test3.utf8.tmx: test.utf8.tmx
	sed '1,35{s/lang2/lang3/}' < $< > $@

# There should be three language specifiers.
.PHONY: corpus3
corpus3: test3.utf8.tmx
	tmx2lfl.pl -output=$@ -txt=.txt $< 2>&1 | grep -q 'Language identifiers found are: lang2:lang1:lang3' 


# Using the 3 language specifiers and there should be 10 EMPTY_ tags.
.PHONY: corpus4
corpus4: test3.utf8.tmx	
	tmx2lfl.pl -output=$@ -txt=.txt -src=lang1 -tgt=lang3 $<
	@[[ `cat $@* | grep -c 'EMPTY_'` == 10 ]]


# Inserting invalid character according to xml specification.
test5.utf8.tmx: test.utf8.tmx
	sed '26,35{s/d//}' < $< > $@

# We should find exactly 3 parse errors.
.PHONY: corpus5
corpus5: test5.utf8.tmx
	[[ `tmx2lfl.pl -output=$@ -txt=.txt $< 2>&1 | grep -c "parser error"` == 3 ]]


# Multiple tmx extraction.
.PHONY: corpus6
corpus6: test.tmx test.utf8.tmx
	tmx2lfl.pl -output=$@ $+
	cat ref/ref.${L1} ref/ref.${L1} | diff -q - $@.${L1}
	cat ref/ref.${L2} ref/ref.${L2} | diff -q - $@.${L2}
	cat ref/ref.id    ref/ref.id    | diff -q - $@.id
