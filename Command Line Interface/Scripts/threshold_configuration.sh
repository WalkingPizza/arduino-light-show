#!/bin/bash

# This script takes a `.ino`-file as command line argument and prints a threshold-configuration
# corresponding to the `.ino`-file's threshold-declarations.
#
# A "threshold-declaration" has the form:
#
# // #threshold <microphone-identifier>
# const int <identifier> = <integer-literal>;
#
# The first line is called the "header", the second one the "body".
# The `<microphone-identifier>` is some (user-defined) string literal, that may not contain colon or
# double-qoute characters.
#
# The generated threshold-configuration file contains a sequence of lines of the form:
#
# <microphone_identifier>: <integer-literal>
#
# Exit status:
# * 0: A threshold-configuration file could successfully be generated.
# * 1: The given program-file path is invalid or not readable
# * 3: The given program-file path is not a `.ino`-file
# * 4: Duplicate microphone-identifiers were detected in the `.ino`-file
# * 5: Malformed threshold-declaration bodies were detected in the `.ino`-file
# * 6: Program-internal error


#-Preliminaries---------------------------------#


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
   readonly ino_file=$1
}


#-Functions-------------------------------------#


# This functions takes line numbered lists of header candidates and valid headers. For every
# malformed header it prints a warning to stderr.
function warn_about_malformed_headers {
   # Gets the diff between the lists of header candidates and valid headers (which `comm` expects to
   # be lexically sorted).
   local malformed_headers=`comm -23 <(sort <<< "$1") <(sort <<< "$2")`

   # Returns early if no malformed headers were found.
   [ -z "$malformed_headers" ] && return

   # Prints a warning message for each malformed line.
   while read malformed_line; do
      local line_number=`cut -d : -f 1 <<< "$malformed_line"`
      echo "Warning: \`$ino_file\` line $line_number: malformed threshold-declaration header" >&2
   done <<< "$malformed_headers"
}

# This functions takes a list of line-numbered microphone-identifiers. For every duplicate
# identifier it prints an error to stderr and aborts.
function abort_on_duplicate_identifiers_ {
   # Gets a list of duplicate identifiers.
   local duplicate_identifiers=`cut -d : -f 2 <<< "$1" | sort | uniq -d`

   # Returns successfully if no duplicates were found.
   [ -z "$duplicate_identifiers" ] && return 0  # Exiting convention

   # Prints and error message for each duplicate.
   while read duplicate; do
      # Gets the lines of the duplicates in a comma-seperated list.
      local duplicate_lines=`egrep "^\s*[0-9]\s*:\s*$duplicate\s*\$" <<< "$1"`
      local line_number_list=`cut -d : -f 1 <<< "$duplicate_lines" | paste -s -d , -`

      # Prints the error message to stderr.
      echo "Error: \`$ino_file\` lines $line_number_list: duplicate microphone-identifiers" >&2
   done <<< "$duplicate_identifiers"

   exit 4
}

# This functions takes a list of line-numbered body candidates. For every malformed body it prints
# an error to stderr and aborts.
function abort_on_malformed_bodies_ {
   # Gets the lines containing malformed threshold-declaration bodies.
   local body_pattern=`regex_for_ --body`
   local malformed_bodies=`egrep -v "^\s*[0-9]+\s*:${body_pattern:1}" <<< "$1"`

   # Returns successfully if there are no malformed bodies.
   [ -z "$malformed_bodies" ] && return 0 # Exiting convention

   # Prints an error message for each malformed line.
   while read malformed_body; do
      local line_number=`cut -d : -f 1 <<< "$malformed_body"`
      echo "Error: \`$ino_file\` line $line_number: malformed threshold-declaration body" >&2
   done <<< "$malformed_bodies"

   exit 5
}

# A helper function to `numbered_declaration_components` which gets the line numbered threshold
# declaration bodies for a given file.
function _numbered_declaration_bodies {
   # Sets up state variables.
   local line_counter=1
   local last_matched=false

   # Iterates over the lines in the file.
   while read -r line; do
      # Prints the current line if the previous one matched (meaning that this line should be a
      # declaration body).
      if $last_matched; then
         echo "$line_counter:$line"
         last_matched=false
      else
         # Checks for threshold-declaration headers, or the end tag.
         if egrep -q "`regex_for_ --header`" <<< "$line"; then
            last_matched=true
         elif egrep -q "`regex_for_ --end-tag`" <<< "$line"; then
            return
         fi
      fi

      (( line_counter++ ))
   done < "$1"
}

# This function takes a flag and a program file. It returns all of the lines (with line numbers) in
# the given program file, that match the chosen threshold-declaration component. The search stops
# when matching a thresholds-end tag.
# Possible flags are: "--header-candidates", "--headers" or "--bodies"
function numbered_declaration_components {
   # Sets the appropriate regex-pattern
   if [ "$1" = '--header-candidates' ]; then
      local pattern=`regex_for_ --header-candidate`
   elif [ "$1" = '--headers' ]; then
      local pattern=`regex_for_ --header`
   elif [ "$1" = '--bodies' ]; then
      echo "`_numbered_declaration_bodies "$2"`"
      return
   else
      return
   fi

   # Iterates over the lines in the file.
   line_counter=1
   while read line; do
      # Checks for matching lines, or the end tag.
      if egrep -q "$pattern" <<< "$line"; then
         echo "$line_counter:$line"
      elif egrep -q "`regex_for_ --end-tag`" <<< "$line"; then
         return
      fi

      (( line_counter++ ))
   done < "$2"
}

# This function takes a `.ino`-file. It prints a list of the microphone-identifiers contained in the
# given file.
function get_microphone_identifiers_ {
   # Gets the lines containing possibly malformed threshold-declaration headers.
   local header_candidates=`numbered_declaration_components --header-candidates "$1"`
   # Gets the lines containing valid threshold-declaration headers.
   local headers=`numbered_declaration_components --headers "$1"`

   warn_about_malformed_headers "$header_candidates" "$headers"

   # Gets the lines in which the declaration headers are located.
   local header_lines=`cut -d : -f 1 <<< "$headers"`
   # Gets the valid threshold-declaration headers' microphone-identifiers.
   local microphone_ids=`cut -d '"' -f 2 <<< "$headers"`
   # Creates a line numbered list of microphone-identifiers.
   local line_numbered_microphone_ids=`paste -d : <(echo "$header_lines") <(echo "$microphone_ids")`

   abort_on_duplicate_identifiers_ "$line_numbered_microphone_ids" || exit $?

   # Prints the result to stdout.
   echo "$microphone_ids"

   return 0
}

# This function takes a line numbered `.ino`-program. It prints a list of the threshold-values
# contained in the given program.
function get_threshold_values_ {
   # Gets the lines right after the declaration headers, containing (possibly malformed) threshold-
   # declaration bodies.
   local declaration_bodies=`numbered_declaration_components --bodies "$1"`

   abort_on_malformed_bodies_ "$declaration_bodies" || exit $?

   # Gets the valid threshold-declaration bodys' values.
   local declaration_body_suffixes=`cut -d '=' -f 2 <<< "$declaration_bodies"`
   local declaration_body_values=`egrep -o '[0-9]+' <<< "$declaration_body_suffixes"`

   # Prints the result to stdout.
   echo "$declaration_body_values"

   return 0 # Exiting convention
}


#-Main-Program----------------------------------#


declare_constants "$@"

# Establishes that an existing `.ino`-file was passed, and creates constants for the program.
assert_path_validity_ "$ino_file" --ino || exit $?

# Gets the lists of microphone-identifiers.
microphone_identifiers=`get_microphone_identifiers_ "$ino_file"` || exit $?

# Early exit if no declarations were found.
[ -n "$microphone_identifiers" ] || exit 0

# Gets the list of threshold-values in the same order as the microphone-identifiers.
threshold_values=`get_threshold_values_ "$ino_file"` || exit $?

# Sanity check.
if [ `wc -l <<< "$microphone_identifiers"` -ne `wc -l <<< "$threshold_values"` ]; then
   echo "Error: \`$script_name\` found different numbers of microphone-identifiers" \
        "and threshold-values" >&2
   exit 6
fi

# Merges the threshold configuration items into joined lines.
threshold_configuration=`paste -d ':' <(echo "$microphone_identifiers") <(echo "$threshold_values")`

# Writes the (formatted) current threshold-configuration to stdout.
sed -e 's/:/: /' <<< "$threshold_configuration"
exit 0
