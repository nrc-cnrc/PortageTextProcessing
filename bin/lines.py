#!/usr/bin/env python3

# @file lines.py
# @brief extract the given lines from a file.
#
# @author Nicola Ueffing
#
# COMMENTS:
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2008, Sa Majeste la Reine du Chef du Canada /
# Copyright 2008, Her Majesty in Right of Canada

import gzip
import io
import sys
from portage_utils import open

if len(sys.argv) != 3:
    sys.stderr.write("Usage: lines.py  \n\
    <file containing line numbers>  <file containing text (can be gzipped)>\n\n\
    Extracts lines specified in first file from second file.\n\
    Line numbers have to start with 1 (not 0) and may contain repetitions.\n\
    Output will be sorted by line numbers.\n\
")
    sys.exit(1)

### Read arguments
# We use latin-1 as an arbitrary 8-bit encoding for encoding-agnostic processing
# this works with utf-8, any iso-8859-*, ascii, and every encoding where newline
# is represented as \x0A. Using "utf_8" would make logical sense too, but it
# would be less versatile for this utility that doesn't inspect line contents.
encoding = "latin-1"
numFile = open(sys.argv[1], mode="rt", encoding=encoding)
txtFile = open(sys.argv[2], mode="rt", encoding=encoding)
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding=encoding)

### Read line numbers
nums = sorted([int(line.strip()) for line in numFile])

### read text and extract lines
n1 = 1
n2 = nums.pop(0)
line = txtFile.readline()
done = False
while (line != "") and (not done):
    #print("%",n1,n2)
    while n1 == n2:
        #sys.stderr.write("Line %i: %s\n" % (n2,line))
        #sys.stdout.write(str(line))
        print(line, end='')
        if len(nums) == 0:
            done = True
            break
        n2 = nums.pop(0)
    #print("#", n1, line, end=' ')
    n1 = n1+1
    line = txtFile.readline()
