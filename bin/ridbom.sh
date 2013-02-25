#!/bin/bash
#
# @file ridbom.sh
# @brief Rid UTF-8 file from BOM (Byte-Order Marker)
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

## 
## Usage: crlf2lf.sh [FILES ...]
## 
## Rid UTF-8 FILES from BOM (Byte-Order Marker), stdin if no files are
## specified.  Output goes to stdout.
##

if [ "$1" == "-help" -o "$1" == "-h" ]; then
    cat $0 | grep "^##" | cut -c4-
    exit 1
fi

sed --separate -e '1 s/^\xef\xbb\xbf//' $*
