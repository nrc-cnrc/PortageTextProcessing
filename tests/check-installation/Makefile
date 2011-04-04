#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make
# $Id$

# @file Makefile
# @brief Validate all dependencies for Portage.
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologiesm
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, Her Majesty in Right of Canada



-include Makefile.params

# Generic error message
EXPLAIN := Can not run your program.

.PHONY: all
all: testsuite


.PHONY: clean
clean:


.PHONY: testsuite
testsuite: canoe cow.sh tokenize.pl ce.pl tmx2lfl.pl
	@echo "Everything is correctly installed!" >&2


canoe: EXPLAIN:=Make sure Portage is correctly installed.  Check your PATH.
ce.pl: EXPLAIN:=Check your PERL5LIB or XML::Twig may not be correctly installed.
cow.sh: EXPLAIN:=Make sure Portage is correctly installed.  Check your PATH.
tmx2lfl.pl: EXPLAIN:=Check your PERL5LIB or you're missing XML::Twig or your version is not greater or equal to XML::Twig-3.28.
tokenize.pl: EXPLAIN:=Check your PERL5LIB.

# We simply make sure we can invoke the help message to trigger the dependencies.
cow.sh tokenize.pl canoe ce.pl tmx2lfl.pl:
	@which $@ &> /dev/null || echo "Can't locate $@ in your PATH!" >&2
	@$@ -h 2>&1 | cmp --quiet - ref/$@.ref || echo "$@ FAILED: ${EXPLAIN}  Refer to \$$PORTAGE/INSTALL" >&2

