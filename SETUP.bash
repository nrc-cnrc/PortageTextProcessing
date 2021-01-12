# @file SETUP.bash
# @brief Source this file to add the Portage Text Processing tools to your PATH
#
# @author Eric Joanis
#
# Traitement multilingue de textes / Multilingual Text Processing
# Technologies numériques / Digital Technologies
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2021, Sa Majeste la Reine du Chef du Canada /
# Copyright 2021, Her Majesty in Right of Canada

echo "PortageTextProcessing, NRC-CNRC, (c) 2004 - 2021, Her Majesty in Right of Canada" >&2

SOURCE="${BASH_SOURCE[0]}"
if [[ -h $SOURCE ]]; then
    SOURCE=$(readlink -f $SOURCE)
fi
BASE_DIR="$( cd "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
#echo BASE_DIR=$BASE_DIR
export PATH=$BASE_DIR/bin:$PATH
export PERL5LIB=$BASE_DIR/lib${PERL5LIB:+:$PERL5LIB}
export PYTHONPATH=$BASE_DIR/lib${PYTHONPATH:+:$PYTHONPATH}
