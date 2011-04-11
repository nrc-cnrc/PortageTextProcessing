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

SHELL = bash
.PHONY: all
all: testsuite


.PHONY: clean
clean:


.PHONY: testsuite
testsuite:
	@echo "Installation successful!"



########################################
# What can be checked before starting to install Portage.
testsuite: pre_installation

.PHONY: pre_installation
pre_installation: perl_version make_version gcc_version
	@echo "You are now ready to install Portage." >&2

.PHONY: perl_version
perl_version:
	@perl -e 'require 5.8.5;' || ! echo "Your perl version is to old." >&2
	@perl -e 'require 5.8.8;' || echo "Some perl XML functionalities we most likely fail." >&2


.PHONY: make_version
make_version:
	@[[ $$( echo "`\make --version | head -n 1 | egrep -o '[0-9\.]+'` >= 3.81" | bc) == 1 ]] \
	|| ! echo "Portage requires make-3.81" >&2


.PHONY: gcc_version
gcc_version:
	@[[ $$( echo "`\g++ --version | head -n 1 | egrep -om1 '[0-9]\.[0-9]+'` >= 4.2" | bc) == 1 ]] \
	|| ! echo "Portage requires at least g++-4.2!" >&2
	@[[ $$( echo "`\g++ --version | head -n 1 | egrep -om1 '[0-9]\.[0-9]+'` >= 4.4" | bc) == 1 ]] \
	|| echo "Warning: We highly recommand g++-4.4 or greater if you want to use OpenMP for internal parallelism!" >&2



########################################
# What needs to work after a successful installation of Portage.
testsuite: post_installation

.PHONY: post_installation
post_installation: canoe cow.sh tokenize.pl ce.pl tmx2lfl.pl
	@echo "Everything is correctly installed!" >&2


canoe: EXPLAIN:=Make sure Portage is correctly installed.  Check your PATH.
ce.pl: EXPLAIN:=Check your PERL5LIB or XML::Twig may not be correctly installed.
cow.sh: EXPLAIN:=Make sure Portage is correctly installed.  Check your PATH.
tmx2lfl.pl: EXPLAIN:=Check your PERL5LIB or you're missing XML::Twig or your version is not greater or equal to XML::Twig-3.28.
tokenize.pl: EXPLAIN:=Check your PERL5LIB.

.PHONY: cow.sh tokenize.pl canoe ce.pl tmx2lfl.pl
# We simply make sure we can invoke the help message to trigger the dependencies.
cow.sh tokenize.pl canoe ce.pl tmx2lfl.pl:
	@which $@ &> /dev/null || ! echo "Can't locate $@ in your PATH!" >&2
	@$@ -h 2>&1 | cmp --quiet - ref/$@.ref || ! echo "$@ FAILED: ${EXPLAIN}  Refer to \$$PORTAGE/INSTALL" >&2

