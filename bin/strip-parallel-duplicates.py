#!/usr/bin/env python2
# $Id: prog.py,v 1.3 2012/05/15 20:36:59 joanise Exp $

# @file strip-parallel-duplicates.py
# @brief Strip lines in parallel from multiple line-aligned files if the lines
# from the compared files are identical.
#
# @author Darlene Stewart
#
# Technologies langagieres interactives / Interactive Language Technologies
# Tech. de l'information et des communications / Information and Communications Tech.
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2012, Sa Majeste la Reine du Chef du Canada /
# Copyright 2012, Her Majesty in Right of Canada

from __future__ import print_function, unicode_literals, division, absolute_import

import sys
import os.path
from argparse import ArgumentParser, FileType

# If this script is run from within src/ rather than from the installed bin
# directory, we add src/utils to the Python module include path (sys.path)
# to arrange that portage_utils will be imported from src/utils.
if sys.argv[0] not in ('', '-c'):
   bin_path = os.path.dirname(sys.argv[0])
   if os.path.basename(bin_path) != "bin":
      sys.path.insert(1, os.path.normpath(os.path.join(bin_path, "..", "utils")))

from portage_utils import *


def get_args():
   """Command line argument processing."""

   usage="strip-parallel-duplicates.py [options] file1 file2 [file3 ...]"
   help="""
   Strip lines in parallel from multiple line-aligned files if the lines
   from the compared files are identical. Write output to <file*><ext>, where
   <ext> defaults to .dedup.
   If <fileN> and subsequent files are provided, where N is > the number of
   files to compare, they are stripped in parallel, but don't participate in
   the identical line comparison.
   """

   # Use the argparse module, not the deprecated optparse module.
   parser = ArgumentParser(usage=usage, description=help, add_help=False)

   # Use our standard help, verbose and debug support.
   parser.add_argument("-h", "-help", "--help", action=HelpAction)
   parser.add_argument("-v", "--verbose", action=VerboseAction)
   parser.add_argument("-d", "--debug", action=DebugAction)

   parser.add_argument("-c", dest="compare", type=int, default=2,
                       help="number of files to compare [%(default)s]")
   parser.add_argument("-ext", dest="ext", type=str, default=".dedup",
                       help="extension for output files [%(default)s]")

   parser.add_argument("in_files", nargs="*", type=FileType('r'),
                       help="files to strip lines from in parallel")

   cmd_args = parser.parse_args()
   if cmd_args.compare < 2:
      fatal_error("Number of files to compare (-c) must be >= 2: ", cmd_args.compare)
   if len(cmd_args.in_files) < cmd_args.compare:
      fatal_error(cmd_args.compare, "files required for comparison.")

   return cmd_args

def main():
   printCopyright("strip-parallel-duplicates.py", 2012);

   cmd_args = get_args()
   out_files = tuple(open(f.name+cmd_args.ext, 'w') for f in cmd_args.in_files)

   eof = False
   while True:
      lines = []
      for f in cmd_args.in_files:
         lines.append(f.readline())
         if len(lines[-1]) is 0: eof = True
      if eof: break
      for i in range(1, cmd_args.compare):
         if lines[i] != lines[0]: identical = False; break
      else:
         identical = True
      if not identical:
         for i in range(len(lines)):
            print(lines[i], file=out_files[i], end='')

   for i in range(len(cmd_args.in_files)):
      if len(lines[i]) != 0:
         fatal_error("File", cmd_args.in_files[i].name,
                     "contains more lines than some other files.")

if __name__ == '__main__':
   main()
