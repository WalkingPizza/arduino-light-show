#!/bin/bash


#-Preliminaries---------------------------------#


# Gets the directory of this script.
_dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports testing and CLI utilities.
. "$_dot/utilities.sh"
. "$_dot/../Utilities/utilities.sh"
# (Re)sets the dot-variable after imports.
dot="$_dot"


#-Constants-------------------------------------#


readonly test_command="$dot/../Scripts/arduino_path_usb.sh"
readonly test_device_folder="$dot/test_APU_devices"


#-Setup-----------------------------------------#


echo "Testing \``basename "$test_command"`\` in \`${BASH_SOURCE##*/}\`:"
mkdir "$test_device_folder"


#-Cleanup---------------------------------------#


trap cleanup EXIT
function cleanup {
   rm -r "$test_device_folder"
}


#-Tests-Begin-----------------------------------#


# Test: Usage

silently- "$test_command" 1 2
report_if_last_status_was 1


# Test: Invalid device-folder path

silently- "$test_command" invalid_directory_path
report_if_last_status_was 2


# Test: No "usb"-devices

touch "$test_device_folder/some"
touch "$test_device_folder/us_b"

silently- "$test_command" "$test_device_folder"
report_if_last_status_was 3

rm -r "$test_device_folder/"*


# Test: One "usb"-device

touch "$test_device_folder/usb1"
touch "$test_device_folder/not_us_b"

output=`silently- --stderr "$test_command" "$test_device_folder"`
report_if_output_matches "$output" "$test_device_folder/usb1"

rm -r "$test_device_folder/"*


# Test: Select first of multiple "usb"-devices

touch "$test_device_folder/usb1 with spaces"
touch "$test_device_folder/usb2"
touch "$test_device_folder/not_us_b"

output=`silently-  --stderr "$test_command" "$test_device_folder" <<< '1'`
report_if_output_matches "$output" "$test_device_folder/usb1 with spaces"

rm -r "$test_device_folder/"*


# Test: Select "I don't know" option

touch "$test_device_folder/usb1"
touch "$test_device_folder/usb2"

silently- "$test_command" "$test_device_folder" <<< '3'
report_if_last_status_was 3

rm -r "$test_device_folder/"*


# Test: Select "Quit" option

touch "$test_device_folder/usb1"
touch "$test_device_folder/usb2"

silently- "$test_command" "$test_device_folder" <<< '4'
report_if_last_status_was 4

rm -r "$test_device_folder/"*


#-Tests-End-------------------------------------#


exit 0
