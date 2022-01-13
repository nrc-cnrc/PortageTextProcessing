#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make

# @file Makefile
# @brief Basic unit test cases for PortageTextProcessing
#
# The goal of this unit test suite is just to provide coverage: call each script
# in PortageTextProcessing at least once in at least one of the test suites,
# here if nowhere else.
#
# @author Eric Joanis
#
# Traitement multilingue de textes / Multilingual Text Processing
# Centre de recherche en technologies numériques / Digital Technologies Research Centre
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2021, Sa Majesté la Reine du Chef du Canada /
# Copyright 2021, Her Majesty in Right of Canada

include ../Makefile.incl
TEMP_FILES=out.* in-copy.* src/parallel*.no-blanks src/parallel*.dedup \
           src/parallel*.filt src/parallel*.uniq seq.gz
TEMP_DIRS=
SHELL:=/bin/bash

all: test

compare.%: %
	@echo -n "diff $* ref/$* "
	@(diff $* ref/$* &> /dev/null) && echo "OK" || (echo "FAILED" && false)

test: compare.out.expand-auto
out.expand-auto: src/expand-auto.in
	expand-auto.pl < $< > $@

test: compare.out.expand-auto.utf8
out.expand-auto.utf8: src/expand-auto.in
	expand-auto.pl -u < $< > $@

test: compare.out.clean-utf8-text
out.clean-utf8-text: src/dirty-utf8
	clean-utf8-text.pl < $< > $@

test: compare.out.clean_utf8
out.clean_utf8: src/dirty-utf8
	clean_utf8.py < $< > $@

test: compare.out.ridbom
out.ridbom: src/dirty-utf8
	ridbom.sh < $< > $@

test: compare.out.crlf2lf
out.crlf2lf: src/dirty-utf8
	crlf2lf.sh < $< > $@

test: compare.out.diff-round
out.diff-round: src/numbers1 src/numbers2
	! diff-round.pl $+ > $@ 2>&1

test: compare.out.fix-slashes
out.fix-slashes: src/dirty-utf8
	fix-slashes.pl < $< > $@

test: compare.out.accent-slash
out.accent-slash: src/accent-slash
	fix-slashes.pl $< > $@

test: compare.out.lc-utf8
out.lc-utf8: src/dirty-utf8
	lc-utf8.pl < $< > $@

test: compare.out.li-sort
out.li-sort: src/dirty-utf8
	LC_ALL=fr_CA.UTF-8 li-sort.sh < $< > $@

test: compare.out.sort-by-length
out.sort-by-length: src/dirty-utf8
	sort-by-length.pl < $< > $@

test: compare.out.iu
out.iu: src/iu
	normalize-iu-spelling.pl < $< > $@

test: compare.out.strip-blanks
out.strip-blanks: src/parallel1 src/parallel2
	strip-parallel-blank-lines.py $+
	head src/parallel?.no-blanks > $@

test: compare.out.strip-blanks-r
out.strip-blanks-r: src/parallel1 src/parallel2
	cp src/parallel1 in-copy.parallel1
	gzip < src/parallel2 > in-copy.parallel2.gz
	strip-parallel-blank-lines.py -r in-copy.parallel1 in-copy.parallel2.gz
	zcat -f in-copy.parallel?.no-blanks* > $@

test: compare.out.strip-dup
out.strip-dup: src/parallel1 src/parallel2
	strip-parallel-duplicates.py $+
	head src/parallel?.dedup > $@

test: compare.out.filt
out.filt: src/parallel.scores src/parallel1 src/parallel2
	filter-parallel.py -ge 3 $+
	head src/parallel?.filt > $@

test: compare.out.parallel-uniq
out.parallel-uniq: src/parallel1 src/parallel2
	parallel-uniq.pl $+
	head src/parallel?.uniq > $@

test: compare.out.stableuniq
out.stableuniq: src/parallel1 src/parallel2
	cat $+ | stableuniq.pl > $@

test: compare.out.random-chunks
out.random-chunks:
	select-random-chunks.py  -o 35 -m 100 | wc -l > $@

test: test.lines.py
test.lines.py:
	diff <(lines.py <(echo $$'2\n4\n4\n10\n1') <(seq 1 20)) <(echo $$'1\n2\n4\n4\n10')
	seq 1 20 | gzip > seq.gz
	diff <(lines.py <(echo $$'2\n4\n4\n10\n1') seq.gz) <(echo $$'1\n2\n4\n4\n10')

test: test.select-lines.py
test.select-lines.py:
	diff <(select-lines.py <(echo $$'2\n4\n5\n10') <(seq 1 20)) <(echo $$'2\n4\n5\n10')
	! select-lines.py <(echo $$'2\n4\n3\n10') <(seq 1 20) >& /dev/null
	! select-lines.py <(echo not-a-number) <(seq 1 20) >& /dev/null
