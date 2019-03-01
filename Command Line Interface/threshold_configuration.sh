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
# * 1: No program-file was given as argument
# * 2: The given program-file path is invalid or not readable
# * 3: The given program-file path is not a `.ino`-file
# * 4: Duplicate microphone-identifiers were detected in the `.ino`-file
# * 5: Malformed threshold-declaration bodies were detected in the `.ino`-file
# * 6: Program-internal error

# Exiting convention:
# Functions whose names contain a trailing underscore, require exiting the script on non-zero exit
# status. This only requires action when this function is run in a subshell. So e.g. if
# `my_function_` returns an error code of 1, the program should be exited.


#-Constant-Declarations-------------------------#


declare -r script_name=${BASH_SOURCE##*/}
declare -r ino_file=$1

declare -r line_number_pattern='^\s*[0-9]+\s+'
declare -r header_candidate_pattern="$line_number_pattern//\\s*#threshold\\s+"
declare -r const_int_pattern='const\s+int\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*[0-9]+\s*;$'

declare -r header_pattern="$header_candidate_pattern\"[^:\"]+\"\\s*\$"
declare -r body_pattern="$line_number_pattern$const_int_pattern"


#-Functions-------------------------------------#


# This function takes a file path. Aborts the program if the given string does not actually point to
# an existing `.ino`-file.
function abort_on_bad_path_ {
   # Aborts if no command line argument has been passed.
   if [ -z "$1" ]; then
      echo "Error: \`$script_name\` expects an argument" >&2
      exit 1
   fi

   # Aborts if the given string is not a path to an existing readable file.
   if ! [ -f "$1" -a -r "$1" ]; then
      echo "Error: \`$script_name\` expects an existing readable file as argument" >&2
      exit 2
   fi

   # Aborts if the given string is not a path to an existing `.ino`-file.
   if [ "${1: -4}" != '.ino' ]; then
      echo "Error: \`$script_name\` expects an existing \`.ino\`-file as argument" >&2
      exit 3
   fi

   return 0 # Exiting convention
}

# This function takes a regex-pattern and a line numbered `.ino`-program. It prints the successors
# of all of the lines in the program, matching the regex-pattern.
function lines_after {
   egrep -A1 "$1" <<< "$2" | egrep -v "$1|--"
}

# This functions takes a list of header candidates and a list of valid headers. For every malformed
# header it prints a warning to stderr.
function warn_about_malformed_headers {
   # Gets the diff between the lists of header candidates and valid headers.
   local malformed_headers=`comm -23 <(echo "$1") <(echo "$2")`

   # Prints a warning message for each malformed line.
   while read line_number _; do
      echo "Warning: \`$ino_file\` line $line_number: Malformed threshold-declaration header" >&2
   done <<< "$malformed_headers"
}

# This functions takes a list of microphone-identifiers. For every duplicate identifier it prints an
# error to stderr and aborts.
function abort_on_duplicate_identifiers_ {
   # Gets a list of duplicate identifiers.
   local duplicate_identifiers=`sort <<< "$1" | uniq -d`

   # Returns successfully if no duplicates were found.
   if [ -z "$duplicate_identifiers" ]; then
      return 0  # Exiting convention
   fi

   # TODO: Print an error message for each duplicate identifier
   
   exit 4
}

# This functions takes a list of body candidates. For every malformed body it prints an error to
# stderr and aborts.
function abort_on_malformed_bodies_ {
   # Gets the lines containing malformed threshold-declaration bodies.
   local malformed_declaration_bodies=`egrep -v "$body_pattern" <<< "$1"`

   # Aborts if there are any threshold-declaration headers without a valid body.
   if [ -n "$malformed_declaration_bodies" ]; then
      # Prints an error message for each malformed line.
      while read line_number _; do
         echo "Error: \`$ino_file\` line $line_number: Malformed threshold-declaration body" >&2
      done <<< "$malformed_declaration_bodies"

      exit 5
   fi

   return 0 # Exiting convention
}

# This function takes a line numbered `.ino`-program. It prints a list of the microphone-identifiers
# contained in the given program.
function get_microphone_identifiers_ {
   # Gets the lines containing possibly malformed threshold-declaration headers.
   local declaration_header_candidates=`egrep "$header_candidate_pattern" <<< "$1"`
   # Gets the lines containing valid threshold-declaration headers.
   local declaration_headers=`egrep "$header_pattern" <<< "$1"`

   warn_about_malformed_headers "$declaration_header_candidates" "$declaration_headers"

   # Gets the valid threshold-declaration headers' microphone-identifiers.
   local microphone_identifiers=`cut -d '"' -f 2 <<< "$declaration_headers"`

   abort_on_duplicate_identifiers_ "$microphone_identifiers" || exit $?

   # Prints the result to stdout.
   echo "$microphone_identifiers"

   return 0 # Exiting convention
}

# This function takes a line numbered `.ino`-program. It prints a list of the threshold-values
# contained in the given program.
function get_threshold_values_ {
   # Gets the lines containing (possibly malformed) threshold-declaration bodies.
   local declaration_bodies=`lines_after "$header_pattern" "$1"`

   abort_on_malformed_bodies_ "$declaration_bodies" || exit $?

   # Gets the valid threshold-declaration bodys' values.
   local declaration_body_suffixes=`cut -d '=' -f 2 <<< "$declaration_bodies"`
   local declaration_body_values=`egrep -o '[0-9]+' <<< "$declaration_body_suffixes"`

   # Prints the result to stdout.
   echo "$declaration_body_values"

   return 0 # Exiting convention
}


#-Main-Program----------------------------------#


# Establishes that an existing `.ino`-file was passed, and creates constants for the program.
abort_on_bad_path_ "$ino_file"

declare -r numbered_ino_program=`nl -s' ' -ba "$ino_file"`

# Gets the lists of microphone-identifiers.
microphone_identifiers=`get_microphone_identifiers_ "$numbered_ino_program"` || exit $?

# Gets the list of threshold-values in the same order as the microphone-identifiers.
threshold_values=`get_threshold_values_ "$numbered_ino_program"` || exit $?

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
