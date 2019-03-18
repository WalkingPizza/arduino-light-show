#!/bin/bash

# This script scans the `/dev` folder for any devices that contain "usb" in their name. It lets the
# user choose which of the devices represents an Arduino, and prints the selected device's path to
# stdout.
# The user also has the option to state that they don't know which is the correct device, or to
# simply quit the command.
#
# If there is only one device containing the "usb"-substring, it is assumed to be the correct one,
# so the user is not asked to choose a device.
#
# If there are multiple devices differing only in the prefix "cu" or "tty", the "tty"-version is
# filtered out.
# Explanations:
# * https://stackoverflow.com/questions/8632586
# * https://learn.sparkfun.com/tutorials/terminal-basics/tips-and-tricks
#
# Exit status:
# * 0: An Arduino-device was found an printed to stdout.
# * 1: The given device-folder does not exits, or can't be read
# * 2: No fitting Arduino-device was found.
# * 3: The user chose to quit the program.


#-Preliminaries---------------------------------#


# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports CLI utilities.
. "$dot/../Utilities/utilities.sh"


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   # Sets the device-folder as the first command line argument, or `/dev` if none was passed.
   if [ -n "$1" ]; then
      readonly device_folder=${1%/};
   else
      readonly device_folder='/dev'
   fi

   # Defines strings appearing as options in the select statement below.
   readonly dont_know_option="I don't know"
   readonly quit_option='Quit'
}


#-Main-Program----------------------------------#


declare_constants "$@"

# Asserts that the given path is a readable directory.
if ! [ -d "$device_folder" -a -r "$device_folder" ]; then
   echo "Error: \`$device_folder\` is not a valid directory path" >&2
   exit 1
fi

# Gets all of the files (devices) in the the device-folder.
devices=`ls -1 "$device_folder"`

# Filters the devices for those, which contain the substring "usb" (case insensitive).
usb_devices=`egrep -i 'usb' <<< "$devices"`

# Prints an error message and exits if no potential Arduino-device was found.
if [ -z "$usb_devices" ]; then
   echo "Error: no potential Arduino-device detected in \`$device_folder\`" >&2
   exit 2
fi

# Merges "cu"- and "tty"-devices.
possible_devices=`merge_tty_onto_cu "$usb_devices"`

# Prints out the possible device to stdout, if there only is one.
[ `wc -l <<< "$possible_devices"` -gt 1 ] || { echo "$device_folder/$possible_devices"; exit 0; }

# Creates the list of options the user can select.
select_options=`echo -e "$possible_devices\n$dont_know_option\n$quit_option"`

# Sets up the conditions nessecary for the following select-statement.
PS3="> "; IFS=$'\n'

# Prompts the user to choose the Arduino's port or another action.
echo "Choose the Arduino's port or another option:" >&2
select selection in $select_options; do
   # Either exits the program on reason-specific exit codes, or sets the selected device-path.
   case "$selection" in
      $dont_know_option) exit 2 ;;
           $quit_option) exit 3 ;;
                      *) device_path="$device_folder/$selection"; break ;;
   esac
done

# Prints the selected device's path to stdout and exits the script successfully.
echo "$device_path"
exit 0
