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
all: corpus1
all: corpus2
all: corpus3
all: corpus4
all: corpus5


.PHONY: clean
clean:
	${RM} test*.utf8.tmx
	${RM} corpus*


test.utf8.tmx: test.tmx
	iconv -f UCS-2 -t UTF-8 < $< > $@


# Extract parallel corpus from a UCS-2 tmx.
corpus1: test.tmx
corpus2: test.utf8.tmx
corpus%:
	tmx2lfl.pl -output=$@ -txt=.txt $<
	diff -q $@.${L1}     ref/ref.${L1}
	diff -q $@.${L1}.txt ref/ref.${L1}.txt
	diff -q $@.${L2}     ref/ref.${L2}
	diff -q $@.${L2}.txt ref/ref.${L2}.txt
	diff -q $@.id        ref/ref.id


# Create a tmx with three language specifiers.
test3.utf8.tmx: test.utf8.tmx
	sed '1,35{s/lang2/lang3/}' < $< > $@

# There should be three language specifiers.
corpus3: test3.utf8.tmx
	tmx2lfl.pl -output=$@ -txt=.txt $< 2>&1 | grep -q 'Language identifiers found are: lang2:lang1:lang3' 

corpus4: test3.utf8.tmx	
	tmx2lfl.pl -output=$@ -txt=.txt -src=lang1 -tgt=lang3 $<
	@[[ `cat $@* | grep -c 'EMPTY_'` == 10 ]]


# Inserting invalid character according to xml specification.
test5.utf8.tmx: test.utf8.tmx
	sed '26,35{s/d//}' < $< > $@

# We should find exactly 3 parse errors.
corpus5: test5.utf8.tmx
	[[ `tmx2lfl.pl -output=$@ -txt=.txt $< 2>&1 | grep -c "parser error"` == 3 ]]
