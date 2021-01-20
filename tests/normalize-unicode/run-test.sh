#!/bin/bash

set -o pipefail

FOUND_ERR=

echo -n STDIN... ""
echo ٷ | normalize-unicode.pl  ar | diff - <(echo ۇٴ) &&
   echo OK || { echo FAIL; FOUND_ERR=1; }
echo -n Using - for STDIN... ""
echo ٷ | normalize-unicode.pl  ar - | diff - <(echo ۇٴ) &&
   echo OK || { echo FAIL; FOUND_ERR=1; }
echo -n Using filename... ""
echo ٷ | normalize-unicode.pl  ar /dev/stdin | diff - <(echo ۇٴ) &&
   echo OK || { echo FAIL; FOUND_ERR=1; }

if [[ $FOUND_ERR ]]; then
   echo At least one test FAILED.
else
   echo All tests PASSED.
fi
exit $FOUND_ERR
