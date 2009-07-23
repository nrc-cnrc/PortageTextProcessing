#!/bin/bash
# run-all-tests.sh - Run the clean Makefile target for all unit testing suites
#
# PROGRAMMER: Darlene Stewart
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2009, Sa Majeste la Reine du Chef du Canada /
# Copyright 2009, Her Majesty in Right of Canada

if [[ "$1" =~ "^-" ]]; then
   echo "Usage: $0 [test-suite [test-suite2 [...]]]
       Run the clean Makefile target for the specified test suites, 
       or all test suites if none are specified."
   exit
fi

TEST_SUITES=$*
if [[ ! $TEST_SUITES ]]; then
   TEST_SUITES=`echo */Makefile | sed 's/\/Makefile//g'`
fi

echo ""
echo Test suites to clean: $TEST_SUITES

for TEST_SUITE in $TEST_SUITES; do
   echo ""
   echo =======================================
   echo Cleaning $TEST_SUITE
   if cd -- $TEST_SUITE; then
      if [[ ! -x ./Makefile ]]; then
         echo FAILED $TEST_SUITE: can\'t find or execute ./Makefile
         FAIL="$FAIL $TEST_SUITE"
      else
         TARGET=clean
      	 if [[ $TEST_SUITE == "canoe.compress.output" ]]; then
      	 	TARGET=distclean
      	 elif [[ $TEST_SUITE == "filter_models" ]]; then
      	 	TARGET=distclean
      	    if ! make -C histogram clean; then
         	   echo FAILED $TEST_SUITE/histogram: make returned $?
         	   FAIL="$FAIL $TEST_SUITE/histogram"
            fi
      	 fi
      	 if ! make $TARGET; then
         	echo FAILED $TEST_SUITE: make returned $?
         	FAIL="$FAIL $TEST_SUITE"
         fi
      fi

      echo "rm -f log.run-test run-parallel-logs-*"
      rm -f log.run-test run-parallel-logs-*
      cd ..
   else
      echo FAILED $TEST_SUITE: could not cd into $TEST_SUITE
      FAIL="$FAIL $TEST_SUITE"
   fi
done

for TEST_SUITE in align.posteriors run-parallel.sh; do
   echo ""
   echo =======================================
   echo Cleaning $TEST_SUITE
   if cd -- $TEST_SUITE; then
      echo "rm -f log.run-test run-parallel-logs-*"
      rm -f log.run-test run-parallel-logs-*
      cd ..
   else
      echo FAILED $TEST_SUITE: could not cd into $TEST_SUITE
      FAIL="$FAIL $TEST_SUITE"
   fi
done

echo ""
echo =======================================
if [[ $FAIL ]]; then
   echo FAILED to clean these test suites:$FAIL
   exit 1
else
   echo CLEANED all test suites
fi
