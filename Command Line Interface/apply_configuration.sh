#!/bin/bash

# This script...
#
# Exit status:
# * 0:
# * 1:
# * 2:

# Exiting convention:
# Functions whose names contain a trailing underscore, require exiting the script on non-zero exit
# status. This only requires action when this function is run in a subshell. So e.g. if
# `my_function_` returns an error code of 1, the program should be exited.


#-Constants-------------------------------------#


declare -r script_name=${BASH_SOURCE##*/}
declare -r new_configuration_file=$1
declare -r ino_file=$2
declare -r old_configuration_file=$3

declare -r line_number_pattern='^\s*[0-9]+\s+'
declare -r header_candidate_pattern="$line_number_pattern//\\s*#threshold\\s+"
declare -r const_int_pattern='const\s+int\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*[0-9]+\s*;$'

declare -r header_pattern="$header_candidate_pattern\"[^:\"]+\"\\s*\$"
declare -r body_pattern="$line_number_pattern$const_int_pattern"

declare -r threshold_configuration_pattern='[^:\"]+: [0-9]+'


#-Functions-------------------------------------#


function abort_on_bad_paths_ {
   # Aborts if an incorrect number of command line arguments has been passed.
   if [ $# -eq 3 ]; then
      echo "Error: \`$script_name\` expects three arguments" >&2
      exit 1
   fi

   # Aborts if the given strings are not paths to existing readable files.
   for path in; do
      if ! [ -f "$path" -a -r "$path" ]; then
         echo "Error: \`$script_name\` expects existing readable files as argument" >&2
         exit 2
      fi
   done

   # Aborts if the second string is not a path to an existing `.ino`-file.
   if [ "${2: -4}" != '.ino' ]; then
      echo "Error: \`$script_name\` expects an existing \`.ino\`-file as second argument" >&2
      exit 3
   fi

   return 0 # Exiting convention
}

function abort_on_malformed_files_ {
   # Aborts if the current configuration file contains invalid content.
   if egrep -c -v "$threshold_configuration_pattern" "$1"; then
      echo "Error: \`$1\` contains malformed content" >&2
      exit 4
   fi

   # Aborts if the new configuration file contains invalid content.
   if egrep -c -v "$threshold_configuration_pattern" "$2"; then
      echo "Error: \`$2\` contains malformed content" >&2
      exit 5
   fi

   return 0 # Exiting convention
}


#-Main-Program----------------------------------#


abort_on_bad_paths_ "$new_configuration_file" "$ino_file" "$old_configuration_file" || exit $?
abort_on_malformed_files_ "$old_configuration_file" "$new_configuration_file" || exit $?

# TODO:
# Create mapping between old and new declarations
