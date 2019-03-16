#!/bin/bash

# This script serves as a library of functions to be used by other scripts in the CLI. It can be
# "imported" via sourcing. The script makes use of other files, namely:
# * file_locations
# * regular_expressions
# ... which are expected to be in the same directory.
# It should be noted that this script activates alias expansion.


#-Preliminaries---------------------------------#


# Turns on alias-expansion explicitly as users of this script will probably be non-interactive
# shells, while also clearing all existing aliases.
shopt -s expand_aliases
unalias -a

# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)


#-Constants-------------------------------------#


# The file referenced for getting regular expression patterns.
readonly _regex_file="$dot/regular_expressions"
# The file referenced for getting the (intended) locations of certain files.
readonly _location_file="$dot/file_locations"


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
function silently- {
   # Runs <command> and redirects output differently depending on the given <flag>.
   case "$1" in
      --stdout) "${@:2}" 1> /dev/null ;;
      --stderr) "${@:2}" 2> /dev/null ;;
             *) "$@"     &> /dev/null ;;
   esac

   # Propagates the return status of <command>.
   return $?
}

# Prints all of the lines of <file> immediately following the line containing only <string> upto the
# next empty line. It is expected for there to be exactly one line containing only <string>.
#
# Arguments:
# * <string>
# * <file>
#
# Return status:
# 0: success
# 1: there were less or more than one line exactly matching <string> in <file>
function lines_after_unique_ {
   # Gets all of the lines in <file> exactly matching <string>.
   local -r match_line=`egrep -n "^$1\$" "$2"`

   # Makes sure that there was exactly one match line, or prints an error and returns on failure.
   if ! [ `wc -l <<< "$match_line"` -eq 1 ]; then
      echo "Error: \`${FUNCNAME[0]}\` did not match exactly one line" >&2
      return 1
   fi

   # Gets the line number immediately following the line of <string>'s match in <file>.
   local -r list_start=$[`cut -d : -f 1 <<< "$match_line"` + 1]

   # Prints all of the lines in <file> starting from "$list_start", until an empty line is reached.
   while read -r line; do
      [ -n "$line" ] && echo "$line" || break
   done <<< "`tail -n "+$list_start" "$2"`"

   return 0
}

# Prints the regular expression pattern used to match a type of item identified by a given <flag>.
# All patterns are taken from the <utility file: regular expressions>.
#
# Arguments:
# * <flag>
#
# Return status:
# 0: success
# 1: the given <flag> is invalid
# 2: internal error
function regex_for_ {
   # The string used to search the regex-file for a certain pattern.
   local regex_identifier

   # Sets the search string according to the given flag, or prints an error and returns on failure
   # if an unknown flag was passed.
   case "$1" in
      --header-candidate)               regex_identifier='Threshold declaration header candidate:';;
      --header)                         regex_identifier='Threshold declaration header:'          ;;
      --body)                           regex_identifier='Threshold declaration body:'            ;;
      --end-tag)                        regex_identifier='Threshold declarations end tag:'        ;;
      --configuration-entry)            regex_identifier='Threshold configuration entry:'         ;;
      --uninstall-arduino-cli-flag-tag) regex_identifier='Uninstall Arduino-CLI flag tag:'        ;;
      *)
         echo "Error: \`${FUNCNAME[0]}\` received invalid flag \"$1\"" >&2
         return 1 ;;
   esac

   # Prints the lines following the search string in the regex-file, or returns on failure if that
   # operation fails.
   lines_after_unique_ "$regex_identifier" "$_regex_file" || return 2

   return 0
}

# These locations are relative to the CLI-folder if contained within it.

# Prints the path of files/directories identified by a given <flag>.
# Paths to files/directories within the CLI-directory are given relative to the CLI-directory.
# Paths to files/directories within the repository but not the CLI-directory are given relative to
# the repository.
# Paths outside of the repository are given as absolute, with tilde expansion performed beforehand.
#
# All paths are taken from the <utility file: file paths>.
#
# Arguments:
# * <flag>
#
# Return status:
# 0: success
# 1: the given <flag> is invalid
# 2: internal error
function location_of_ {
   # The string used to search the location-file for certain paths.
   local location_identifier

   # Sets the search string according to the given flag, or prints an error and returns on failure
   # if an unknown flag was passed.
   case "$1" in
      --repo-cli-directory)               location_identifier='Repository CLI-directory:'        ;;
      --cli-command)                      location_identifier='CLI-command:'                     ;;
      --cli-uninstaller)                  location_identifier='CLI-uninstaller:'                 ;;
      --cli-scripts)                      location_identifier='CLI-scripts:'                     ;;
      --cli-utilities)                    location_identifier='CLI-utilities:'                   ;;
      --cli-command-destination)          location_identifier='CLI-command destination:'         ;;
      --cli-supporting-files-destination) location_identifier='CLI-supporting files destination:';;
      --arduino-cli-source)               location_identifier='Arduino-CLI source:'              ;;
      --arduino-cli-destination)          location_identifier='Arduino-CLI destination:'         ;;
      *)
         echo "Error: \`${FUNCNAME[0]}\` received invalid flag \"$1\"" >&2
         return 1 ;;
   esac

   # Gets the lines matched in the location-file for the given identifier, or returns on failure if
   # that operation fails.
   local -r raw_paths=`lines_after_unique_ "$location_identifier" "$_location_file"` || return 2

   # Performs explicit tilde expansion and prints the resulting paths.
   while read path; do
      [ "${path:0:1}" = '~' ] && echo "$HOME${path:1}" || echo "$path"
   done <<< "$raw_paths"

   return 0
}

# Returns on failure if a given <string> is not a path to an existing readable file.
# If the <flag> is passed as last argument, the file is is also checked for the ".ino"-extension.
#
# Arguments:
# * <script name> passed automatically by the alias
# * <string>
# * <flag> optional, possible values: "--ino"
#
# Return status:
# 0: success
# 1: the given string is not a path to an existing readable file
# 2: the given <flag> is invalid
# 3: the <flag> was passed and the given path is not a `.ino`-file
alias assert_path_validity_='_assert_path_validity_ "${BASH_SOURCE##*/}" '
function _assert_path_validity_ {
   # Makes sure the given string is a path to an existing readable file, or prints an error and
   # returns on failure.
   if ! [ -f "$2" -a -r "$2" ]; then
      echo "Error: \"$2\" is not an existing readable file" >&2
      return 1
   fi

   # Checks if a <flag> was passed.
   if [ -n "$3" ]; then
      # Makes sure the flag is valid or prints an error and returns on failure.
      if [ "$3" != '--ino' ]; then
         echo "Error: \`${FUNCNAME[0]}\` received invalid flag \"$3\"" >&2
         return 2
      fi

      # Makes sure the given <string> ends in ".ino", or prints an error and returns on failure.
      if [ "${2: -4}" != '.ino' ]; then
         echo "Error: \"$2\" is not a \`.ino\`-file" >&2
         return 3
      fi
   fi

   return 0
}

# Prompts the user for input until either [ENTER] or [ESC] is pressed. If [ENTER] is pressed, the
# function returns successfully, otherwise it returns on failure.
#
# Return status:
# 0: the user pressed [ENTER]
# 1: the user pressed [ESC]
function succeed_on_approval_ {
   # Creates an infinite loop.
   while :; do
      # Reads exactly one character.
      read -s -n 1

      # Checks for [ENTER] or [ESC] and returns if either one of them was entered.
      case $REPLY in
         '') return 0 ;;
         $'\e') return 1 ;;
      esac
   done
}
