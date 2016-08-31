#!/usr/bin/make -f
# vim:noet:ts=3:nowrap:filetype=make

# @file Makefile
# @brief Validate all dependencies for Portage.
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, Her Majesty in Right of Canada



-include Makefile.params

# Generic error message
EXPLAIN := Can not run your program.

# Stabilize the output
export PORTAGE_INTERNAL_CALL=1

SHELL = bash
.PHONY: all
all: testsuite

include ../Makefile.incl

.PHONY: testsuite
testsuite:
	@echo "Installation successful."



########################################
# What can be checked before starting to install Portage.
testsuite: pre_installation

.PHONY: pre_installation
pre_installation: perl_version
pre_installation: perl_modules
pre_installation: python_version
pre_installation: python_modules
pre_installation: make_version
pre_installation: gcc_version
pre_installation: ram_vs_swap
	@echo "Prerequisites are correctly installed." >&2

.PHONY: perl_version
perl_version:
	@perl -e 'require 5.14.0;' || ! echo "Your perl version is too old." >&2
	@perl -e 'require 5.14.4;' || echo "Some perl XML functionalities will most likely fail." >&2
	@perl -e 'use threads;' || ! echo "Perl must be installed with -Dusethreads." >&2

.PHONY: perl_modules
perl_modules: perl_modules_for_portage_r_and_d
perl_modules:
	@rc=0; for module in XML::Twig XML::XPath JSON YAML File::Spec File::Temp List::Util Time::gmtime FindBin Env; do \
		perldoc -l $$module || rc=1; \
	done; [[ $$rc == 0 ]] || ! echo "Some required Perl modules are missing." >&2
	@perl -e 'use XML::Twig 3.32;' || ! echo "Portage requires XML::Twig version 3.32 or greater." >&2

perl_modules_for_portage_r_and_d:
	@perldoc -l Algorithm::Diff
	@perldoc -l Bloom::Faster
	@perldoc -l Data::TreeDumper
	@perldoc -l Encode::Buckwalter || ! echo "Buckwalter encoding is used during MADA." >&2
	@perldoc -l Encode::HanConvert
	@perldoc -l Iterator
	@perldoc -l JSON::XS || ! echo "JSON parsing will be significantly slower without a C implementation." >&2
	@perldoc -l Test::More
	@perldoc -l Tie::Cache
	@perldoc -l Time::HiRes
	@perldoc -l Time::Piece
	@perldoc -l Tree::Simple
	@perldoc -l XML::Writer
	@perl -e 'use Term::ANSIColor 2.02;'  || ! echo "jobtree & qstattree require colorvalid to parse user defined colors via $$PORTAGE_QSTATTREE_COLORS" >&2


.PHONY: python_version
python_version:
	@python --version 2>&1 | grep -q 2\.7 || ! echo "Portage requires Python 2.7." >&2

.PHONY: python_modules
python_modules:
	@rc=0; for module in argparse ctypes __future__ optparse os.path subprocess codecs glob gzip math os re sys string theano; do \
		echo "Checking python's $$module";\
		python -c "import $$module" || rc=1;\
	done; [[ $$rc == 0 ]] || ! echo "Some required Python modules are missing." >&2

.PHONY: make_version
make_version:
	@[[ $$( echo "`\make --version | head -n 1 | egrep -o '[0-9\.]+'` >= 3.81" | bc) == 1 ]] \
	|| ! echo "Portage requires make-3.81" >&2


.PHONY: gcc_version
gcc_version:
	@[[ $$( echo "`${CXX} --version | head -n 1 | egrep -om1 '[0-9]\.[0-9]+' | head -n 1` >= 4.2" | bc) == 1 ]] \
	|| ! echo "Portage requires at least g++-4.2, unless you have a binary distribution." >&2


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

VALIDATE_PGMS := canoe tune.py tokenize.pl ce.pl tmx2lfl.pl filter-nc1.py arpalm.encode
.PHONY: post_installation
post_installation: ${VALIDATE_PGMS}
	@echo "Portage itself is correctly installed." >&2


canoe: EXPLAIN:=Make sure Portage is correctly installed.  Check your PATH.
ce.pl: EXPLAIN:=Check your PERL5LIB or XML::Twig may not be correctly installed.
tune.py: EXPLAIN:=Make sure Portage is correctly installed.  Check your PATH.
tmx2lfl.pl: EXPLAIN:=Check your PERL5LIB or you're missing XML::Twig or your version is not greater or equal to XML::Twig-3.28.
tokenize.pl: EXPLAIN:=Check your PERL5LIB.
filter-nc1.py: EXPLAIN:=Check your Python version and PYTHONPATH variable.
arpalm.encore: EXPLAIN:=Check that all boost libraries are installed.

.PHONY: ${VALIDATE_PGMS}
# We simply make sure we can invoke the help message to trigger the dependencies.
${VALIDATE_PGMS}:
	@which $@ &> /dev/null || ! echo "Can't locate $@ in your PATH." >&2
	@$@ -h 2>&1 | head -5 | diff - ref/$@.ref || ! echo "$@ -h FAILED: ${EXPLAIN}  Refer to \$$PORTAGE/INSTALL." >&2

post_installation: check_casemark

.PHONY: check_casemark
check_casemark: EXPLAIN:=Check your LD_LIBRARY_PATH: it should point to the location of libportage_truecasing.so.  Check your PYTHONPATH: it should point to the location of portage_utils.py.
check_casemark:
	@casemark.py -lm /dev/null /dev/null 2>&1 | diff - ref/casemark.py.error-ref || ! echo "casemark.py -lm /dev/null /dev/null FAILED: ${EXPLAIN}  Refer to \$$PORTAGE/INSTALL." >&2
