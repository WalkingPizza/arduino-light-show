#!/bin/bash

# This script prompts the user to briefly un- and then replug the Arduino. By monitoring the '/dev'
# folder, it should therefore be possible to track, which device was added (which would then be the
# Arduino).
# If a suitable device was detected, its path is printed to stdout. Otherwise the program exits on a
# non-zero exit status.
#
# Exit status:
# * 0: An Arduino-device was found an printed to stdout.
# * 1: The given device-folder does not exits, or can't be read
# * 2: No fitting Arduino-device was found.
# * 3: Multiple fitting Arduino-devices were found.
# * 4: The user chose to quit the program.

# Exiting convention:
# Functions whose names contain a trailing underscore, require exiting the script on non-zero exit
# status. This only requires action when this function is run in a subshell. So e.g. if
# `my_function_` returns an error code of 1, the program should be exited.


#-Constants-------------------------------------#


if [ -n "$1" ]; then
   declare -r device_folder=${1%/};
else
   declare -r device_folder='/dev'
fi


#-Functions-------------------------------------#


function get_approval_or_exit_ {
   while :; do
      read -s -n 1

      case $REPLY in
         '') break ;;
         $'\e') exit 4 ;;
      esac
   done

   return 0 # Exiting convention
}

# This function takes a list of device-paths. It prints out the same list, with any "tty"-prefixed
# being merged onto a corresponding "cu"-prefixed device (if one exists).
function merge_tty_onto_cu {
   # Gets all of the devices whose names start with "tty".
   local tty_devices=`egrep '^tty' <<< "$1"`

   # Initializes the set of possible devices, with those whose name does not start with "tty".
   local possible_devices=`egrep -v '^tty' <<< "$1"`

   # Adds only those "tty"-devices to the `possible_devices`, that do not have an equivalent "cu"
   # device.
   for tty_device in "$tty_devices"; do
      # Removes the "tty"-prefix from the device's name.
      local device_without_prefix=${tty_device:3}

      # If there is no matching "cu"-device, the "tty"-device is added to the set of possible
      # devices.
      egrep -q "^cu$device_without_prefix" <<< "$possible_devices"
      if [ $? -eq 0 ]; then
         possible_devices="$possible_devices tty$device_without_prefix"
      fi
   done

   # Returns the resulting devices via stdout.
   echo "$possible_devices"
}


#-Main-Program----------------------------------#


# Asserts that the given path is a readable directory.
if ! [ -d "$device_folder" -a -r "$device_folder" ]; then
   echo "Error: \`$device_folder\` is not a valid directory path" >&2
   exit 1
fi

# Makes sure the devices is unplugged.
echo "Unplug the Arduino then confirm [ENTER], or quit [ESC]" >&2
get_approval_or_exit_

# Gets the list of devices without the Arduino.
devices_when_unplugged=`ls -1 "$device_folder"`

# Makes sure the devices is plugged in.
echo "Plug in the Arduino then confirm [ENTER], or quit [ESC]" >&2
get_approval_or_exit_

# Gets the list of devices with the Arduino.
devices_when_plugged_in=`ls -1 "$device_folder"`

# Gets the list of devices added by plugging in the Arduino.
added_devices=`comm -23 <(echo "$devices_when_unplugged") <(echo "$devices_when_plugged_in")`

# Aborts if no new devices could be found.
if [ -z "$added_devices" ]; then
   echo "Error: no port for the Arduino could be detected." >&2
   exit 2
fi

# Merges "tty"-prefixed devices onto equivalent "cu"-prefixed devices.
consolidated_new_devices=`merge_tty_onto_cu "$added_devices"`

# Aborts if multiple new devices were found.
if [ `wc -l <<< "$consolidated_new_devices"` -gt 1 ]; then
   echo "Error: multiple potential ports for the Arduino were detected." >&2
   exit 3
fi

# Prints the detected port to stdout.
echo "$device_folder/$added_devices"
exit 0
