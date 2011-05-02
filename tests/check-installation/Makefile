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

HOSTNAME:=$(shell uname -n)
ifeq (${HOSTNAME},iitgatsrv0575)
# On Leclerc, where we run autobuild, the default Perl can't handle XML::Twig
export PERL5LIB:=/home/portage/i686-g4.2/lib/site_perl/5.8.9:${PERL5LIB}
export PATH:=/home/portage/pkgs/perl-5.8.9-x86_64/bin:${PATH}
TMX2LFL:=perl $(shell which tmx2lfl.pl)
else
TMX2LFL:=tmx2lfl.pl
endif

# Generic error message
EXPLAIN := Can not run your program.

SHELL = bash
.PHONY: all
all: testsuite


.PHONY: clean
clean:
	@true

.PHONY: testsuite
testsuite:
	@echo "Installation successful!"



########################################
# What can be checked before starting to install Portage.
testsuite: pre_installation

.PHONY: pre_installation
pre_installation: perl_version make_version gcc_version ram_vs_swap
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


# Since the ram is power of 1024 but swap is power of 1000, we will make the
# conversion here.
.PHONY: ram_vs_swap
ram_vs_swap:
	@SWAP=`cat /proc/meminfo | grep SwapTotal | egrep -o '[0-9]+'`; \
	RAM=`cat /proc/meminfo | grep MemTotal | egrep -o '[0-9]+'`; \
	[[ $$SWAP -ge $$((2 * $$RAM * 1000 / 1024 * 1000 / 1024)) ]] \
	|| echo "We strongly suggest that you have twice as much swap($$SWAP) than ram($$RAM)." >&2



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
cow.sh tokenize.pl canoe ce.pl:
	@which $@ &> /dev/null || ! echo "Can't locate $@ in your PATH!" >&2
	@$@ -h 2>&1 | cmp --quiet - ref/$@.ref || ! echo "$@ FAILED: ${EXPLAIN}  Refer to \$$PORTAGE/INSTALL" >&2

# We need a special target for the daily build on leclerc.
tmx2lfl.pl:
	@which $@ &> /dev/null || ! echo "Can't locate $@ in your PATH!" >&2
	@${TMX2LFL} -h 2>&1 | cmp --quiet - ref/$@.ref || ! echo "$@ FAILED: ${EXPLAIN}  Refer to \$$PORTAGE/INSTALL" >&2

