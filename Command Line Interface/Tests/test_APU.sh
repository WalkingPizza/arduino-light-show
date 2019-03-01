#!/bin/bash

# Import testing utilities.
. utilities.sh


#-Constant-Declarations-------------------------#


declare -r test_command='../arduino_path_usb.sh'
declare -r test_device_folder='test_APU_devices'


#-Test-Setup------------------------------------#


echo "* Testing \``basename $test_command`\` in \`${BASH_SOURCE##*/}\`:"
silent mkdir $test_device_folder


#-Tests-----------------------------------------#

# Test: Invalid device-folder path

silent $test_command invalid_directory_path
report_if_status_is 1


# Test: No "usb"-devices

# Adds some file to the device folder, not containing the substring "usb".
touch $test_device_folder/some
touch $test_device_folder/us_b

silent $test_command $test_device_folder
report_if_status_is 2

rm -r $test_device_folder/*


# Test: One "usb"-device

touch $test_device_folder/usb1
touch $test_device_folder/not_us_b

output=`$test_command $test_device_folder`
report_if_output_matches "$output" "$test_device_folder/usb1"

rm -r $test_device_folder/*


# Test: Select first of multiple "usb"-devices

touch "$test_device_folder/usb device with spaces"
touch $test_device_folder/not_us_b
touch $test_device_folder/usb1

# TODO: Implement using TCL's expect

rm -r $test_device_folder/*


# Test: Select "I don't know" option

# TODO: Implement using TCL's expect


# Test: Select "Quit" option

# TODO: Implement using TCL's expect


#-Test-Cleanup------------------------------------#


rm -r $test_device_folder
