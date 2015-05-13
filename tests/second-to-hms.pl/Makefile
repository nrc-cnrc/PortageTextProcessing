#!/usr/bin/make -f
# vim:noet:ts=3:nowrap

# @file Makefile
# @brief Testsuite for second-to-hms.pl
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2009, Sa Majeste la Reine du Chef du Canada /
# Copyright 2009, Her Majesty in Right of Canada

SHELL=bash

.PHONY: all
all: testsuite
	@echo All tests PASSED.

clean:
	@:


.PHONY: testsuite
testsuite: seconds2HMS
testsuite: HMS2seconds



# Contains all tests that convert from seconds to HMS.
.PHONY: seconds2HMS

# Processing seconds to HMS thus HMS should be unchanged/untouched.
.PHONY: seconds2HMS_1
seconds2HMS: seconds2HMS_1
seconds2HMS_1:
	echo "3d5h0m9s" | second-to-hms.pl | diff -q - <(echo "3d5h0m9s")

.PHONY: seconds2HMS_2
seconds2HMS: seconds2HMS_2
seconds2HMS_2:
	second-to-hms.pl <(echo "277209s") | diff -q - <(echo "3d5h0m9s")

# to seconds.
.PHONY: seconds2HMS_3
seconds2HMS: seconds2HMS_3
seconds2HMS_3:
	echo "09s" | second-to-hms.pl | diff -q - <(echo "9s")

# to minutes & seconds
.PHONY: seconds2HMS_4
seconds2HMS: seconds2HMS_4
seconds2HMS_4:
	echo "309s" | second-to-hms.pl | diff -q - <(echo "5m9s")

# to hours, minutes & seconds
.PHONY: seconds2HMS_5
seconds2HMS: seconds2HMS_5
seconds2HMS_5:
	echo "7209s" | second-to-hms.pl | diff -q - <(echo "2h0m9s")

# to days, hours, minutes & seconds
.PHONY: seconds2HMS_6
seconds2HMS: seconds2HMS_6
seconds2HMS_6:
	echo "439209s" | second-to-hms.pl | diff -q - <(echo "5d2h0m9s")

# to days, hours, minutes & seconds
.PHONY: seconds2HMS_7
seconds2HMS: seconds2HMS_7
seconds2HMS_7:
	echo "86400s" | second-to-hms.pl | diff -q - <(echo "1d0h0m0s")

# Multiple time on a single line.
.PHONY: seconds2HMS_8
seconds2HMS: seconds2HMS_8
seconds2HMS_8:
	echo "439209s 439209s" | second-to-hms.pl | diff -q - <(echo "5d2h0m9s 5d2h0m9s")

# Rounding
.PHONY: round_1
seconds2HMS: round_1
round_1:
	echo "123.234s 321.654s 3.5s 45.0s" | second-to-hms.pl | diff -q - <(echo "2m3s 5m22s 4s 45s")


################################################################################
# Let's try to convert from dhms to seconds.
################################################################################

# Contains all tests that convert from HMS to seconds.
.PHONY: HMS2seconds

# HMS to seconds.
.PHONY: HMS2seconds_1
HMS2seconds: HMS2seconds_1
HMS2seconds_1:
	echo "3d5h0m9s" | second-to-hms.pl -r | diff -q - <(echo "277209s")

# From a file.
.PHONY: HMS2seconds_2
HMS2seconds: HMS2seconds_2
HMS2seconds_2:
	second-to-hms.pl -r <(echo "3d5h0m9s") | diff -q - <(echo "277209s")

# Only seconds.
.PHONY: HMS2seconds_3
HMS2seconds: HMS2seconds_3
HMS2seconds_3:
	echo "9s" | second-to-hms.pl -r | diff -q - <(echo "9s")

# minutes & seconds.
.PHONY: HMS2seconds_4
HMS2seconds: HMS2seconds_4
HMS2seconds_4:
	echo "5m9s" | second-to-hms.pl -r | diff -q - <(echo "309s")

# hours, minutes & seconds.
.PHONY: HMS2seconds_5
HMS2seconds: HMS2seconds_5
HMS2seconds_5:
	echo "2h0m9s" | second-to-hms.pl -r | diff -q - <(echo "7209s")

# days, hours, minutes & seconds.
.PHONY: HMS2seconds_6
HMS2seconds: HMS2seconds_6
HMS2seconds_6:
	echo "5d2h0m9s" | second-to-hms.pl -r | diff -q - <(echo "439209s")

# Missing items
.PHONY: HMS2seconds_7
HMS2seconds: HMS2seconds_7
HMS2seconds_7:
	echo "5d9s" | second-to-hms.pl -r | diff -q - <(echo "432009s")

# Missing items
.PHONY: HMS2seconds_8
HMS2seconds: HMS2seconds_8
HMS2seconds_8:
	echo "5d9s 5d9s" | second-to-hms.pl -r | diff -q - <(echo "432009s 432009s")

