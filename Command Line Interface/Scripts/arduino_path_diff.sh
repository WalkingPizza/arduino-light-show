#!/bin/bash

# This script prompts the user to briefly un- and then replug the Arduino. By monitoring a given
# device folder (/dev by default) it should therefore be possible to track, which device was added
# (which would then be assumed to be the Arduino). If a suitable device is detected, its path is
# printed to stdout.
#
# Arguments:
# <device folder path> optional
#
# Return status:
# 0: success
# 1: invalid number of command line arguments
# 2: the given device-folder does not exits, or can't be read
# 3: the user chose to quit the program
# 4: no fitting Arduino-device was found
# 5: multiple fitting Arduino-devices were found


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
}


#-Main-Program----------------------------------#


assert_correct_argument_count_ 0 1 '<device folder path> optional' || exit 1 #RS=1
declare_constants "$@"

# Makes sure that the given path is a readable directory, or an error is printed and a return on
# failure occurs.
if ! [ -d "$device_folder" -a -r "$device_folder" ]; then
   echo "Error: \`$device_folder\` is not a path to a readable directory" >&2
   exit 2 #RS=2
fi

# Makes sure the devices is unplugged.
echo "Unplug the Arduino then confirm [y], or quit [n]" >&2
succeed_on_approval_ || exit 3 #RS=3

# Gets the list of devices without the Arduino.
devices_before=`ls -1 "$device_folder"`

# Makes sure the devices is plugged in.
echo "Plug in the Arduino then confirm [y], or quit [n]" >&2
succeed_on_approval_ || exit 3 #RS=3

# Gets the list of devices with the Arduino plugged in.
devices_after=`ls -1 "$device_folder"`

# Gets the list of devices added by plugging in the Arduino.
added_devices=`comm -23 <(sort <<< "$devices_after") <(sort <<< "$devices_before")`

# If no new devices could be found an error is printed and a return on failure occurs.
if [ -z "$added_devices" ]; then
   echo "Error: no port for the Arduino could be detected" >&2
   exit 4 #RS=4
fi

# TODO: figure out if this makes sense
# Merges "tty"-prefixed devices onto equivalent "cu"-prefixed devices.
consolidated_new_devices=`merge_tty_onto_cu "$added_devices"`

# If multiple new devices were found an error is printed and a return on failure occurs.
if [ `wc -l <<< "$consolidated_new_devices"` -gt 1 ]; then
   echo "Error: multiple potential ports for the Arduino were detected" >&2
   exit 5 #RS=5
fi

# Prints the detected port to stdout.
echo "$device_folder/$consolidated_new_devices"
exit 0
