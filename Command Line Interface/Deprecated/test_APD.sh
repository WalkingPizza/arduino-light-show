#!/bin/bash


#-Preliminaries---------------------------------#


# Gets the directory of this script.
_dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports testing and CLI utilities.
. "$_dot/../Libraries/test_utilities.sh"
. "$_dot/../Libraries/utilities.sh"
# (Re)sets the dot-variable after imports.
dot="$_dot"


#-Constant--------------------------------------#


readonly test_command="$dot/../Scripts/arduino_path_diff.sh"
readonly test_device_folder="$dot/test_APD_devices"


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


# Test: User quit

silently- "$test_command" "$test_device_folder" <<< 'n'
report_if_last_status_was 3


# Test: No added device

silently- "$test_command" "$test_device_folder" <<< 'yy'
report_if_last_status_was 4


# Test: Multiple added devices

interactively- silently- "$test_command" "$test_device_folder" << INTERACTION
# Responds to the first prompt and waits the duration expected for the test command to reach the
# first prompt and process it.
echo 'y'; sleep 1

# Adds new files to the devices folder.
touch "$test_device_folder/added_file_1"
touch "$test_device_folder/added_file_2"

# Waits the duration expected for the test command to produce its next prompt and then responds.
sleep 1; echo 'y'
INTERACTION

report_if_last_status_was 5
rm -r "$test_device_folder/"*


# Test: One added device

output=`
interactively- silently- --stderr "$test_command" "$test_device_folder" << INTERACTION
# Responds to the first prompt and waits the duration expected for the test command to reach the
# first prompt and process it.
echo 'y'; sleep 1

# Adds new files to the devices folder.
touch "$test_device_folder/added_file"

# Waits the duration expected for the test command to produce its next prompt and then responds.
sleep 1; echo 'y'
INTERACTION
`

report_if_output_matches "$output" "$test_device_folder/added_file"
rm -r "$test_device_folder/"*


# Test: One mergable added device

output=`
interactively- silently- --stderr "$test_command" "$test_device_folder" << INTERACTION
# Responds to the first prompt and waits the duration expected for the test command to reach the
# first prompt and process it.
echo 'y'; sleep 1

# Adds new files to the devices folder.
touch "$test_device_folder/tty.added_file"
touch "$test_device_folder/cu.added_file"

# Waits the duration expected for the test command to produce its next prompt and then responds.
sleep 1; echo 'y'
INTERACTION
`

report_if_output_matches "$output" "$test_device_folder/cu.added_file"
rm -r "$test_device_folder/"*


#-Tests-End-------------------------------------#


exit 0
