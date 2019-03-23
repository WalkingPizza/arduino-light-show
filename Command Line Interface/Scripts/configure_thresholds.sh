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
. "$_dot/../Utilities/utilities.sh"
# (Re)sets the dot-variable after imports.
dot="$_dot"


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   # Gets the program file, which should be the only `.ino`-file in the CLI's supporting files
   # folder.
   readonly program_file=`ls -1 "$dot/../"*\.ino`
   # Creates a file in which the configuration can be saved.
   readonly configuration_file=`mktemp`
   # Creates a file in which errors can be collected.
   readonly error_pool=`mktemp`

   # Defines the error message for malformed configuration entries.
   readonly malformed_configuration_message=`cat << END
${print_red}The specified configuration contains malformed entries.$print_normal

Entries must have the form:
${print_yellow}<microphone-identifier>: <threshold-value>$print_normal

The characters $print_yellow"$print_normal and $print_yellow:$print_normal may not be used in \
$print_yellow<microphone-identifier>${print_normal}s.
The $print_yellow<threshold-value>$print_normal must be an integer not starting with a \
${print_yellow}0$print_normal (unless it is exactly ${print_yellow}0$print_normal).
END`

   # Defines the error message for duplicate microphone identifiers.
   readonly duplicate_identifier_message=`cat << END
${print_red}The specified configuration contains duplicate microphone-identifiers.$print_normal

Entries must have the form:
$print_yellow<microphone-identifier>: <threshold-value>$print_normal

No two $print_yellow<microphone-identifier>${print_normal}s may be identical.
END`
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

# Loops until the specified configuration is valid.
while true; do
   # Opens the configuration in Vi to allow the user to edit it.
   vi "$configuration_file"

   # Tries to apply the user-specified configuration to the program file, while saving any error
   # messages.
   "$dot/apply_configuration.sh" "$configuration_file" "$program_file" 2>"$error_pool"
   return_status=$?

   # Checks the success of the previous operation.
   case $return_status in
      # Breaks out of the loop if the operation was successful.
      0) break ;;

      # Sets an appropriate error-message if the operation failed on a recoverable error.
      3) error_message="$malformed_configuration_message" ;;
      4) error_message="$duplicate_identifier_message" ;;

      # Prints an error message and returns on failure if any other error occured.
      *) echo 'Internal error:'; cat "$error_pool"; exit 2 ;; #RS=2
   esac

   # This point is only reached if a recoverable error occured.
   # Prints an error message and prompts the user for reconfiguration or exit.
   clear
   echo -e "$error_message"
   echo -e "\n${print_green}Do you want to try again? [y or n]$print_normal"
   succeed_on_approval_ || exit 3 #RS=3
done;

# TODO: Get the Arduino's path, compile the program file and upload it to the Arduino

exit 0
