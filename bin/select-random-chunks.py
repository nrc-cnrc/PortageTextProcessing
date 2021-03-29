#!/usr/bin/env python3
# coding=utf-8

# @file select-random-chunks.py
# @brief Select a number of random chunks of a specified size producing an index file.
#
# @author Darlene Stewart
#
# Traitement multilingue de textes / Multilingual Text Processing
# Centre de recherche en technologies numériques / Digital Technologies Research Centre
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2020, Sa Majeste la Reine du Chef du Canada /
# Copyright 2020, Her Majesty in Right of Canada

from __future__ import print_function, unicode_literals, division, absolute_import

# import time
# from random import randrange
# start_time = time.time()

import sys
# import codecs
# import re
from argparse import ArgumentParser, RawDescriptionHelpFormatter
import os
import os.path
import subprocess
import random

# If this script is run from within src/ rather than from the installed bin
# directory, we add src/utils to the Python module include path (sys.path).
if sys.argv[0] not in ('', '-c'):
    bin_path = os.path.dirname(sys.argv[0])
    if os.path.basename(bin_path) != "bin":
        sys.path.insert(1, os.path.normpath(os.path.join(bin_path, "..", "utils")))

from portage_utils import *


def get_args():
   """Command line argument processing."""

#    usage = "select-random-chunks.py [options] [outfile]"
   help = """
   Select a number of random chunks of a specified size producing an index file.

   The generated indicies are 1-based.

   outfile can be used as an indexfile for select-lines.py.
   """

#    parser = ArgumentParser(usage=usage, description=help, add_help=False,
#                            formatter_class=RawDescriptionHelpFormatter)
   parser = ArgumentParser(description=help, add_help=False,
                           formatter_class=RawDescriptionHelpFormatter)
   parser.add_argument("-h", "-help", "--help", action=HelpAction)
   parser.add_argument("-v", "--verbose", action=VerboseAction)
   parser.add_argument("-d", "--debug", action=DebugAction)

   parser.add_argument("-c", "--chunk-size", dest="chunk_size", default=1, type=int,
                       help="Size of chunks to select [%(default)s]")

   group1 = parser.add_mutually_exclusive_group(required=True)
   group1.add_argument("-n", "--number-chunks", dest="num_chunks", type=int,
                       help="Number of chunks to select")
   group1.add_argument("-o", "--outsize", dest="output_size", type=int,
                       help="Target size for outfile [num_chunks * chunk_size]")

   group2 = parser.add_mutually_exclusive_group(required=True)
   group2.add_argument("-m", "--max-index", dest="max_index", type=int,
                       help="Number of chunks to select [%(default)s]")
   group2.add_argument("-f", "--infile", dest="infile", type=str,
                       help="File whose size determines max_index")

   parser.add_argument("-s", "--seed", dest="seed", default=2020, type=int,
                       help="Seed for random number generator. [%(default)s]")

   parser.add_argument("outfile", nargs='?', type=lambda f: open(f,'w'), default=sys.stdout,
                       help="output file [sys.stdout]")

   cmd_args = parser.parse_args()

   return cmd_args


def file_size( filename ):
   result = subprocess.run(['wc', '-l', filename], stdout=subprocess.PIPE)
   if result.returncode != 0:
      fatal_error("Cannot access (using wc -l):", filename)
   return int(result.stdout.decode().split()[0])


def main():

   printCopyright("select-random-chunks.py", 2020);
   os.environ['PORTAGE_INTERNAL_CALL'] = '1';

   cmd_args = get_args()

   random.seed(cmd_args.seed)

   if cmd_args.output_size is not None:
      num_chunks = cmd_args.output_size // cmd_args.chunk_size
   else:
      num_chunks = cmd_args.num_chunks

   if cmd_args.infile is not None:
      max_index = file_size(cmd_args.infile)
   else:
      max_index = cmd_args.max_index

   verbose("seed:", cmd_args.seed)
   verbose("chunk_size:", cmd_args.chunk_size)
   if cmd_args.output_size is not None:
      verbose("output_size: ", cmd_args.output_size)
   verbose("num_chunks:", num_chunks)
   if cmd_args.infile is not None:
      verbose("infile:", cmd_args.infile)
   verbose("max_index: ", max_index)
   verbose("outfile: ", cmd_args.outfile)

   if num_chunks * cmd_args.chunk_size > max_index:
      fatal_error("num_chunks * chunk_size (", num_chunks * cmd_args.chunk_size,
                  ") must be <= max_index (", max_index, ").")

   max_range = max_index - (cmd_args.chunk_size-1) + 1
   chunks = sorted(random.sample(range(1, max_range, cmd_args.chunk_size), num_chunks))

   for index in chunks:
      for i in range(cmd_args.chunk_size):
         print(index+i, file=cmd_args.outfile)

   cmd_args.outfile.close()

if __name__ == '__main__':
    main()
