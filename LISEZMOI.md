[English](README.md)

# Traitement de texte Portage (PortageTextProcessing)

Ce repo rassemble des outils de pré- et de post-traitement de texte écrits dans le
contexte du projet de traduction automatique statistique Portage. Comme ils servent
fréquemment dans d'autres projets, nous les avons regroupés dans ce repo qui se veut
trivial à installer.

## Installation

Clonez ce repo à l'endroit de votre choix et ajoutez cette ligne à votre .profile ou .bashrc:

`source /path/to/PortageTextProcessing/SETUP.bash`

## Dépendances

PortageTextProcessing a besoin de:
 - Perl >= 5.14, nommé `perl` sur votre PATH;
 - Python 2.7, nommé `python2` sur votre PATH;
 - n'importe quelle version de Python 3, nommée `python3` sur votre PATH;
 - `/bin/bash`, `/bin/sh`, `/usr/bin/env`.

Il faut aussi certaines librairies Perl, Python 2.7 et Python 3, que vous pourrez
installer à l'aide de gestionnaire de modules de votre choix. La liste peut être obtenue
en exécutant `./run-test.sh` dans le répertoire `tests/check-installation/`. Cette suite
de tests valide la présence des dépendances et signale celles qui manquent.

## Validation

Pour tester votre installation plus en profondeur, exécutez `./run-all-tests.sh` dans le
répertoire `tests/`. Examinez ensuite `_log.run-test` dans tout sous-répertoire où une
erreur est signalée, ou encore roulez-y `./run-test.sh` directement.

Certaines suites sont parallélisées pour terminer plus rapidement. Si vous avez de la
difficulté à associer un message d'erreur à sa source, utilisez `make -B` au lieu de
`./run-test.sh` pour exécuter les tests de la suite de façon séquentielle, en arrêtant à
la première erreur.

## Documentation

Chaque script accepte l'option `-h` pour produire sa documentation (en anglais) à
l'écran.

## Liste des scripts

| Script                          | Description brève (en anglais)                             |
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

## Contribuer

Si vous voulez contribuer des scripts à ce repo, s'il-vous-plaît:
 - Assurez-vous qu'ils ne requièrent aucune compilation ou installation (autre que
   sourcer `SETUP.bash`).
 - Ajouter des tests pour votre script sous `tests/`.
 - Assurez-vous qu'ils soient pertinents, c'est à dire qu'ils font du traitement simple
   du langage naturel.

## Citation

```bib
@misc{Portage_Text_Processing,
author = {Larkin, Samuel and Joanis, Eric and Stewart, Darlene and Simard, Michel and Foster, George and Ueffing, Nicola and Tikuisis, Aaron},
license = {MIT},
title = {{Portage Text Processing}},
url = {https://github.com/nrc-cnrc/PortageTextProcessing}
}
```

## Copyright

Traitement multilingue de textes / Multilingual Text Processing

Centre de recherche en technologies numériques / Digital Technologies Research Centre

Conseil national de recherches Canada / National Research Council Canada

Copyright 2022, Sa Majesté la Reine du Chef du Canada / Her Majesty in Right of Canada

Publié sous la license MIT (voir [LICENSE](LICENSE))

