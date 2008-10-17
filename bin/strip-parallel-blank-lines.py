#!/usr/bin/env python

# strip-parallel-blank-lines.py
# 
# PROGRAMMER: George Foster
# 
# COMMENTS: 
#
# George Foster
# Technologies langagieres interactives / Interactive Language Technologies
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2007, Sa Majeste la Reine du Chef du Canada /
# Copyright 2007, Her Majesty in Right of Canada

import sys
import re

help = """
strip-parallel-blank-lines.py [-r] file1 file2 [file3...]

Strip blank lines in parallel from two line-aligned files: strip if EITHER file
contains a blank line.  Write output to <file1>.no-blanks. If <file3> and subsequent
files are provided, they are stripped in parallel, but are not themselves checked
for blank lines.

Options:
-r   For any set of parallel lines in which the first (ONLY!) is blank, replace
     any blank lines with a '.'. NOTE the change of matching criterion with
     this option! 

"""

args = sys.argv[1:]

replace = False
if len(args) > 1 and args[0] == "-r":
    replace = True
    args = args[1:]

if len(args) < 2:
    sys.stderr.write(help);
    sys.exit(1)
    
blankline = re.compile("^\s*$")

ifiles = []
ofiles = []
for file in args:
    ifiles.append(open(file, "r"))
    ofiles.append(open(file+".no-blanks", "w"))

lines = [""] * len(ifiles)
for lines[0] in ifiles[0]:

    for i in range(1, len(ifiles)):
        lines[i] = ifiles[i].readline()
        if (lines[i] == ""):
            sys.stderr.write("file " + ifiles[i].name + " too short!\n")
            sys.exit(1)

    if replace:
        rep = blankline.match(lines[0])
        for i in range(0,len(ifiles)):
            if rep and blankline.match(lines[i]): lines[i] = ".\n"
            ofiles[i].write(lines[i])
    else:
        if not blankline.match(lines[0]) and not blankline.match(lines[1]):
            for i in range(0,len(ifiles)):
                ofiles[i].write(lines[i])

for file in ifiles:
    if (file.readline() != ""):
        sys.stderr.write("file " + file.name + " too long!\n");
        sys.exit(1)
