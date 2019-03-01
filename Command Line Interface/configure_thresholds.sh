#!/bin/bash

# This script...
#
# Exit status:
# * 0:
# * 1:
# * 2:

# Exiting convention:
# Functions whose names contain a trailing underscore, require exiting the script on non-zero exit
# status. This only requires action when this function is run in a subshell. So e.g. if
# `my_function_` returns an error code of 1, the program should be exited.


#-Constants-------------------------------------#


declare -r program_file=`ls -1 | egrep '\.ino$'`

# These files are only temporary
declare -r current_configuration_file='current_configuration'
declare -r new_configuration_file='new_configuration'


#-Functions-------------------------------------#


#-Main-Program----------------------------------#


./threshold_configuration.sh "$program_file" > "$current_configuration_file" || exit $?

cp "$current_configuration_file" "$new_configuration_file"

vi "$new_configuration_file"

./apply_configuration.sh "$new_configuration_file" "$program_file" "$current_configuration_file" || exit $?

# TODO: Get the Arduino's path
# TODO: Compile and upload the program file to the Arduino
