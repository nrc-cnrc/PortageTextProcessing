#!/usr/bin/env python

# $Id$

# lines.py - extract the given lines from a file
#
# PROGRAMMER: Nicola Ueffing
#
# COMMENTS:
#
# Technologies langagieres interactives / Interactive Language Technologies
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2008, Sa Majeste la Reine du Chef du Canada /
# Copyright 2008, Her Majesty in Right of Canada

import sys, math, string, gzip

if len(sys.argv)!=3:
    sys.stderr.write("Usage: %s  \n\
    <file containing line numbers>  <file containing text (can be gzipped)>\n\n\
    Extracts lines specified in first file from second file.\n\
    Line numbers have to start with 1 (not 0) and may contain repititions.\n\
    " % (sys.argv[0])))
    sys.exit(1)

### Read arguments
numFile = open(sys.argv[1])
txtFileName = sys.argv[2]
if txtFileName[-3:] == '.gz':
    txtFile = gzip.open(txtFileName)
else:
    txtFile = open(txtFileName)

### Read line numbers
nums = []
line = numFile.readline()
while line!="":
    nums.append(int(string.strip(line)))    
    line = numFile.readline()
nums.sort()

    ### read text and extract lines
    n1 = 1
    n2 = nums.pop(0)
    line = txtFile.readline()
    while (line!="") & (len(nums)>0):
        #print "%",n1,n2
        while (n1 == n2) & (len(nums)>0):
            sys.stderr.write("Line %i: %s\n" % (n2,line))
            print line,
            n2 = nums.pop(0)
        #print "#",n1,line,
        n1 = n1+1
        line = txtFile.readline()

    while (line!="") & (n1<n2):
        line = txtFile.readline()
        n1 = n1+1
    print line,
