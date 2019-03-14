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

# This function takes a string and a file. It returns all of the lines immediately following the
# line containing only the given string upto the next empty line.
# The funtion expects there to be exactly one match of the given string in the file.
function lines_after_unique_ {
   local match_line=`egrep -n "^$1\$" "$2"`

   # Makes sure that there was exactly one match line.
   if ! [ `wc -l <<< "$match_line"` -eq 1 ]; then
      echo "Error: \`${FUNCNAME[0]}\` did not match exactly one line"
      exit 1
   fi

   local list_start=$(( `cut -d : -f 1 <<< "$match_line"` + 1 ))

   while read -r line; do
      [ -n "$line" ] && echo "$line" || break
   done <<< "`tail -n "+$list_start" "$2"`"
}

function regex_for {
   local regex_file="$dot/regular_expressions"

   case "$1" in
      --header-candidate)
         lines_after_unique_ 'Threshold declaration header candidate:' "$regex_file" ;;
      --header)
         lines_after_unique_ 'Threshold declaration header:' "$regex_file" ;;
      --body)
         lines_after_unique_ 'Threshold declaration body:' "$regex_file" ;;
      --end-tag)
         lines_after_unique_ 'Threshold declarations end tag:' "$regex_file" ;;
      --configuration-entry)
         lines_after_unique_ 'Threshold configuration entry:' "$regex_file" ;;
      --uninstall-arduino-cli-flag-tag)
         lines_after_unique_ 'Uninstall Arduino-CLI flag tag:' "$regex_file" ;;
      *)
         echo "Error: \`${FUNCNAME[0]}\` received invalid flag \"$1\""
         return 1
   esac
   return 0
}

# These locations are relative to the CLI-folder if contained within it.
function location_of {
   local location_file="$dot/file_locations"
   local raw_paths=''

   case "$1" in
      --repo-cli-directory)
         raw_paths=`lines_after_unique_ 'Repository CLI-directory:' "$location_file"` ;;
      --cli-command)
         raw_paths=`lines_after_unique_ 'CLI-command:' "$location_file"` ;;
      --cli-uninstaller)
         raw_paths=`lines_after_unique_ 'CLI-uninstaller:' "$location_file"` ;;
      --cli-scripts)
         raw_paths=`lines_after_unique_ 'CLI-scripts:' "$location_file"` ;;
      --cli-utilities)
         raw_paths=`lines_after_unique_ 'CLI-utilities:' "$location_file"`;;
      --cli-command-destination)
         raw_paths=`lines_after_unique_ 'CLI-command destination:' "$location_file"` ;;
      --cli-supporting-files-destination)
         raw_paths=`lines_after_unique_ 'CLI-supporting files destination:' "$location_file"` ;;
      --arduino-cli-source)
         raw_paths=`lines_after_unique_ 'Arduino-CLI source:' "$location_file"` ;;
      --arduino-cli-destination)
         raw_paths=`lines_after_unique_ 'Arduino-CLI destination:' "$location_file"` ;;
      *)
         echo "Error: \`${FUNCNAME[0]}\` received invalid flag \"$1\""
         return 1
   esac

   # Performs tilde expansion and prints the result.
   while read path; do
      [ "${path:0:1}" = '~' ] && echo "$HOME${path:1}" || echo "$path"
   done <<< "$raw_paths"
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
