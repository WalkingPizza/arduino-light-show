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
# * 1: No fitting Arduino-device was found.
# * 2: The user chose to quit the program.


#-Constants-------------------------------------#


declare -r dont_know_option='I do not know'
declare -r quit_option='Quit'


#-Functions-------------------------------------#


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

      # Determines whether there are matching "cu"-devices for the "tty"-device in the set of
      # possible devices.
      matched_devices=`egrep -c "^cu$device_without_prefix" <<< "$possible_devices"`

      # If there is no matching "cu"-device, the "tty"-device is added to the set of possible
      # devices.
      if [ $matched_devices -eq 0 ]; then
         possible_devices="$possible_devices tty$device_without_prefix"
      fi
   done

   # Returns the resulting devices via stdout.
   echo "$possible_devices"
}


#-Main-Program----------------------------------#


# Gets all of the devices in the `/dev` folder, seperated by newlines.
# TODO: Change this back to the `/dev` folder
devices=`ls -1 'devices'`

# Filters the `devices` for the lines, which contain the substring "usb" (case insensitive).
usb_devices=`egrep -i -e 'usb' <<< "$devices"`

# Exits on an exit status of `1` if no potential Arduino-device was found.
if [ -z "$usb_devices" ]; then exit 1; fi

# Merges "cu"- and "tty"-devices.
possible_devices=`merge_tty_onto_cu "$usb_devices"`

# Only prompts the user to choose a device if there are multiple possible devices.
if [ `wc -l <<< "$possible_devices"` -gt 1 ]; then
   # Creates the list of options the user can select.
   # BUGGY:
   select_options=("${possible_devices[@]}" "$dont_know_option" "$quit_option")

   # Prompts the user to choose the Arduino's port or another action.
   PS3="Arduino's port: "
   select selection in $select_options; do
      # Either exits the program on reason-specific exit codes, or sets the selected device-path.
      case "$selection" in
         "$dont_know_option")
            exit 1 ;;
         "$quit_option")
            exit 2 ;;
         *)
            device_path="/dev/$selection"
            break ;;
      esac
   done
else
   device_path="/dev/$possible_devices"
fi

# Prints the selected device's path to stdout and exits the script successfully.
echo "$device_path"
exit 0
