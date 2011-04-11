#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make
# $Id$

# @file Makefile
# @brief Unittest for lfl2tmx.pl
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologiesm
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, Her Majesty in Right of Canada


LFL2TMX := lfl2tmx.pl

HOSTNAME:=$(shell uname -n)
ifeq (${HOSTNAME},iitgatsrv0575)
# On Leclerc, where we run autobuild, the default Perl can't handle XML::Twig/xml_grep
export PERL5LIB:=/home/portage/i686-g4.2/lib/site_perl/5.8.9:${PERL5LIB}
export PATH:=/home/portage/pkgs/perl-5.8.9-x86_64/bin:${PATH}
XML_GREP := perl $(shell which xml_grep)
else
XML_GREP := xml_grep
endif


-include Makefile.params


vpath %.id  src/
vpath %.al  src/
vpath %.tmx ref/


SHELL = bash
.PHONY: all
all: test-suite


.PHONY: clean
clean:
	${RM} unittest*


.PHONY: test-suite
test-suite: unittest1
test-suite: unittest2
test-suite: unittest3
test-suite: unittest4
test-suite: unittest5
test-suite: unittest6
test-suite: unittest7


# Single file.
.PHONY: unittest1
unittest1: 39-1-JUST-15.id 39-1-JUST-15_en.al 39-1-JUST-15_fr.al unittest1.tmx
	${LFL2TMX} $(basename $(filter %.id, $+)) > $@
	[[ `${XML_GREP} --text_only --nowrap --cond 'tu/tuv[@xml:lang="EN-CA"]' $@ | \wc -l` == `\wc -l < $(basename $(filter %.id, $+))_en.al` ]]
	[[ `grep -co '&lt;Affiliation&gt;' $@` == 32 ]]
	[[ `grep -co '&lt;Sup&gt;' $@` == 2 ]]
	${XML_GREP} --cond 'tuv[@xml:lang="FR-CA"]' --text_only $@ | diff -q - $(filter %_fr.al, $+)
	${XML_GREP} --cond 'tuv[@xml:lang="EN-CA"]' --text_only $@ | diff -q - $(filter %_en.al, $+)
	cmp $@ $(filter %.tmx, $+)


# Make sure we have generated a valid tmx.
.PHONY: unittest2
unittest2: unittest1


# From a directory.
.PHONY: unittest3
unittest3: src unittest3.tmx
	${LFL2TMX} $< > $@
	[[ `${XML_GREP} --text_only --nowrap --cond 'tu/tuv[@xml:lang="EN-CA"]' $@ | \wc -l` == `cat src/*_en.al | \wc -l` ]]
	diff -q <(${XML_GREP} --cond 'tuv[@xml:lang="FR-CA"]' --text_only $@) <(cat src/*_fr.al)
	diff -q <(${XML_GREP} --cond 'tuv[@xml:lang="EN-CA"]' --text_only $@) <(cat src/*_en.al)
	cmp $@ $(filter %.tmx, $+)


# Make sure we have generated a valid tmx.
.PHONY: unittest4
unittest4: unittest3


unittest2 unittest4:
	xmllint --dtdvalid tmx14.dtd $< &> /dev/null


# Copyright notice prefix.
.PHONY: unittest5
unittest5: 40-2-ETHI-30.id unittest5.tmx
	${LFL2TMX} -copyright permission_hoc $(basename $(filter %.id, $+)) > $@
	${XML_GREP} --nowrap --cond 'header/note[@xml:lang="EN-CA"]' $@ \
	| sed -e '/<note xml:lang/d; /<\/note>/d' \
	| diff -q - permission_hoc_en.txt
	${XML_GREP} --nowrap --cond 'header/note[@xml:lang="FR-CA"]' $@ \
	| sed -e '/<note xml:lang/d; /<\/note>/d' \
	| diff -q - permission_hoc_fr.txt
	cmp $@ $(filter %.tmx, $+)


# Remove xml markup.
.PHONY: unittest6
unittest6: 39-1-JUST-15.id unittest6.tmx
	${LFL2TMX} -x $(basename $(filter %.id, $+)) > $@
	[[ `grep -co '&lt;Affiliation&gt;' $@` == 0 ]]
	[[ `grep -co 'Affiliation' $@` == 0 ]]
	[[ `grep -co '&lt;Sup&gt;' $@` == 0 ]]
	[[ `grep -co 'Sup' $@` == 0 ]]
	cmp $@ $(filter %.tmx, $+)


# Detokenize sentences.
.PHONY: unittest7
unittest7: 39-1-JUST-15.id unittest7.tmx
	${LFL2TMX} -t $(basename $(filter %.id, $+)) > $@
	[[ `egrep -co ' \.$$' $@` == 0 ]]
	cmp $@ $(filter %.tmx, $+)

