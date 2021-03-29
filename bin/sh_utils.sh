#!/bin/bash

# @file sh_utils.sh
# @brief Library of useful bash commands.
#
# @author Samuel Larkin
#
# Technologies langagieres interactives / Interactive Language Technologies
# Inst. de technologie de l'information / Institute for Information Technology
# Conseil national de recherches Canada / National Research Council Canada
# Copyright 2008, Sa Majeste la Reine du Chef du Canada /
# Copyright 2008, Her Majesty in Right of Canada

# How to include the library:
## Include NRC's bash library.
#BIN=`dirname $0`
#if [[ ! -r $BIN/sh_utils.sh ]]; then
#   # assume executing from src/* directory
#   BIN="$BIN/../utils"
#fi
#source $BIN/sh_utils.sh || { echo "Error: Unable to source sh_utils.sh" >&2; exit 1; }



# Portage is developed with bash 3, and uses the bash 3.1 RE syntax, which
# changed from version 3.2.  Set "compat31" if we're using bash 3.2, 4 or more
# recent, to preserve the expected syntax.  We used to test the version of bash
# explicitly, but it's simpler to always run the command and ignore its return
# code: if it fails, we're running a version of bash that doesn't need it.
shopt -s compat31 >& /dev/null || true

# error_exit "some error message" "optionnally a second line of error message"
# will exit with an error status, print the specified error message(s) on
# STDERR.
error_exit() {
   {
      PROG_NAME=`basename $0`
      echo -n "$PROG_NAME fatal error: "
      for msg in "$@"; do
         echo $msg
      done
      echo "Use -h for help."
   } >&2
   exit 1
}

# Verify that enough args remain on the command line
# syntax: one_arg_check <args needed> $# <arg name>
# Note that the syntax show above is meant to be part of a while/case structure
# for handling parameters, so that $# still includes the option itself.  exits
# with error message if the check fails.
arg_check() {
   if [ $2 -le $1 ]; then
      error_exit "Missing argument to $3 option."
   fi
}

# arg_check_int $value $arg_name exits with an error if $value does not
# represent an integer, using $arg_name to provide a meaningful error message.
arg_check_int() {
   expr $1 + 0 &> /dev/null
   RC=$?
   if [ $RC != 0 -a $RC != 1 ]; then
      error_exit "Invalid argument to $2 option: $1; integer expected."
   fi
}

# arg_check_pos_int $value $arg_name exits with an error if $value does not
# represent a positive integer, using $arg_name to provide a meaningful error
# message.
arg_check_pos_int() {
   expr $1 + 0 &> /dev/null
   RC=$?
   if [ $RC != 0 -a $RC != 1 ] || [ $1 -le 0 ]; then
      error_exit "Invalid argument to $2 option: $1; positive integer expected."
   fi
}

# Print a warning message.
warn() {
   echo "WARNING: $*" >&2
}

# Print a debug message.
debug() {
   test -n "$DEBUG" && echo "<D> $*" >&2
}

# Print a verbose message.
verbose() {
   level=$1; shift
   if [[ $level -le $VERBOSE ]]; then
      echo "$*" >&2
   fi
}

# Normally, evaluate a command, also echoing it to STDERR if verbose is on.
# However, if NOTREALLY is set, just echo the command to STDOUT.
run_cmd() {
   cmd=$*
   if [[ $NOTREALLY ]]; then
      echo "$cmd"
   else
      verbose 1 $cmd
      eval $cmd
      return $?
   fi
}

# Print the standard NRC Copyright notice
# Usage: print_nrc_copyright program_name year
current_year=2020
print_nrc_copyright() {
   prog_name=$1
   year=$2
   if [[ "" && ! $PORTAGE_INTERNAL_CALL ]]; then
      echo -n "$prog_name, NRC-CNRC, (c) $year"
      if [[ $year != $current_year ]]; then
         echo -n " - $current_year"
      fi
      echo ", Her Majesty in Right of Canada";
      echo "Please run \"portage_info -notice\" for Copyright notices of 3rd party libraries."
      echo ""
   fi >&2
}

# This library's help message.
_sh_utils_help() {
   print_nrc_copyright sh_utils.sh 2008
   {
   echo '
sh_utils.sh is a library of useful bash functions for other bash scripts.

   Include sh_utils.sh in your bash script using the following snippet of code:

   BIN=`dirname $0`
   if [[ ! -r $BIN/sh_utils.sh ]]; then
      # assume executing from src/* directory
      BIN="$BIN/../utils"
   fi
   source $BIN/sh_utils.sh

Functions available:
'

   grep -o '^[a-z][a-z_]*()' $0 | sed 's/^/   /'

   echo "
Documentation for these functions is found within sh_utils.sh
"
   } >&2
}

# This file is intended to be a library and not an executable file.
if [[ `basename $0` == "sh_utils.sh" ]]; then
   _sh_utils_help
   exit # exit with 0 status: it's not an error to call this script with -h!
fi


# Return the ceiling of the quotient of $1 / $2 => ⌈$1 / $2⌋
# Both arguments must be positive integers and the dividor mustn't be 0
ceiling_quotient() {
   echo $((($1 + $2 - 1) / $2))
}

