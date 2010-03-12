#!/bin/bash
#############################################################
#
# @file crlf2lf.sh
# @brief Convert CRLF (DOS-style) line endings to LF (UNIX-style).
#
# @author Michel Simard
#
# COMMENTS:
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2010, Conseil national de recherches du Canada /
# Copyright 2010, National Research Council of Canada
#############################################################

## 
## Usage: crlf2lf.sh [FILES ...]
## 
## Convert CRLF (DOS-style) line endings to LF (UNIX-style) in FILES,
## stdin if no files are specified.  Output goes to stdout.
##

if [ "$1" == "-help" -o "$1" == "-h" ]; then
    cat $0 | grep "^##" | cut -c4-
    exit 1
fi

sed -e 's/\x0d$//' $*
