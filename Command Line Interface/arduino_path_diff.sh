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
# 0: An Arduino-device was found an printed to stdout.
# 1: No fitting Arduino-device was found.
# 2: The user chose to quit the program.


#-Constants-------------------------------------#


#-Functions-------------------------------------#


#-Main-Program----------------------------------#
