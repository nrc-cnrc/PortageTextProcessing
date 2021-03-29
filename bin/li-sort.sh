#!/bin/bash

# @file li-sort.sh
# @brief locale-independent sort.
#
# @author George Foster
#
# COMMENTS:
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2007, Sa Majeste la Reine du Chef du Canada /
# Copyright 2007, Her Majesty in Right of Canada

# Include NRC's bash library.
BIN=`dirname $0`
if [[ ! -r $BIN/sh_utils.sh ]]; then
   # assume executing from src/* directory
   BIN="$BIN/../utils"
fi
source $BIN/sh_utils.sh || { echo "Error: Unable to source sh_utils.sh" >&2; exit 1; }


[[ $PORTAGE_INTERNAL_CALL ]] ||
print_nrc_copyright "li-sort.sh" 2007
export PORTAGE_INTERNAL_CALL=1

if [ $# -gt 0 ] && [ "$1" == "-h" ]; then

cat <<==EOF== >&2

li-sort.sh [-h] [sort args]

Call Unix sort on the given arguments, in a locale-independent way.

==EOF==
exit 1
fi

export LC_ALL=C
exec sort $*
