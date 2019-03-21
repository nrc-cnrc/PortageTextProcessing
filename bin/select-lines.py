#!/usr/bin/env python
# coding=utf-8

# @file select-lines.py
# @brief Select a set of lines by index from a file. 
# 
# @author Darlene Stewart
# 
# Traitement multilingue de textes / Multilingual Text Processing
# Centre de recherche en technologies numériques / Digital Technologies Research Centre
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2018, Sa Majeste la Reine du Chef du Canada /
# Copyright 2018, Her Majesty in Right of Canada

from __future__ import print_function, unicode_literals, division, absolute_import

import time
start_time = time.time()

import sys
import codecs
import re
from argparse import ArgumentParser, RawDescriptionHelpFormatter
import os
import os.path

# If this script is run from within src/ rather than from the installed bin
# directory, we add src/utils to the Python module include path (sys.path).
if sys.argv[0] not in ('', '-c'):
    bin_path = os.path.dirname(sys.argv[0])
    if os.path.basename(bin_path) != "bin":
        sys.path.insert(1, os.path.normpath(os.path.join(bin_path, "..", "utils")))

from portage_utils import *


def get_args():
   """Command line argument processing."""

   usage = "select-lines.py [options] indexfile [infile [outfile]]"
   help = """
   Select a set of lines by index from a file.
   
   indexfile contains 1-based integer indicies of lines to be extracted.
   indexfile is assumed to be sorted.
   """
   
   parser = ArgumentParser(usage=usage, description=help, 
                           formatter_class=RawDescriptionHelpFormatter, add_help=False)
   parser.add_argument("-h", "-help", "--help", action=HelpAction)
   parser.add_argument("-v", "--verbose", action=VerboseAction)
   parser.add_argument("-d", "--debug", action=DebugAction)
   parser.add_argument("-a", "--alignment-column", dest="alignment_column", default=0, type=int,
                       help="indexfile is an alignment info file from ssal -a; process given column: 1 or 2")
   
   parser.add_argument("indexfile", type=open, help="sorted index file")
   
   parser.add_argument("infile", nargs='?', type=open, default=sys.stdin,
                       help="input file [sys.stdin]")
   
   parser.add_argument("outfile", nargs='?', type=lambda f: open(f,'w'), default=sys.stdout, 
                       help="output file [sys.stdout]")
   
   cmd_args = parser.parse_args()
      
   return cmd_args


def parse_alignment_line(line, column):
   tokens = line.split()
   try:
      (start,end) = tokens[column-1].split('-', 1)
      start=int(start)
      end=int(end)
   except:
      fatal_error("Invalid alignment info line:", line.strip())
   if end < start:
      fatal_error("Invalid alignment has end<start at:", line.strip())
   return (start,end)


def main():

   printCopyright("select-lines.py", 2018);
   os.environ['PORTAGE_INTERNAL_CALL'] = '1';

   cmd_args = get_args()
   
   encoding = "utf-8"
   try:
      codecs.lookup(encoding)
   except LookupError:
      fatal_error("utf-8 codec not found.")

   indexfile = codecs.getreader(encoding)(cmd_args.indexfile)
   infile = codecs.getreader(encoding)(cmd_args.infile)
   outfile = codecs.getwriter(encoding)(cmd_args.outfile)
   # The following allows stderr to handle non-ascii characters:
   sys.stderr = codecs.getwriter(encoding)(sys.stderr)

   line_number = 0

   if cmd_args.alignment_column == 0:
      index_line = indexfile.readline()
      if index_line:
         index = int(index_line)

      for in_line in infile:
         if not index_line:
            break
         line_number += 1
         if line_number == index:
            print(in_line, file=outfile, end='')
            index_line = indexfile.readline()
            if index_line:
               index = int(index_line)
         elif line_number > index:
            fatal_error("Index file out of sort order at index:", index, "input line:", line_number)

      if index_line:
         fatal_error("Out of input before end of index file at index:", index)

   elif cmd_args.alignment_column == 1 or cmd_args.alignment_column == 2:
      col = cmd_args.alignment_column
      index_line = indexfile.readline()
      if index_line:
         (start, end) = parse_alignment_line(index_line, col)
         if start < 0:
            fatal_error("Alignment file specifies negative line number at:", index_line.strip())

      for in_line in infile:
         if not index_line:
            break
         if line_number >= start and line_number < end:
            print(in_line.strip('\n'), file=outfile, end='')
            if line_number+1 < end:
               print(' ', file=outfile, end='')

         line_number += 1
         while line_number == end:
            print('', file=outfile, end='\n')
            index_line = indexfile.readline()
            if index_line:
               (start, end) = parse_alignment_line(index_line, col)
               if start < line_number:
                  fatal_error("Alignment file out of order at:", index_line.strip())
            else:
               break

      if index_line:
         fatal_error("Out of input before end of alignment index file at:", index_line.strip())

   else:
      fatal_error("invalid -a/--alignment-column value: use 1 or 2 (or 0 for none).")

   indexfile.close()
   infile.close()
   outfile.close()

if __name__ == '__main__':
    main()
