#!/bin/bash

# Turns on alias expansion explicitly as the shell will be non-interactive, while also clearing all
# existing aliases.
unalias -a
shopt -s expand_aliases

# Creates a convenience alias for the `report_exit_status_assertion` function.
alias report_if_status_is='report_exit_status_assertion $LINENO '

# Creates a convenience alias for the `report_exit_status_assertion` function.
alias report_if_output_matches='report_ouput_assertion $LINENO '

# Runs a given command while removing all of its output to stdout and stderr. `$?` remains the same.
function silent {
   $@ &> /dev/null
   return $?
}

# Takes a test-identifier, an expected exit status and optionally an explicit last exit status
# (otherwise `$?` is used). This function prints a description, representing the success status of
# a test with the given identifier.
function report_exit_status_assertion {
   # Takes the last exit status as `exit_status`, unless one is explicitly provided as `$3`.
   local -i exit_status=$?; if [ -n "$3" ]; then exit_status=$3; fi

   if [ $exit_status -eq "$2" ]; then
      echo -e "> Test[$1]\tOK"
   else
      echo -e "> Test[$1]\tNO: Expected exit status $2, but got $exit_status"
   fi
}

# Takes a test-identifier, a string representing a command's output and a string representing the
# expected output. This function prints a description, representing the validity of the command's
# output.
# Using this command implies an expectation of exit status 0.
function report_ouput_assertion {
   local exit_status=$?

   if [ $exit_status ]; then
      if [ "$2" = "$3" ]; then
         echo -e "> Test[$1]\tOK"
      else
         echo -e "> Test[$1]\tNO: Expected different output"
      fi
   else
      report_if_status_is $1 0 $exit_status
   fi
}
