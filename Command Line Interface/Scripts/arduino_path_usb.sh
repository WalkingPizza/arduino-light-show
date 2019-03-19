#!/bin/bash

# This script scans a given device-folder for any devices that contain "usb" in their name. It lets
# the user choose which of theses devices represents an Arduino, and prints the selected device's
# path to stdout.
# If there is only one device containing the "usb"-substring, it is assumed to be the correct one,
# so the user is not asked to choose a device.
#
# Arguments:
# * <device folder path> optional, defaults to /dev
#
# Return status:
# 0: success
# 1: invalid number of command line arguments
# 2: the given device-folder does not exits, or can't be read
# 3: no fitting Arduino-device could be determined
# 4: the user chose to quit the program


#-Preliminaries---------------------------------#


# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports CLI utilities.
. "$dot/../Utilities/utilities.sh"


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   # Sets the device-folder as the first command line argument, or `/dev` if none was passed.
   [ -n "$1" ] && readonly device_folder=${1%/} || readonly device_folder='/dev'

   # Defines strings appearing as options to the user when propmted to select the Arduino's port.
   readonly dont_know_option="I don't know"
   readonly quit_option='Quit'
}


#-Main------------------------------------------#


assert_correct_argument_count_ 0 1 '<device folder path> optional' || exit 1 #RS=1
declare_constants "$@"

# Makes sure that the given path is a readable directory, or an error is printed and a return on
# failure occurs.
if ! [ -d "$device_folder" -a -r "$device_folder" ]; then
   echo "Error: \`$device_folder\` is not a path to a readable directory" >&2
   exit 2 #RS=2
fi

# Gets all of the files (devices) in the the device-folder, which contain the substring "usb" (case
# insensitive).
readonly usb_devices=`ls -1 "$device_folder" | egrep -i 'usb'`

# Prints an error message and returns on failure if no potential Arduino-device was found.
if [ -z "$usb_devices" ]; then
   echo "Error: no potential Arduino-device detected in \`$device_folder\`" >&2
   exit 3 #RS=3
fi

# TODO: does this make sense
# Merges "cu"- and "tty"-devices.
readonly possible_devices=`merge_tty_onto_cu "$usb_devices"`

# Prints the possible device to stdout and returns on success, if there only is one.
[ `wc -l <<< "$possible_devices"` -gt 1 ] || { echo "$device_folder/$possible_devices"; exit 0; }

# Creates the list of options the user can select.
readonly select_options=`echo -e "$possible_devices\n$dont_know_option\n$quit_option"`

# Prompts the user to choose the Arduino's port or another action.
echo "Choose the Arduino's port:" >&2
PS3="> "; IFS=$'\n'
select selection in $select_options; do
   # Either exits the program on reason-specific exit codes, or prints the selected device-path.
   case "$selection" in
      $dont_know_option) exit 3 ;; #RS=3
           $quit_option) exit 4 ;; #RS=4
                      *) echo "$device_folder/$selection"; break ;;
   esac
done

exit 0
