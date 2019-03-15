#!/bin/bash

# This script serves as a library of functions to be used by the CLI's test-scripts. It can be
# "imported" via sourcing. It should be noted that this script activates alias expansion.


#-Preliminaries---------------------------------#


# Turns on alias-expansion explicitly as users of this script will probably be non-interactive
# shells, while also clearing all existing aliases.
unalias -a
shopt -s expand_aliases


#-Constants-------------------------------------#


# Declares color codes for printing.
readonly _color_red='\033[0;31m'
readonly _color_green='\033[0;32m'
readonly _color_normal='\033[0m'


#-Functions-------------------------------------#


# Runs a given command while removing the output streams specified by a flag. If no flag is passed,
# stdout and stderr are silenced.
#
# Arguments:
# <flag> optional, possible values: "--stderr", "--stdout"
# <command> including all of its arguments
#
# Return status:
# $? of <command>
function silent- {
   # Runs <command> and redirects output differently depending on the given <flag>.
   case "$1" in
      --stdout) "${@:2}" 1> /dev/null ;;
      --stderr) "${@:2}" 2> /dev/null ;;
      *) "$@" &> /dev/null ;;
   esac

   # Propagates the return status of <command>.
   return $?
}

# Prints a description about whether the test with a given identifier succeeded based on whether the
# last return status corresponds to an expected value or not.
#
# Arguments:
# <test-identifier> passed automatically as the current line number by the alias
# <expected return status>
# <last return status> optional, is set as $? if not passed explicitly
alias report_if_last_status_was='_report_if_last_status_was "Line $LINENO" '
function _report_if_last_status_was {
   # Secures the last return status, unless it was explicitly passed as argument.
   local return_status=$?; [ -n "$3" ] && return_status=$3

   # Prints a message depending on whether <last return status> has the expected value or not.
   if [ "$return_status" -eq "$2" ]; then
      echo -e "> $_color_green$1\tOK$_color_normal"
   else
      echo -e "> $_color_red$1\tNO: Expected return status $2, but got $return_status$_color_normal"
   fi

   return 0
}

# Prints a description about whether a given output string matches a given expected string. The use
# of this functions implies and expectation that the last return status was 0. If this is not the
# case this is also reported.
#
# Arguments:
# <test-identifier> passed automatically as the current line number by the alias
# <output string>
# <expected output string>
alias report_if_output_matches='_report_if_output_matches "Line $LINENO" '
function _report_if_output_matches {
   # Secures the last return status.
   local -r return_status=$?

   # Makes sure that the last return status was not failing, or else reports this and returns.
   [ "$return_status" -eq 0 ] || { _report_if_last_status_was "$1" 0 "$return_status"; return 0; }

   # Prints a message depending on whether <output string> and <expected output string> have the
   # same value.
   if [ "$2" = "$3" ]; then
      echo -e "> $_color_green$1\tOK$_color_normal"
   else
      echo -e "> $_color_red$1\tNO: Expected different output$_color_normal"
   fi

   return 0
}
