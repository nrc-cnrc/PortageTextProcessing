#!/bin/bash
# run-test.sh - Unit-test for portage_utils.pyc
# Tests
#
# PROGRAMMER: Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, Her Majesty in Right of Canada

# Run the test suite with Python 2.7, but only if we find python2, since
# PortageTextProcessing no longer actually has any python2 scripts.

EXIT_CODE=

if which-test.sh python2; then
   make clean
   if ! make all -B -j ${OMP_NUM_THREADS:-$(nproc)} --makefile Makefile.python2; then
      EXIT_CODE=1
   fi
fi

# Run the test suite with Python 3
make clean
if ! make all -B -j ${OMP_NUM_THREADS:-$(nproc)}; then
   EXIT_CODE=1
fi

if [[ $EXIT_CODE ]]; then
   echo Some tests FAILED, running with either python2 or python3. Scroll up for details.
fi

exit $EXIT_CODE
