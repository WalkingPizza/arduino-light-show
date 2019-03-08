#!/bin/bash

# Gets the directory of this script.
dot="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Imports testing utilities.
. "$dot/utilities.sh"


#-Constant-Declarations-------------------------#


readonly test_command="$dot/../arduino_path_diff.sh"
readonly test_device_folder="$dot/test_APD_devices"


#-Test-Setup------------------------------------#


echo "Testing \``basename "$test_command"`\` in \`${BASH_SOURCE##*/}\`:"
silent mkdir "$test_device_folder"


#-Tests-----------------------------------------#


# Test: Invalid device-folder path

silent "$test_command" invalid_directory_path
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


silent rm -r "$test_device_folder"
exit 0
