#!/bin/bash

# TODO: Add documentation

# Turns on alias expansion explicitly as the shell will be non-interactive, while also clearing all
# existing aliases.
unalias -a
shopt -s expand_aliases

# Creates a convenience alias for the `assert_path_validity_` function.
alias abort_on_bad_path_='assert_path_validity_ "${BASH_SOURCE##*/}" '

# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# This function takes a regular expression and a file. It returns the lines immediately following
# the lines matching the regular expression in the file.
function lines_after {
   egrep -A1 "$1" "$2" | egrep -v "$1|^--\$"
}

function regex_for {
   local regex_file="$dot/regular_expressions"

   case "$1" in
      --header-candidate)
         lines_after '^Threshold declaration header candidate:$' "$regex_file" ;;
      --header)
         lines_after '^Threshold declaration header:$' "$regex_file" ;;
      --body)
         lines_after '^Threshold declaration body:$' "$regex_file" ;;
      --end-tag)
         lines_after '^Threshold declarations end tag:$' "$regex_file" ;;
      --configuration-entry)
         lines_after '^Threshold configuration entry:$' "$regex_file" ;;
      *)
         echo "Error: \`${FUNCNAME[0]}\` received invalid flag \"$1\""
         return 1
   esac
   return 0
}

# These locations are relative to the repository if contained within it.
function location_of {
   local location_file="$dot/file_locations"
   local cli_directory=`lines_after '^Repository CLI-directory:$' "$location_file"`

   case "$1" in
      --cli-command)
         "$cli_directory/`lines_after '^CLI-command:$' "$location_file"`" ;;
      --cli-uninstaller)
         "$cli_directory/`lines_after '^CLI-uninstaller:$' "$location_file"`" ;;
      --cli-scripts)
         local match_line=`egrep -n '^CLI-scripts:$' "$location_file"`
         local list_start=$(( `cut -d : -f 1 <<< "$match_line"` + 1 ))

         while read line; do
            [ -n "$line" ] && echo "$cli_directory/$line" || break
         done <<< "`tail -n +$list_start $location_file`"
         ;;
      --cli-command-destination)
         lines_after '^Destination for CLI-command:$' "$location_file" ;;
      --cli-scripts-destination)
         lines_after '^Destination for CLI-scripts:$' "$location_file" ;;
      --arduino-cli-source)
         lines_after '^Arduino-CLI source:$' "$location_file" ;;
      --arduino-cli-destination)
         lines_after '^Arduino-CLI destination:$' "$location_file" ;;
      *)
         echo "Error: \`${FUNCNAME[0]}\` received invalid flag \"$1\""
         return 1
   esac
   return 0
}

# This function takes a script name, a string and optionally a flag. It aborts if the given string
# is not a path to an existing readable file.
# If the "--ino"-flag is passed as last argument, the file is is also checked for the
# ".ino"-extension.
function assert_path_validity_ {
   # Aborts if no command line argument has been passed.
   if [ -z "$2" ]; then
      echo "Error: \`$1\` expects more arguments" >&2
      return 1
   fi

   # Aborts if the given string is not a path to an existing readable file.
   if ! [ -f "$2" -a -r "$2" ]; then
      echo "Error: \`$1\` expects an existing readable file as argument" >&2
      return 2
   fi

   # Aborts if the given string is not a path to an existing `.ino`-file.
   if [ "$3" = '--ino' -a "${2: -4}" != '.ino' ]; then
      echo "Error: \`$1\` expects an existing \`.ino\`-file as argument" >&2
      return 3
   fi

   return 0 # Exiting convention
}

# Prompts the user for input until either [ENTER] or [ESC] is pressed. If [ENTER] is pressed, the
# function returns successfully, otherwise it aborts.
function get_approval_or_exit_ {
   # Creates an infinite loop.
   while :; do
      # Reads exactly one character.
      read -s -n 1

      # Checks for [ENTER] or [ESC].
      case $REPLY in
         '') return 0 ;; # Exiting convention
         $'\e') return 1 ;;
      esac
   done
}
