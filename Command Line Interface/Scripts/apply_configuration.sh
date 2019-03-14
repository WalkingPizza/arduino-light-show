#!/bin/bash

# This script...
#
# Exit status:
# * 0:
# * 1:
# * 2:
#
# Exiting convention:
# Functions whose names contain a trailing underscore, require exiting the script on non-zero exit
# status. This only requires action when this function is run in a subshell. So e.g. if
# `my_function_` returns an error code of 1, the program should be exited.

# TODO: Add documentation to this file

# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports CLI utilities.
. "$dot/../Utilities/utilities.sh"


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   # The name of this script.
   readonly script_name=${BASH_SOURCE##*/}

   # Named command line arguments.
   readonly configuration_file=$1
   readonly ino_file=$2
}


#-Functions-------------------------------------#


function abort_on_malformed_configuration_ {
   # Aborts if the configuration file contains invalid entries.
   if egrep -vq "`regex_for --configuration-entry`" "$1"; then
      echo "Error: \`$script_name\` received malformed configuration file" >&2
      exit 4
   fi

   # Gets a list of duplicate identifiers.
   local duplicate_microphone_ids=`cut -d : -f 1 "$1" | sort | uniq -d`

   # Returns successfully if no duplicates were found.
   [ -z "$duplicate_microphone_ids" ] && return 0  # Exiting convention

   # Prints and error message for each duplicate.
   while read duplicate; do
      # Gets the lines of the duplicates in a comma-seperated list.
      local line_number_list=`egrep -n "^$duplicate:" "$1" | cut -d : -f 1 | paste -s -d , -`

      # Prints the error message to stderr.
      echo "Error: \`$1\` lines $line_number_list: duplicate microphone-identifiers" >&2
   done <<< "$duplicate_microphone_ids"

   exit 5
}

function declaration_line_numbers {
   line_counter=1

   while read line; do
      if egrep -q "`regex_for --header`" <<< "$line"; then
         echo $line_counter
         echo $(( line_counter + 1 ))
      elif egrep -q "`regex_for --end-tag`" <<< "$line"; then
         return
      fi

      (( line_counter++ ))
   done < "$1"
}

function threshold_declarations_for_configuration {
   configuration=`cat "$1"`
   [ -z "$configuration" ] && return

   declaration_counter=0
   while read declaration; do
      microphone_id=`cut -d : -f 1 <<< "$declaration"`
      threshold_value=`cut -d : -f 2 <<< "$declaration"`

      echo "// #threshold \"$microphone_id\""
      echo "const int threshold_declaration_${declaration_counter}_value =$threshold_value;"
      echo

      (( declaration_counter++ ))
   done <<< "$configuration"

   echo '// #threshold-declarations-end'
}


#-Main-Program----------------------------------#


declare_constants "$@"

# Aborts if either of the given command line arguments are invalid or malformed.
abort_on_bad_path_ "$ino_file" --ino || exit $?
abort_on_bad_path_ "$configuration_file" || exit $?
abort_on_malformed_configuration_ "$configuration_file" || exit $?

# Gets all of the lines containing threshold-declarations.
declaration_line_numbers=`declaration_line_numbers "$ino_file"`

# Removes all of the current threshold-declarations (in reverse order, so removal of one line does
# not affect the line number of another).
while read line_to_delete; do
   sed -i '' -e "${line_to_delete}d" "$ino_file"
done <<< "`tail -r <<< "$declaration_line_numbers"`"

# Determines where to insert the new threshold-declarations.
declaration_insertion_point=`head -n 1 <<< "$declaration_line_numbers"`

# Generates threshold-declarations from the new configuration.
new_declarations=`threshold_declarations_for_configuration "$configuration_file"`

# Inserts the generated declarations at the insertion point.
ex -s -c "${declaration_insertion_point}i|$new_declarations" -c 'x' "$ino_file"

# TODO: Remove any uses of "threshold_declaration_[n >= number of declarations]_value"
