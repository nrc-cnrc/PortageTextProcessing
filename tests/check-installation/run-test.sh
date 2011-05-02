#!/bin/bash
# $Id$

# @file run-test.sh
# @brief Run this test suite, with a non-zero exit status if it fails
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2010, Sa Majeste la Reine du Chef du Canada /
# Copyright 2010, Her Majesty in Right of Canada

make clean
make testsuite

exit
