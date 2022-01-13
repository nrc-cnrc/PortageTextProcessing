#!/usr/bin/env python3

# @file strip-parallel-blank-lines.py
# @brief Strip blank lines in parallel from one or more line-aligned files:
# strip if EITHER of the first two files contains a blank line.
#
# @author George Foster
#
# COMMENTS:
#
# George Foster
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2007, Sa Majeste la Reine du Chef du Canada /
# Copyright 2007, Her Majesty in Right of Canada

import sys
import re

# portage_utils provides a bunch of useful and handy functions, including:
#   HelpAction, VerboseAction, DebugAction (helpers for argument processing)
#   printCopyright
#   info, verbose, debug, warn, error, fatal_error
#   open (transparently open stdin, stdout, plain text files, compressed files or pipes)
from portage_utils import *


help = """
strip-parallel-blank-lines.py [-r] file1 [file2 file3...]

Strip blank lines in parallel from one or more line-aligned files: strip if
EITHER of the first two files contains a blank line.  Write output to
<file*>.no-blanks. If <file3> and subsequent files are provided, they are
stripped in parallel, but are not themselves checked for blank lines.

Options:
-r   Replace blank lines with a '.' rather than stripping them. This tests ONLY
     the first file for a blank line, and iff one is found replaces it and any
     aligned blank lines with a '.'.

"""

args = sys.argv[1:]

replace = False
if len(args) > 1 and args[0] == "-r":
    replace = True
    args = args[1:]

if len(args) < 1 or args[0] == "-h":
    sys.stderr.write(help);
    sys.exit(1)

blankline = re.compile("^\s*$")

ifiles = []
ofiles = []
for file in args:
    ifiles.append(open(file, "rt", encoding="utf8"))
    ofiles.append(open(re.sub(r'(.gz$|$)', r'.no-blanks\g<1>', file, count=1), "wt"))

second = 1
if len(ifiles) < 2: second = 0          # only use file1 if only file1 given

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
        if not blankline.match(lines[0]) and not blankline.match(lines[second]):
            for i in range(0,len(ifiles)):
                ofiles[i].write(lines[i])

for file in ifiles:
    if (file.readline() != ""):
        sys.stderr.write("file " + file.name + " too long!\n");
        sys.exit(1)
