#!/bin/bash
# run-all-tests.sh - Run all unit testing suites, reporting which ones failed
#
# PROGRAMMER: Eric Joanis
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2008, Sa Majeste la Reine du Chef du Canada /
# Copyright 2008, Her Majesty in Right of Canada

if [[ "$1" == "-j" ]]; then
   PARALLEL_MODE=1
   PARALLEL_LEVEL=$2
   shift
   shift
fi

if [[ "$1" =~ "^-" ]]; then
   echo "Usage: $0 [test-suite [test-suite2 [...]]]
   Run the specified test suites, or all test suites if none are specified.
   Each test suite must contain a script named run-test.sh which returns 0
   as exit status if the suite passes, non-zero otherwise.

Option:
   -j N   Run the tests N-ways parallel.
"
   exit
fi

TEST_SUITES=$*
if [[ ! $TEST_SUITES ]]; then
   TEST_SUITES=`echo */run-test.sh | sed 's/\/run-test.sh//g'`
fi

echo ""
echo Test suites to run: $TEST_SUITES

if [[ $PARALLEL_MODE ]]; then
   LOG=.log.run-all-tests-parallel
   PARALLEL_MODE=
   for suite in $TEST_SUITES; do
      echo $0 $suite
   done |
      run-parallel.sh -unordered-cat -v - $PARALLEL_LEVEL 2>&1 |
      tee $LOG | grep --line-buffered '^\['
   grep PASSED $LOG | grep -v 'test suites' | sort -u
   grep FAILED $LOG | grep -v 'test suites' | sort -u

   if grep -q FAILED $LOG; then
      exit 1
   else
      echo ""
      echo PASSED all test suites
      exit
   fi
fi

run_test() {
   { time-mem ./run-test.sh; } >& _log.run-test
}

for TEST_SUITE in $TEST_SUITES; do
   echo ""
   echo =======================================
   echo Running $TEST_SUITE
   if cd -- $TEST_SUITE; then
      if [[ ! -x ./run-test.sh ]]; then
         echo '***' FAILED $TEST_SUITE: can\'t find or execute ./run-test.sh
         FAIL="$FAIL $TEST_SUITE"
      elif run_test; then
         echo PASSED $TEST_SUITE
      else
         echo '***' FAILED $TEST_SUITE: ./run-test.sh returned $?
         FAIL="$FAIL $TEST_SUITE"
      fi

      cd ..
   else
      echo '***' FAILED $TEST_SUITE: could not cd into $TEST_SUITE
      FAIL="$FAIL $TEST_SUITE"
   fi
done

echo ""
echo =======================================
if [[ $FAIL ]]; then
   echo '***' FAILED these test suites:$FAIL
   exit 1
else
   echo PASSED all test suites
fi



