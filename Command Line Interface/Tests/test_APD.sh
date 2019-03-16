#!/bin/bash


#-Preliminaries---------------------------------#


# Gets the directory of this script.
_dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports testing and CLI utilities.
. "$_dot/utilities.sh"
. "$_dot/../Utilities/utilities.sh"
# (Re)sets the dot-variable after imports.
dot="$_dot"

#-Constant-Declarations-------------------------#


readonly test_command="$dot/../Scripts/arduino_path_diff.sh"
readonly test_device_folder="$dot/test_APD_devices"


#-Test-Setup------------------------------------#


echo "Testing \``basename "$test_command"`\` in \`${BASH_SOURCE##*/}\`:"
silently- mkdir "$test_device_folder"


#-Tests-----------------------------------------#


# Test: Invalid device-folder path

silently- "$test_command" invalid_directory_path
report_if_last_status_was 1


# Test: No added device

# TODO: Implement using TCL's expect


# Test: Multiple added devices

# TODO: Implement using TCL's expect


# Test: One added device

# TODO: Implement using TCL's expect


# Test: One mergable added device

# TODO: Implement using TCL's expect


#-Test-Cleanup------------------------------------#


silently- rm -r "$test_device_folder"
exit 0
