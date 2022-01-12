[Français](LISEZMOI.md)

# Portage Text Processing

This repository contains a number of text pre- and post-processing utilities written in
the context of the Portage Statistical Machine Translation project.  Since they are
frequently useful outside that context, we have separated them into this repository that
is trivial to install.

## Installation

Clone this repo to the location of your choice and add this line to your .profile or .bashrc:

`source /path/to/PortageTextProcessing/SETUP.bash`

## Dependencies

PortageTextProcessing requires:
 - Perl >= 5.14, as `perl` on your PATH;
 - Python 2.7, as `python2` on your PATH;
 - any version of Python 3, as `python3` on your PATH;
 - `/bin/bash`, `/bin/sh`, `/usr/bin/env`.

It also requires a number of Perl, Python 2.7, and Python 3 libraries, which you can
install with the package manager of your choice. For the list, go to
`tests/check-installation/` and run `./run-test.sh`. This test suite looks for
dependencies and flags any missing ones.

## Testing

For more extensive testing, go to `tests/` and run `./run-all-tests.sh`.  Go into any
directory showing errors and examine `_log.run-test` to see what went wrong, or run
`./run-test.sh` interactively.

Some test suites are parallelized to run faster. If you have difficulty figuring out
which command caused the error, you can also run `make -B` interactively in any test
suite instead of `./run-test.sh`, to run all its test cases sequentially and stop at the
first error.

## Documentation

Each script accepts the `-h` option to output its documentation to your terminal.

## List of scripts

| Script                          | Brief Description                                          |
| ------------------------------- | ---------------------------------------------------------- |
| `clean-utf8-text.pl`            | Clean up spaces, control chars, hyphen, etc. in utf8 text. |
| `clean_utf8.py`                 | Yet another utf8 clean up script.                          |
| `crlf2lf.sh`                    | Convert CRLF (DOS-style) line endings to LF (UNIX-style).  |
| `diff-round.pl`                 | Like diff, but ignore rounding errors.                     |
| `expand-auto.pl`                | Like expand, with automatically calculated tab stops.      |
| `filter-long-lines.pl`          | Filter out long lines.                                     |
| `filter-parallel.py`            | Filter parallel files by scores.                           |
| `fix-slashes.pl`                | Separate slash-joined words.                               |
| `lc-utf8.pl`                    | Map utf8 text to lowercase, regardless of your locale.     |
| `lfl2tmx.pl`                    | Create a TMX file from plain text aligned files.           |
| `li-sort.sh`                    | Locale-independent sort.                                   |
| `lines.py`                      | Extract the given lines from a file.                       |
| `map-chinese-punct.pl`          | Map Chinese wide punctuation marks to similar narrow ones. |
| `normalize-iu-spelling.pl`      | Apply Inuktut syllabic character normalization rules.      |
| `normalize-unicode.pl`          | Normalize unicode input into canonical representations.    |
| `parallel-uniq.pl`              | Like uniq, but take into consideration parallel files.     |
| `ridbom.sh`                     | Remove the byte-order marker (BOM) from UTF8 input.        |
| `second-to-hms.pl`              | Convert from seconds to HH:MM:SS or vice-versa.            |
| `select-line`                   | Get a given line from a text file.                         |
| `select-lines.py`               | Extract the given lines from a file.                       |
| `select-random-chunks.py`       | Sample random chunks from a file or by indices.            |
| `sort-by-length.pl`             | Sort a text file by line length.                           |
| `stableuniq.pl`                 | Remove duplicates without sorting.                         |
| `strip-parallel-blank-lines.py` | Strip parallel blank lines from two line-aligned files.    |
| `strip-parallel-duplicates.py`  | Strip aligned lines that are the same in both files.       |
| `tmx2lfl.pl`                    | Convert a TMX file to plain text aligned files.            |
| `udetokenize.pl`                | Detokenize utf8 text, reversing utokenize.pl.              |
| `utokenize.pl`                  | Tokenize utf8 text, e.g., for machine translation.         |
| `which-test.sh`                 | Which-like program with reliable exit status.              |

## Contributing

If you want to contribute scripts to this repo, please:
 - Make sure they require no compilation or installation (beyond sourcing `SETUP.bash`).
 - Add unit tests for your scripts under `tests/`.
 - Keep them relevant, which means pretty much anything related to text processing goes.

## Copyright

Traitement multilingue de textes / Multilingual Text Processing

Centre de recherche en technologies numériques / Digital Technologies Research Centre

Conseil national de recherches Canada / National Research Council Canada

Copyright 2022, Sa Majesté la Reine du Chef du Canada / Her Majesty in Right of Canada

Published under the MIT License (see [LICENSE](LICENSE))
