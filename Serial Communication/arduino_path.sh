#!/bin/bash

# This script scans the `/dev` folder for any devices that contain "usb" in
# their name. It lets the user choose which of the devices represents an
# Arduino, and prints the selected device's path to stdout.
#
# If no device with a "usb"-substring in its name is found, an error is printed,
# and a return value of `1` is set.
#
# If there is only one device containing the "usb"-substring, it is assumed to
# be the correct one, so the user is not asked to choose a device.
#
# If there are multiple devices differing only in the prefix "cu" or "tty", the
# "tty"-version is filtered out.
# Explanations:
# * https://stackoverflow.com/questions/8632586
# * https://learn.sparkfun.com/tutorials/terminal-basics/tips-and-tricks

function merge_tty_onto_cu {
   # Gets all of the devices whose names start with "tty".
   local tty_devices=$(grep -e "^tty" <<< "$1")

   # Initializes the set of possible devices, with those whose name does not
   # start with "tty".
   local possible_devices=$(grep --invert-match -e "^tty" <<< "$1")

   # Adds only those "tty"-devices to the `possible_devices`, that do not have
   # an equivalent "cu"-device.
   for tty_device in "$tty_devices"; do
      # Removes the "tty"-prefix from the device's name.
      local device_without_prefix=${tty_device:3}

      # Determines whether there are matching "cu"-devices for the
      # "tty"-device in the set of possible devices.
      matched_devices=$(
         grep -c -e "^cu$device_without_prefix" <<< "$possible_devices"
      )

      # If there is no matching "cu"-device, the "tty"-device is added to the
      # set of possible devices.
      if [ $matched_devices -eq "0" ]; then
         possible_devices="$possible_devices tty$device_without_prefix"
      fi
   done

   # Returns the resulting devices via stdout.
   echo "$possible_devices"
}

# Gets all of the devices in the `/dev` folder, seperated by newlines.
devices=$(ls -1 /dev)

# Filters the `devices` for the lines, which contain the substring "usb" (case
# insensitive).
usb_devices=$(grep -i -e "usb" <<< "$devices")

# Prints an error if no Arduino-device was found, and exits on a return value of
# `1`.
if [ -z "$usb_devices" ]; then
   echo "Error: No device fitting for an Arduino was detected." >&2
   exit 1
fi

# Merges "cu"- and "tty"-devices, and captures the result in an array.
possible_devices=($(merge_tty_onto_cu $usb_devices))

# Only prompts the user to choose a device if there are multiple usb devices.
if [ ${#possible_devices[@]} -gt 1 ]; then
   # Prompts the user to choose from the `usb_devices`.
   PS3="Arduino's port: "
   select device in $possible_devices; do
      device_path="/dev/$device"
      break
   done
else
   device_path="/dev/$possible_devices"
fi

# Prints the selected device's path to stdout and exits the script successfully.
echo $device_path
exit 0
