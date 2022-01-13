#!/usr/bin/env python3

# @file filter-parallel.py
# @brief Filter lines in parallel from multiple line-aligned files according to
# a score in the provided scores file.
#
# @author Darlene Stewart
#
# Technologies langagieres interactives / Interactive Language Technologies
# Tech. de l'information et des communications / Information and Communications Tech.
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2015, Sa Majeste la Reine du Chef du Canada /
# Copyright 2015, Her Majesty in Right of Canada

import sys
import os.path
from argparse import ArgumentParser, FileType, Action

from portage_utils import (
   open,
   printCopyright,
   DebugAction,
   HelpAction,
   VerboseAction,
)


class Op(object):
   none = 0
   gt = 1
   ge = 2
   lt = 3
   le = 4

class OpAction(Action):
   """A custom action is needed to store both the operator and threshold."""
   def __init__(self, option_strings, dest, **kwargs):
      super(OpAction, self).__init__(option_strings, dest, **kwargs)
   def __call__(self, parser, namespace, values, option_string=None):
      setattr(namespace, self.dest, self.const)
      setattr(namespace, self.dest+"_threshold", values)

def get_args():
   """Command line argument processing."""

   usage="filter-parallel.py [options] scores_file in_file1 [in_file2 ...]"
   help="""
   Filter lines in parallel from multiple line-aligned files according to
   a score in the provided <scores_file>, removing those lines whose score fails
   to satisfy a specified threshold test. Write output to <in_file*><ext>, where
   <ext> defaults to .filt. Any number of files can be filtered in parallel.
   All files, including the scores file, must contain the same number of lines.
   """

   # Use the argparse module, not the deprecated optparse module.
   parser = ArgumentParser(usage=usage, description=help, add_help=False)

   # Use our standard help, verbose and debug support.
   parser.add_argument("-h", "-help", "--help", action=HelpAction)
   parser.add_argument("-v", "--verbose", action=VerboseAction)
   parser.add_argument("-d", "--debug", action=DebugAction)

   parser.add_argument("-ext", dest="ext", type=str, default=".filt",
                       help="extension for output files [%(default)s]")

   grp_op = parser.add_argument_group("Threshold operator selection options (one required)")
   ops = grp_op.add_mutually_exclusive_group(required=True)
   ops.add_argument('-gt', dest="op", action=OpAction, const=Op.gt, type=float,
                     metavar="THRESHOLD", help='''Keep if greater than threshold''')
   ops.add_argument('-ge', dest="op", action=OpAction, const=Op.ge, type=float,
                    metavar="THRESHOLD", help='''Keep if greater than or equal to threshold''')
   ops.add_argument('-lt', dest="op", action=OpAction, const=Op.lt, type=float,
                    metavar="THRESHOLD", help='''Keep if less than threshold''')
   ops.add_argument('-le', dest="op", action=OpAction, const=Op.le, type=float,
                    metavar="THRESHOLD", help='''Keep if less than or equal to threshold''')

   parser.add_argument("scores_file", type=FileType('r'),
                       help="files to strip lines from in parallel")

   parser.add_argument("in_files", nargs="+", type=FileType('r'),
                       help="file of scores to use for filtering")

   try:
      cmd_args = parser.parse_args()
   except IOError as e:
      fatal_error("cannot open: '{0}': {1}".format(e.filename, e))

   return cmd_args

def main():
   printCopyright("filter-parallel.py", 2015);

   cmd_args = get_args()
   out_files = tuple(open(f.name+cmd_args.ext, 'w') for f in cmd_args.in_files)

   for score_line in cmd_args.scores_file:
      score = float(score_line)
      lines = []
      for f in cmd_args.in_files:
         lines.append(f.readline())
      if cmd_args.op is Op.gt and score > cmd_args.op_threshold or \
         cmd_args.op is Op.ge and score >= cmd_args.op_threshold or \
         cmd_args.op is Op.lt and score < cmd_args.op_threshold or \
         cmd_args.op is Op.le and score <= cmd_args.op_threshold:
            for i in range(len(lines)):
               print(lines[i], file=out_files[i], end='')

   for f in cmd_args.in_files:
      if len(f.readline()) != 0:
         fatal_error("File", f.name, "contains more lines than some other files.")

if __name__ == '__main__':
   main()
