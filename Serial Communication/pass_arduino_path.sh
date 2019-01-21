#!/bin/bash

# This script scans the `/dev` folder for any devices that contain "usb" in
# their name. It lets the user choose, which of the devices represents an
# Arduino, and calls a given program with the Arduino's device-path.
#
# If no device with a "usb"-substring in its name is found, an error is printed,
# and a return value of `1` is set.
#
# If there is only one device containing the "usb"-substring, it is assumed to
# be the correct one, so the user is not asked to choose a device.
#
# If there are multiple devices differing only in the prefix "cu" or "tty", the
# "tty"-version is filtered out.
# Explaination: https://stackoverflow.com/questions/8632586

# Gets all of the devices in the `/dev` folder, seperated by newlines.
devices=$(ls -1 /dev)

# Filters the `devices` for the lines, which contain the substring "usb" (case
# insensitive).
usb_devices=$(echo "$devices" | grep -i -e "usb")

# Prints an error if no Arduino-device was found, and exits on a return value of
# `1`.
if [ -z "$usb_devices" ]; then
   echo "Error: No device fitting for an Arduino was detected." >&2
   exit 1
fi




# TODO:
# delete occurances of "tty.[???]" if an equivalent "cu.[???]" exists.




# Only prompts the user to choose a device if there are multiple usb devices.
if [ ${#usb_devices[@]} -gt 1 ]; then
   # Prompts the user to choose from the `usb_devices`.
   echo "Which USB-port is the Arduino attached to?"
   PS3="Port: "
   select device in $usb_devices; do
      device_path="/dev/$device"
      break
   done
else
   device_path="/dev/$usb_devices"
fi

# Clears the screen before executing the next program.
clear

# Calls the specified program, with the chosen usb-device's file path as
# command line argument.
"./"$1 $device_path
return 0
