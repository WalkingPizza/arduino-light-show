#!/bin/bash

# Import testing utilities.
. utilities.sh


#-Constant-Declarations-------------------------#


declare -r test_command='../arduino_path_diff.sh'
declare -r test_device_folder='test_APD_devices'


#-Test-Setup------------------------------------#


echo "* Testing \``basename $test_command`\` in \`${BASH_SOURCE##*/}\`:"
silent mkdir $test_device_folder


#-Tests-----------------------------------------#


# Test: Invalid device-folder path

silent $test_command invalid_directory_path
report_if_status_is 1


# Test: No added device

# TODO: Implement using TCL's expect


# Test: Multiple added devices

# TODO: Implement using TCL's expect


# Test: One added device

# TODO: Implement using TCL's expect


# Test: One mergable added device

# TODO: Implement using TCL's expect


#-Test-Cleanup------------------------------------#


rm -r $test_device_folder
