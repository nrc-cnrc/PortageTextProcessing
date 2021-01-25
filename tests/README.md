# Unit testing for PortageTextProcessing

This directory contains the unit test suites for the scripts in PortageTextProcessing.

## Running the tests

Run `./run-all-tests.sh` to run all test suites. A summary of the results will
be printed on script, with the log from each test suite saved into
`_log.run-test` in its directory.

You can run an individual test suite by running `./run-test.sh` in its directory.

In the case of test suites that are parallelized, you can run `make -B` to run
the test cases sequentially and better see which commands produce which
output/errors.

## Cleaning up

Run `./clean-all-tests.sh` to remove all temporary files in the test suites.

## Writing test

Each test suite has to respect the following simple rules:
 - `./run-test.sh` should run the suite and exit 0 if all test cases pass, or
   exit non-zero otherwise.
 - Provide a `Makefile` that, at minimum (see `normalize-unicode/Makefile` for
   the simplest example):
   - has the statement `include ../Makefile.incl`
   - has a `test:` target to run the test suite,
   - sets `all: test` as a dependency

Including `../Makefile.incl` automates several things for you:
 - The `make clean` target is alread implemented, you just need to declare your
   temporary files in variable `TEMP_FILES`, and temporary directories in
   variable `TEMP_DIRS`.
 - The `.gitignore` file gets created for you when you run `make all`.
 - A friendly "All tests PASSED." message gets printed by `make all` when all
   tests pass.

Have a look at the various Makefiles in the test suites for more complex
examples you can reuse as necessary.
