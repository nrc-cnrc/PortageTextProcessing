#!/bin/bash

# li-sort.sh
# 
# PROGRAMMER: GF
# 
# COMMENTS:
#
# Technologies langagieres interactives / Interactive Language Technologies
# Institut de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2006, Sa Majeste la Reine du Chef du Canada / 
# Copyright 2006, Her Majesty in Right of Canada

if [ $# -gt 0 ] && [ "$1" == "-h" ]; then

cat <<==EOF== >&2
li-sort.sh [-h] [sort args]

Call Unix sort on the given arguments, in a locale-independent way.

==EOF==
exit 1
fi

export LC_ALL=C
exec sort $*
