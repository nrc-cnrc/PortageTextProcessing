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
if which-test.sh python2; then
   make clean
   make all -B -j ${OMP_NUM_THREADS:-$(nproc)} --makefile Makefile.python2
fi

# Run the test suite with Python 3
make clean
make all -B -j ${OMP_NUM_THREADS:-$(nproc)}

exit
