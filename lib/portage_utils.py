#!/usr/bin/env python
# coding=utf-8

# @file portage_utils.py
# @brief Useful common Python classes and functions
#
# @author Darlene Stewart & Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2011, Sa Majeste la Reine du Chef du Canada /
# Copyright 2011, Her Majesty in Right of Canada

from __future__ import print_function, unicode_literals, division, absolute_import

import sys
import argparse
import re
import __builtin__
from subprocess import Popen, PIPE

__all__ = ["printCopyright",
           "HelpAction", "VerboseAction", "VerboseMultiAction", "DebugAction",
           "set_debug","set_verbose",
           "error", "fatal_error", "warn", "info", "debug", "verbose",
           "open", "split",
          ]

current_year = 2020

def printCopyright(program_name, start_year):
   """Print the standard NRC Copyright notice.

   The Crown Copyright will be asserted for start_year to latest release year.

   program_name: name of the program
   start_year: the first year of Copyright for the program;
   """
   # Just like in sh_utils.sh, we don't actually bother with the Copyright
   # statement within Portage.
   pass


class HelpAction(argparse.Action):
   """argparse action class for displaying the help message to stderr.
   e.g: parser.add_argument("-h", "-help", "--help", action=HelpAction)
   """
   def __init__(self, option_strings, dest, help="print this help message to stderr and exit"):
      super(HelpAction, self).__init__(option_strings, dest, nargs=0,
                                       default=argparse.SUPPRESS,
                                       required=False, help=help)
   def __call__(self, parser, namespace, values, option_string=None):
      parser.print_help(file=sys.stderr)
      exit()

class VerboseAction(argparse.Action):
   """argparse action class for turning on verbose output.
   e.g: parser.add_argument("-v", "--verbose", action=VerboseAction)
   """
   def __init__(self, option_strings, dest, help="print verbose output to stderr [False]"):
      super(VerboseAction, self).__init__(option_strings, dest, nargs=0,
                                          const=True, default=False,
                                          required=False, help=help)

   def __call__(self, parser, namespace, values, option_string=None):
      setattr(namespace, self.dest, True)
      set_verbose(True)

class VerboseMultiAction(argparse.Action):
   """argparse action class increase level of verbosity in output.
   e.g: parser.add_argument("-v", "--verbose", action=VerboseMultiAction)
   Using multiple flags increase the verbosity multiple levels.
   """
   def __init__(self, option_strings, dest,
                help="increase level of verbosity output to stderr [0]"):
      super(VerboseMultiAction, self).__init__(option_strings, dest, nargs=0,
                                               type=int, default=0,
                                               required=False, help=help)

   def __call__(self, parser, namespace, values, option_string=None):
      setattr(namespace, self.dest, getattr(namespace, self.dest, 0) + 1)
      set_verbose(True)

class DebugAction(argparse.Action):
   """argparse action class for turning on verbose output.
   e.g: parser.add_argument("-d", "--debug", action=DebugAction)
   """
   def __init__(self, option_strings, dest, help="print debug output to stderr [False]"):
      super(DebugAction, self).__init__(option_strings, dest, nargs=0,
                                        const=True, default=False,
                                        required=False, help=help)

   def __call__(self, parser, namespace, values, option_string=None):
      setattr(namespace, self.dest, True)
      set_debug(True)


verbose_flag = False
debug_flag = False

def set_debug(flag):
   """Set value of the debug flag to control printing of debug messages."""
   global debug_flag
   debug_flag = flag

def set_verbose(flag):
   """Set value of the verbose flag to control printing of debug messages."""
   global verbose_flag
   verbose_flag = flag

def error(*args, **kwargs):
   """Print an error message to stderr."""
   print("Error:", *args, file=sys.stderr, **kwargs)
   return

def fatal_error(*args, **kwargs):
   """Print a fatal error message to stderr and exit with code 1."""
   print("Fatal error:", *args, file=sys.stderr, **kwargs)
   sys.exit(1)

def warn(*args, **kwargs):
   """Print an warning message to stderr."""
   print("Warning:", *args, file=sys.stderr, **kwargs)
   return

def info(*args, **kwargs):
   """Print information output to stderr."""
   print(*args, file=sys.stderr, **kwargs)

def debug(*args, **kwargs):
   """Print debug output to stderr if debug_flag (-d) is set."""
   if debug_flag:
      print("Debug:", *args, file=sys.stderr, **kwargs)

def verbose(*args, **kwargs):
   """Print verbose output to stderr if verbose_flag (-v) or debug_flag (-d) is set."""
   if verbose_flag or debug_flag:
      print(*args, file=sys.stderr, **kwargs)

def open(filename, mode='r', quiet=True):
   """Transparently open files that are stdin, stdout, plain text, compressed or pipes.

   examples: open("-")
      open("file.txt")
      open("file.gz")
      open("zcat file.gz | grep a |")

   filename: name of the file to open
   mode: open mode
   quiet:  suppress "zcat: stdout: Broken pipe" messages.
   return: file handle to the open file.
   """
   filename.strip()
   #debug("open: ", filename, " in ", mode, " mode")
   if len(filename) is 0:
      fatal_error("You must provide a filename")

   if filename == "-":
      if mode == 'r':
         theFile = sys.stdin
      elif mode == 'w':
         theFile = sys.stdout
      else:
         fatal_error("Unsupported mode.")
   elif filename.endswith('|'):
      theFile = Popen(filename[:-1], shell=True, stdout=PIPE).stdout
   elif filename.startswith('|'):
      theFile = Popen(filename[1:], shell=True, stdin=PIPE).stdin
   elif filename.endswith(".gz"):
      #theFile = gzip.open(filename, mode+'b')
      if mode == 'r':
         if quiet:
            theFile = Popen(["zcat", "-f", filename], stdout=PIPE, stderr=open('/dev/null', 'w')).stdout
         else:
            theFile = Popen(["zcat", "-f", filename], stdout=PIPE).stdout
      elif mode == 'w':
         internal_file = __builtin__.open(filename, mode)
         theFile = Popen(["gzip"], close_fds=True, stdin=PIPE, stdout=internal_file).stdin
      else:
         fatal_error("Unsupported mode for gz files.")
   else:
      theFile = __builtin__.open(filename, mode)

   return theFile

# Regular expression to match whitespace the same way that split() in
# str_utils.cc does, i.e. sequence of spaces, tabs, and/or newlines.
split_re = re.compile('[ \t\n]+')

def split(s):
   """Split s into tokens the same way split() in str_utils.cc does, i.e.
   using any sequence of spaces, tabs, and/or newlines as a delimiter, and
   ignoring leading and trailing whitespace.

   s: string to be split into token
   returns: list of string tokens
   """
   ss = s.strip(' \t\n');
   return [] if len(ss) is 0 else split_re.split(ss)


if __name__ == '__main__':
   pass
