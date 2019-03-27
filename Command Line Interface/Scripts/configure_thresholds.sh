#!/bin/bash

# This script pulls a threshold-configuration from the `.ino`-file in the CLI-directory, lets the
# user configure it, and applies the changes to the `.ino`-file.
# If the user creates a malformed configuration, they are prompted to rewrite it or quit.
#
# Expectations:
# * there is exactly one file ending on ".ino" in the parent directory of this script
#
# Return status:
# 0: success
# 1: invalid number of command line arguments
# 2: internal error
# 3: the user chose to quit the program


#-Preliminaries---------------------------------#


# Gets the directory of this script.
_dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports CLI utilities.
. "$_dot/../Libraries/utilities.sh"
. "$_dot/../Libraries/constants.sh"
# (Re)sets the dot-variable after imports.
dot="$_dot"


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   # Sets the location of the folder holding the program file(s) as the first command line
   # argument, or to the one specified by <utility file: file locations> if none was passed.
   if [ -n "$1" ]; then
      readonly program_folder=${1%/}
   else
      readonly program_folder="$dot/../../`location_of_ --repo-program-directory`"
   fi

   # Gets the program file, which should be the only file in the program-folder ending in ".ino".
   readonly program_file="$program_folder/`ls -1 "$program_folder" | egrep '\.ino$'`"
   # Creates a file in which the configuration can be saved.
   readonly configuration_file=`mktemp`
   # Creates a file in which errors can be collected.
   readonly error_pool=`mktemp`
}


#-Functions-------------------------------------#


# Opens the configuration file in Vi, and allows the user to edit it. The user will be prompted to
# rewrite the configuration as long as it is malformed. They also have the option to quit.
#
# Return status:
# 0: success
# 1: internal error
# 2: the user chose to quit
function carry_out_configuration_editing_ {
   # Loops until the specified configuration is valid or the user quits.
   while true; do
      # Opens the configuration in Vi to allow the user to edit it.
      vi "$configuration_file"

      # Tries to apply the user-specified configuration to the program file, while saving any error
      # messages.
      "$dot/apply_configuration.sh" "$configuration_file" "$program_file" 2>"$error_pool"

      # Checks the success of the previous operation.
      case $? in
         # Breaks out of the loop if the operation was successful.
         0) break ;;

         # Sets an appropriate error-message if the operation failed on a recoverable error.
         3) error_message=`message_for_ --ct-malformed-configuratation` ;;
         4) error_message=`message_for_ --ct-duplicate-identifiers` ;;

         # Prints an error message and returns on failure if any other error occured.
         *) echo 'Internal error:'; cat "$error_pool"; return 1 ;;
      esac

      # This point is only reached if a recoverable error occured.
      # Prints an error message and prompts the user for reconfiguration or exit.
      clear
      echo -e "$error_message"
      echo -e "\n${print_green}Do you want to try again? [y or n]$print_normal"
      succeed_on_approval_ || return 2
   done

   return 0
}

# Tries to set the variables $arduino_fqbn and $arduino_port, by getting those traits from the only
# Arduino currently attached to the computer. If there are no, or multiple Arduinos attached, the
# user will be prompted to fix the issue until there is only one. They also have the option to quit.
#
# Return status:
# 0: success
# 1: internal error
# 2: the user chose to quit
function set_arduino_trait_variables_ {
   # Loops until the specified configuration is valid or the user quits.
   while true; do
      # Gets the Arduino's FQBN and port, while saving any error messages.
      arduino_fqbn=`"$dot/arduino_trait.sh" --fqbn 2>"$error_pool"`
      arduino_port=`"$dot/arduino_trait.sh" --port 2>"$error_pool"`

      case $? in
         # Breaks out of the loop if the operation was successful.
         0) break ;;

         # Sets an appropriate error-message if the operation failed on a recoverable error.
         1) error_message=`message_for_ --ct-no-arduino` ;;
         2) error_message=`message_for_ --ct-multiple-arduinos` ;;

         # Prints an error message and returns on failure if any other error occured.
         *) echo 'Internal error:'; cat "$error_pool"; return 1 ;;
      esac

      # This point is only reached if a recoverable error occured.
      # Prints an error message and prompts the user to un-/replug the Arduino or exit.
      clear
      echo -e "$error_message"
      echo -e "\n${print_green}Do you want to try again? [y or n]$print_normal"
      succeed_on_approval_ || return 2
   done

   return 0
}


#-Main------------------------------------------#


assert_correct_argument_count_ 0 || exit 1 #RS=1
declare_constants "$@"

# Makes sure the temporary files are removed on exiting.
trap "rm '$configuration_file' '$error_pool'" EXIT

# Tries to get the threshold-configuration of the program file, while saving any error messages. If
# that fails, an error message is printed and a return on failure occurs.
if ! "$dot/threshold_configuration.sh" "$program_file" >"$configuration_file" 2>"$error_pool"; then
   echo 'Internal error:'; cat "$error_pool"
   exit 2 #RS=2
fi

carry_out_configuration_editing_ || exit $[$?+1] #RS+2=3
set_arduino_trait_variables_ || exit $[$?+1] #RS1+2=3

# Compiles and uploads the program to the Arduino.
silently- arduino-cli compile --fqbn "$arduino_fqbn" "$program_folder"
silently- arduino-cli upload -p "$arduino_port" --fqbn "$arduino_fqbn" "$program_folder"

exit 0
