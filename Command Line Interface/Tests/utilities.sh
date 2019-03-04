#!/bin/bash

# Turns on alias expansion explicitly as the shell will be non-interactive, while also clearing all
# existing aliases.
unalias -a
shopt -s expand_aliases

# Creates a convenience alias for the `report_exit_status_assertion` function.
alias report_if_status_is='report_exit_status_assertion $LINENO '

# Creates a convenience alias for the `report_exit_status_assertion` function.
alias report_if_output_matches='report_ouput_assertion $LINENO '

# Color codes for printing.
readonly turn_red='\033[0;31m'
readonly turn_green='\033[0;32m'
readonly turn_normal='\033[0m'

# Runs a given command while removing all of its output to stdout and stderr. `$?` remains the same.
# If "--stderr" is passed as first command line argument, only it is silenced.
function silent {
   if [ "$1" = "--stderr" ]; then
      ${@:2} 2> /dev/null
   else
      $@ &> /dev/null
   fi

   return $?
}

# Takes a test-identifier, an expected exit status and optionally an explicit last exit status
# (otherwise `$?` is used). This function prints a description, representing the success status of
# a test with the given identifier.
function report_exit_status_assertion {
   # Takes the last exit status as `exit_status`, unless one is explicitly provided as `$3`.
   local -i exit_status=$?; if [ -n "$3" ]; then exit_status=$3; fi

   if [ $exit_status -eq "$2" ]; then
      echo -e "> ${turn_green}Test[$1]\tOK$turn_normal"
   else
      echo -e "> ${turn_red}Test[$1]\tNO: Expected exit status $2, but got $exit_status$turn_normal"
   fi
}

# Takes a test-identifier, a string representing a command's output and a string representing the
# expected output. This function prints a description, representing the validity of the command's
# output.
# If "--files" is passed as second command line argument, the inputs are assumed to be files.
# Using this command implies an expectation of exit status 0.
function report_ouput_assertion {
   local exit_status=$?

   # Sets the output- and expected-string according to whether the "--file"-flag was set.
   if [ "$2" = '--files' ]; then
      output_string=`cat $3`
      expected_string=`cat $4`
   else
      output_string=$2
      expected_string=$3
   fi

   if [ $exit_status ]; then
      if [ "$output_string" = "$expected_string" ]; then
         echo -e "> ${turn_green}Test[$1]\tOK$turn_normal"
      else
         echo -e "> ${turn_red}Test[$1]\tNO: Expected different output$turn_normal"
      fi
   else
      report_if_status_is $1 0 $exit_status
   fi
}
