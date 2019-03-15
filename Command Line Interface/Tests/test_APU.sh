#!/bin/bash


#-Preliminaries---------------------------------#


# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports testing utilities.
. "$dot/utilities.sh"


#-Constant-Declarations-------------------------#


readonly test_command="$dot/../Scripts/arduino_path_usb.sh"
readonly test_device_folder="$dot/test_APU_devices"


#-Test-Setup------------------------------------#


echo "* Testing \``basename "$test_command"`\` in \`${BASH_SOURCE##*/}\`:"
silent- mkdir "$test_device_folder"


#-Tests-----------------------------------------#


# Test: Invalid device-folder path

silent- "$test_command" invalid_directory_path
report_if_last_status_was 1


# Test: No "usb"-devices

# Adds some file to the device folder, not containing the substring "usb".
touch "$test_device_folder/some"
touch "$test_device_folder/us_b"

silent- "$test_command" "$test_device_folder"
report_if_last_status_was 2

silent- rm -r "$test_device_folder/"*


# Test: One "usb"-device

touch "$test_device_folder/usb1"
touch "$test_device_folder/not_us_b"

output=`"$test_command" "$test_device_folder"`
report_if_output_matches "$output" "$test_device_folder/usb1"

silent- rm -r "$test_device_folder/"*


# Test: Select first of multiple "usb"-devices

touch "$test_device_folder/usb device with spaces"
touch "$test_device_folder/not_us_b"
touch "$test_device_folder/usb1"

# TODO: Implement using TCL's expect

silent- rm -r "$test_device_folder/"*


# Test: Select "I don't know" option

# TODO: Implement using TCL's expect


# Test: Select "Quit" option

# TODO: Implement using TCL's expect


#-Test-Cleanup------------------------------------#


silent- rm -r "$test_device_folder"
exit 0
