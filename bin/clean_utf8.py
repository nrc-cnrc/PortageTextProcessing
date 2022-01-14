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
# Copyright 2019-2022, Her Majesty in Right of Canada /
# Copyright 2019-2022, Sa Majeste la Reine du Chef du Canada

import click
import os
import re
import sys

from argparse import ArgumentParser
from typing import (
        List,
        Union,
        )
from unicodedata import normalize

try:
    import regex
    regex_available = True
except:
    #print("Failed to import regex to filter out Extended Control characters.", file=sys.stderr)
    #print("Consider `pip install --user regex`", file=sys.stderr)
    regex_available = False


from portage_utils import open



class CleanUTF8:
    """
    Clean up spaces, control characters, hyphen and such in utf8 corpora.
    """
    def __init__(self,
            wide_punct: bool=True,
            phrase_table: bool=False,
            extended_crtl_character_filtering: bool=False,
            normalization_type: str=None,
            ):
       """
       wide_punct: Substitute fullwidth punctuation for their equivalent in ascii.
       phrase_table: Escapes phrase table entry separator " ||| " for " ___|||___ "
       extended_crtl_character_filtering: filter out all unicode characters and not just the ascii control characters.
       normalization_type: perform unicode normalization ( None, "NFD", "NFC", "NFKD", "NFKC" )
       """
       self.wide_punct = wide_punct
       self.phrase_table = phrase_table
       self.normalization_type = normalization_type

       self.re_hyphens = re.compile('[\u001E\u00AD\u2011]')
       self.re_dhyphens = re.compile('\x1F')
       self.re_space = re.compile('[\u2060\uFEFF\u00A0\u2007\u202F\u2028\u2029]')
       self.re_ctrl = re.compile('[\x01-\x09\x0B\x0C\x0E-\x1D\x7F]')
       self.re_crlf = re.compile('\x0D$')
       self.re_phrase_table = re.compile('(^| )\|\|\|(?= |$)')
       self.re_wide = re.compile('([，。：）（；？﹗．﹪﹡﹟])')
       self.re_mspace = re.compile('\s+')   # \s => [ \t\n\r\f\v]

       self.re_ctrl_extended = None
       if extended_crtl_character_filtering:
           if not regex_available:
               assert "Can't perform unicode extended control character filtering since regex is not installed."
           self.re_ctrl_extended = regex.compile(r'\p{C}')

    def __call__(self, text: Union[str, List[str]]) -> Union[str, List[str]]:
       """
       Apply filters to either a string or a list of string.
       """
       if isinstance(text, list):
          return self.clean_list(text)
       else:
          return self.clean_line(text)

    def clean_list(self, list_of_lines: List[str]) -> List[str]:
       """
       Apply filters to either a list of string.
       """
       assert(isinstance(list_of_lines, list))
       return [self.clean_line(line) for line in list_of_lines]

    def clean_line(self, line: str) -> str:
        """
        Apply filters to either a string.
        """
        assert(isinstance(line, str))
        line = line.rstrip()

        if self.normalization_type is not None:
            line = normalize(self.normalization_type, line)

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

        if self.re_ctrl_extended is not None:
            line = self.re_ctrl_extended.sub('', line)

        return line


def progress(*args):
   """
   A simple progress report.
   """
   print('\r', *args, sep='', end='', file=sys.stderr)



@click.command()
@click.option(
        "-v",
       "--verbose",
       "verbose",
       is_flag=True,
       default=False,
       show_default=True,
       help="Display progress")
@click.option(
       "--phrase-table",
       "phrase_table",
       is_flag=True,
       default=False,
       show_default=True,
       help="Handle ||| (Portage phrase-table separator)")
@click.option(
       "--wide-punct",
       "wide_punct",
       is_flag=True,
       default=False,
       show_default=True,
       help="Handle wide punctuation")
@click.option(
       "-x",
       "--extended",
       "extended_crtl_character_filtering",
       is_flag=True,
       default=False,
       show_default=True,
       help="Filter out all unicode Control Characters")
@click.option(
       "-n",
       "--normalize",
       "normalization_type",
       type=click.Choice(("NFD", "NFC", "NFKD", "NFKC"), case_sensitive=False),
       default=None,
       help="Apply unicode normalization")
@click.argument('infile', default='-', type=str)
@click.argument('outfile', default='-', type=str)
def main(
        infile: str,
        outfile: str,
        phrase_table: bool,
        wide_punct: bool,
        extended_crtl_character_filtering: bool,
        normalization_type: str,
        verbose: bool,
        ):
   """
   Clean-up / normalize UTF8 text

   clean_utf8 [options] [infile [outfile]]
   """
   clean = CleanUTF8(
           wide_punct=wide_punct,
           phrase_table=phrase_table,
           extended_crtl_character_filtering=extended_crtl_character_filtering,
           normalization_type=normalization_type,
           )

   with open(str(infile), mode='r', encoding='UTF-8') as cin, open(str(outfile), mode='w', encoding='UTF-8') as cout:
       cin = map(str.strip, cin)
       for count, line in enumerate(cin, 1):
           if verbose and count % 1000 == 0:
               progress(f"[{count} lines...]")
           print(clean(line), file=cout)





if __name__ == '__main__':
   main()
