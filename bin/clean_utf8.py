#!/usr/bin/env python3
# coding=utf-8

# @file clean_utf8.py
# @brief Clean up spaces, control characters, hyphen and such in utf8 corpora
#
# @author Michel Simard / Samuel Larkin -- adopted from Perl code by Eric Joanis
#
# Multilingual Text Processing / Traitement multilingue de textes
# Digital Technologies Research Centre / Centre de recherche en technologies numériques
# National Research Council Canada / Conseil national de recherches Canada
# Copyright 2019, Her Majesty in Right of Canada /
# Copyright 2019, Sa Majeste la Reine du Chef du Canada

import builtins
import os
import re
import string
import sys
from argparse import ArgumentParser
from typing import (
        List,
        Union,
        )

# If this script is run from within src/ rather than from the installed bin
# directory, we add src/utils to the Python module include path (sys.path)
# to arrange that portage_utils will be imported from src/utils.
if sys.argv[0] not in ('', '-c'):
   bin_path = os.path.dirname(sys.argv[0])
   if os.path.basename(bin_path) != "bin":
      sys.path.insert(1, os.path.normpath(os.path.join(bin_path, "..", "utils")))

from portage_utils import *


class CleanUTF8:
    def __init__(self,
            wide_punct: bool=True,
            phrase_table: bool=False,
            ):
       self.wide_punct = wide_punct
       self.phrase_table = phrase_table
       self.re_hyphens = re.compile('[\u001E\u00AD\u2011]')
       self.re_dhyphens = re.compile('\x1F')
       self.re_space = re.compile('[\u2060\uFEFF\u00A0\u2007\u202F\u2028\u2029]')
       self.re_ctrl = re.compile('[\x01-\x09\x0B\x0C\x0E-\x1D\x7F]')
       self.re_crlf = re.compile('\x0D$')
       self.re_phrase_table = re.compile('(^| )\|\|\|(?= |$)')
       self.re_wide = re.compile('([，。：）（；？﹗．﹪﹡﹟])')
       self.re_mspace = re.compile('\s+')   # \s => [ \t\n\r\f\v]

    def __call__(self, text: Union[str, List[str]]) -> Union[str, List[str]]:
       if isinstance(text, list):
          return self.clean_list(text)
       else:
          return self.clean_line(text)

    def clean_list(self, list_of_lines: List[str]) -> List[str]:
       assert(isinstance(list_of_lines, list))
       return [self.clean_line(line) for line in list_of_lines]

    def clean_line(self, line: str) -> str:
        assert(isinstance(line, str))
        line = line.rstrip()

   # Convert various non-breaking hyphen encodings to -: \xAD and \x1E for MS
   # Word, \x2011 for Unicode.  Warning: for html documents, \xAD should be
   # stripped, rather than converted to -.
        line = self.re_hyphens.sub('-', line)

   # Strip out the MS Word discretional hyphen, \x1F
        line = self.re_dhyphens.sub('', line)

   # Replace various special purpose spaces by regular spaces:
   # U+2060: Word joiner / WJ, "a zero width non-breaking space (only) intended
   #         for disambiguation of functions for byte order mark" (Unicode standard);
   #         typically used to join separate words without displaying a space, but
   #         for Portage separate words do need a space.
   # U+FEFF: BOM, now called zero-width no-break space, used more-or-less like WJ
   #         (deprecated use) or left when concatenating files that have the BOM;
   #         in either case, we want to tokenize on it, so we turn it into a space.
   # U+A0:   The canonical non-break space
   # U+2007: Figure space, has the width of a digit
   # U+202F: Narrow no-break space (e.g., before : ; ! ? » and after « in French)
   # U+2028: Line Separator (LS)
   # U+2029: Paragraph Separator (PS)
   #         LS and PS ought to be turned into a newline, but in Portage we define
   #         \n as the newline, sometimes with user-defined semantics, and this
   #         script gets applied to line-aligned text, so the only legal thing we can
   #         do here is map them to spaces.
        line = self.re_space.sub(' ', line)

   # replace remaining control characters by spaces.
        line = self.re_ctrl.sub(' ', line)

   # equivalent to crlf2lf.sh: convert DOS newlines to Linux ones
        line = self.re_crlf.sub('', line)

   # If ||| appears stand-alone in text, that causes problems with Portage
        if (self.phrase_table):
            line = self.re_phrase_table.sub(' ___|||___', line)

   # Basic wide punctuation mapping
        if (self.wide_punct):
            line = self.re_wide.sub(' \g<1> ', line)
            line = line.translate(str.maketrans('，。：）（；？﹗．﹪﹡﹟', ',.:)(;?!.%*#'))

   # Collapse multiple spaces to a single space
        line = self.re_mspace.sub(' ', line)
        line = line.strip()

        return line


def progress(*args):
   verbose('\r', *args, sep='', end='')

def get_args():
   """Command line argument processing."""

   usage="clean_utf8 [options] [infile [outfile]]"
   help="""
   Clean-up / normalize UTF8 text
   """

   # Use the argparse module, not the deprecated optparse module.
   parser = ArgumentParser(usage=usage, description=help, add_help=False)

   # Use our standard help, verbose and debug support.
   parser.add_argument("-h", "-help", "--help", action=HelpAction)
   parser.add_argument("-v", "--verbose", action=VerboseAction)
   parser.add_argument("-d", "--debug", action=DebugAction)

   parser.add_argument(
           "--phrase-table",
           dest="phrase_table",
           action='store_true',
           default=False,
           help="Handle ||| (Portage phrase-table separator) [%(default)s]")
   parser.add_argument(
           "--wide-punct",
           dest="wide_punct",
           action='store_true',
           default=False,
           help="Handle wide punctuation [%(default)s]")

   # The following use the nrc_utils version of open to open files.
   parser.add_argument(
           "infile",
           nargs='?',
           type=lambda f: open(f, 'r'),
           default="-",
           help="input file [sys.stdin]")
   parser.add_argument(
           "outfile",
           nargs='?',
           type=lambda f: open(f, 'w'),
           default="-",
           help="output file [sys.stdout]")

   cmd_args = parser.parse_args()

   return cmd_args

def main():
   cmd_args = get_args()

   clean = CleanUTF8(wide_punct = cmd_args.wide_punct, phrase_table = cmd_args.phrase_table)

   for count, line in enumerate(cmd_args.infile, 1):
       if count % 1000 == 0:
           progress("[{} lines...]".format(count))
       print(clean(line), file=cmd_args.outfile)

   cmd_args.infile.close()
   cmd_args.outfile.close()

if __name__ == '__main__':
   main()
