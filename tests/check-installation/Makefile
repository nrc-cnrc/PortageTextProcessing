#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make

# @file Makefile
# @brief Validate all dependencies for Portage.
#
# @author Samuel Larkin, Eric Joanis, Darlene Stewart
#
# Traitement multilingue de textes / Multilingual Text Processing
# Tech. de l'information et des communications / Information and Communications Tech.
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, 2016, 2021, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, 2016, 2021, Her Majesty in Right of Canada

-include Makefile.params

# Generic error messages
EXPLAIN := Cannot run your program.
EXPLAININSTALL = ${EXPLAIN} Did you source SETUP.bash and install the required dependencies?

# Stabilize the output
export PORTAGE_INTERNAL_CALL=1

SHELL = bash
.PHONY: all
all: testsuite

include ../Makefile.incl

.PHONY: testsuite
testsuite:
	@echo $$'Installation successful.\n'

# Function to run a test with a given summary label, and a given error text if it fails
#DEBUG_RUN=1
ifdef DEBUG_RUN
   check = echo "<D>$2"; echo -n "$1: "; if $2; then echo OK; else echo "***" $3 "***"; false; fi
else
   check = echo -n "$1: "; if $2; then echo OK; else echo "***" $3 "***"; false; fi
endif

check_installed = $(call check,$1 installed,which $1 >& /dev/null,NOT FOUND. ${EXPLAININSTALL})

foo:
	@$(call check,run true,true,ERROR)
	@$(call check,run false,false,ERROR)

########################################
# What can be checked before starting to install Portage.
testsuite: pre_installation

.PHONY: pre_installation
pre_installation: perl_version perl_modules
pre_installation: python2_version python2_modules
pre_installation: python3_version python3_modules
pre_installation: xml_grep xmllint
pre_installation:
	@echo $$'\nPrerequisites are correctly installed.\n'

.PHONY: perl_version
perl_version:
	@$(call check,Perl version,perl -e 'require 5.14.0;',Portage requires Perl 5.14 or greater for proper UTF-8 handling.)

.PHONY: perl_modules
perl_modules:
	@rc=0; for module in XML::Twig XML::XPath File::Temp Getopt::Long POSIX File::Basename Data::Dumper locale; do \
		$(call check,Perl module $$module,perldoc -l $$module >& /dev/null,NOT FOUND) || rc=1; \
	done; [[ $$rc == 0 ]] || ! echo "Some required Perl modules are missing."
	@$(call check,XML::Twig version,perl -e 'use XML::Twig 3.32;',Portage requires XML::Twig version 3.32 or greater.)

.PHONY: python2_version
python2_version:
	@$(call check,Python version 2.7,python2 --version 2>&1 | grep -q 2\.7,PortageTextProcessing requires Python 2.7 as python2.)

.PHONY: python2_modules
python2_modules:
	@rc=0; for module in argparse __future__ optparse os.path subprocess codecs gzip math os re sys string time; do \
		$(call check,Python 2 module $$module,python2 -c "import $$module" >& /dev/null,NOT FOUND) || rc=1; \
	done; [[ $$rc == 0 ]] || ! echo "Some required Python 2 modules are missing."

.PHONY: python3_version
python3_version:
	@$(call check,Python version 3.x,python3 --version 2>&1 | grep -q 3,PortageTextProcessing requires Python 3.? as python3.)

.PHONY: python3_modules
python3_modules:
	@rc=0; for module in builtins os re string sys argparse __future__ os.path subprocess random; do \
		$(call check,Python 3 module $$module,python3 -c "import $$module" >& /dev/null,NOT FOUND) || rc=1; \
	done; [[ $$rc == 0 ]] || ! echo "Some required Python 3 modules are missing."

.PHONY: xml_grep xmllint
xml_grep xmllint: EXPLAIN:=tmx2lfl.pl required xml_grep and xmllint. Make sure they are correcly installed.
xml_grep xmllint:
	@$(call check_installed,$@)
	@$(call check,$@ runs,\
		$@ --version 2>&1 | grep -q "$@.*version",\
		"$@ --version FAILED. ${EXPLAININSTALL}")


########################################
# What needs to work after a successful installation of Portage.
testsuite: post_installation

VALIDATE_PGMS := utokenize.pl tmx2lfl.pl clean_utf8.py select-lines.py sh_utils.sh
.PHONY: post_installation
post_installation: ${VALIDATE_PGMS}
	@echo $$'\nPortageTextProcessing itself is correctly installed.\n'

tmx2lfl.pl: EXPLAIN:=Check your PERL5LIB, or you're missing XML::Twig, or your XML::Twig version is less than 3.32.
utokenize.pl: EXPLAIN:=Check your PERL5LIB.
clean_utf8.py: EXPLAIN:=Check your Python 3 version and PYTHONPATH.
select-lines.py: EXPLAIN:=Check your Python 2.7 version and PYTHONPATH.
sh_utils.sh: EXPLAIN:=Check your PATH.

.PHONY: ${VALIDATE_PGMS}
# We simply make sure we can invoke the help message to trigger the dependencies.
${VALIDATE_PGMS}:
	@$(call check,$@ installed,which $@ &> /dev/null,\
		"NOT FOUND. Cannot locate PortageTextProcessing program $@ in your PATH. Refer to \$$PORTAGE/INSTALL.")
	@$(call check,$@ runs,$@ -h >& /dev/null,"$@ -h FAILED TO RUN: ${EXPLAININSTALL}")
	@$(call check,$@ help,$@ -h 2>&1 | head -5 | diff - ref/$@.ref,\
		"$@ -h did not produce the expected output: Is it the right version? ${EXPLAININSTALL}")
