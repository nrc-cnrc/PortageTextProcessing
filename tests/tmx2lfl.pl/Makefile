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

TMX2LFL := tmx2lfl.pl

L1 ?= lang1
L2 ?= lang2



.PHONY: all
all: test-suite

# Simple test to make sure tmx2lfl.pl is present and that all its dependencies
# are presents.  Unfortunately, the help message returns 1 which indicates a
# failure.
.PHONY: version
version:
	${TMX2LFL} -h &> /dev/null

.PHONY: test-suite
test-suite: unittest1
test-suite: unittest2
test-suite: unittest3
test-suite: unittest4
test-suite: unittest5
test-suite: unittest6
test-suite: unittest7
test-suite: unittest8
test-suite: unittest9


# General unittest clean up.
.PHONY: clean
clean:
	${RM} unittest* test.utf8.tmx


test.utf8.tmx: test.tmx
	iconv -f UCS-2 -t UTF-8 < $< > $@


########################################
# Extract parallel corpus from a UCS-2 tmx.
# Note cannot be PHONY.
unittest1: test.tmx


########################################
# Extract parallel corpus from a UTF-8 tmx.
# Note cannot be PHONY.
unittest2: test.utf8.tmx

# Generic target/commands for unittest1 unittest2.
unittest1 unittest2:
	${TMX2LFL} -output=$@ -txt=.txt $<
	diff -q $@.${L1}     ref/ref.${L1}
	diff -q $@.${L1}.txt ref/ref.${L1}.txt
	diff -q $@.${L2}     ref/ref.${L2}
	diff -q $@.${L2}.txt ref/ref.${L2}.txt
	diff -q $@.id        ref/ref.id


########################################
# Create a tmx with three language specifiers on the utf-8 tmx.
test3.utf8.tmx: test.utf8.tmx
	sed '1,35{s/lang2/lang3/}' < $< > $@

# There should be three language specifiers.
.PHONY: unittest3
unittest3: test3.utf8.tmx
	${TMX2LFL} -output=$@ -txt=.txt $< 2>&1 | grep -q 'Language identifiers found are: lang2:lang1:lang3' 

# Special clean-up for this test.
clean: clean3
.PHONY: clean3
clean3:
	${RM} test3.utf8.tmx


########################################
# Using the 3 language specifiers and there should be 10 EMPTY_ tags.
.PHONY: unittest4
unittest4: test3.utf8.tmx	
	${TMX2LFL} -output=$@ -txt=.txt -src=lang1 -tgt=lang3 $<
	@[[ `cat $@* | grep -c 'EMPTY_'` == 10 ]]


########################################
# Inserting invalid character according to xml specification.
test5.utf8.tmx: test.utf8.tmx
	sed '26,35{s/d//}' < $< > $@

# We should find exactly 3 parse errors.
.PHONY: unittest5
unittest5: test5.utf8.tmx
	[[ `${TMX2LFL} -output=$@ -txt=.txt $< 2>&1 | grep -c "parser error"` == 3 ]]

# Special clean-up for this test.
clean: clean5
.PHONY: clean5
clean5:
	${RM} test5.utf8.tmx


########################################
# Multiple tmx extraction.
# We'll use one UTF-8 tmx and one UCS-2 tmx
.PHONY: unittest6
unittest6: test.tmx test.utf8.tmx
	${TMX2LFL} -output=$@ $+
	cat ref/ref.${L1} ref/ref.${L1} | diff -q - $@.${L1}
	cat ref/ref.${L2} ref/ref.${L2} | diff -q - $@.${L2}
	cat ref/ref.id    ref/ref.id    | diff -q - $@.id


########################################
# We need to make sure tmx2lfl.pl supports filenames containing spaces.
CORPUS_NAME_WITH_A_SPACE := Name\ with\ spaces.tmx
${CORPUS_NAME_WITH_A_SPACE}: test.tmx
	cp $+ "$@" && chmod u+w "$@"

.PHONY: unittest7
unittest7: ${CORPUS_NAME_WITH_A_SPACE}
	${TMX2LFL} -output=$@ "$<" "$<"
	cat ref/ref.${L1} ref/ref.${L1} | diff -q - $@.${L1}
	cat ref/ref.${L2} ref/ref.${L2} | diff -q - $@.${L2}
	cat ref/ref.id    ref/ref.id    | diff -q - $@.id

# Special clean-up for this test.
clean: clean7
.PHONY: clean7
clean7:
	${RM} ${CORPUS_NAME_WITH_A_SPACE}


########################################
# Extracting from a tmx produces by alignFactory which will also test the
# proper extraction of language identifiers.
.PHONY: unittest8
unittest8: alignFactory.tmx
	${TMX2LFL} -output=$@ $+
	@[[ `wc -l < $@.EN` == 4 ]] || echo "We were expecting 4 english segments." >&2
	@[[ `grep -c '^$$' $@.EN` == 1 ]] || echo "We were expecting 1 empty segment." >&2
	@[[ `wc -l < $@.FR` == 4 ]] || echo "We were expecting 4 french segments." >&2
	@[[ `grep -c UNKNOWN $@.id` == 4 ]] || echo "We were expecting 4 document ids." >&2


########################################
# This is the most feature complete tmx but is a blown apart tmx.
# tmx-1.4.tmx is a fixed tmx from the official site:
# http://xml.coverpages.org/tmxSpec971212.html
.PHONY: unittest9
unittest9: tmx-1.4.tmx
	${TMX2LFL} -src=EN -tgt=FR-FR -output=$@ $+
	@[[ `\wc -l < $@.EN` == 2 ]] || echo "We were expecting 2 french segments." >&2
	@[[ `\wc -l < $@.FR-FR` == 2 ]] || echo "We were expecting 2 english segments." >&2
	@[[ `grep -c EMPTY_ $@.FR-FR` == 1 ]] || echo "We were expecting one missing segment." >&2
	@[[ `grep -c UNKNOWN $@.id` == 2 ]] || echo "We were expecting 2 document ids." >&2
	@test ! -s $@.FR-CA || echo "We extracted the wrong target." >&2

