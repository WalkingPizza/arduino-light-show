#!/bin/bash


# TODO: Add documentation to this file


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   # Gets the program file, which should be the only `.ino`-file in the current folder.
   readonly program_file=`ls -1 | egrep '\.ino$'`

   # These files are only temporary.
   readonly current_configuration_file='current_configuration'
   readonly new_configuration_file='new_configuration'
}


#-Functions-------------------------------------#


#-Main-Program----------------------------------#


declare_constants "$@"

./threshold_configuration.sh "$program_file" > "$current_configuration_file" || exit $?

cp "$current_configuration_file" "$new_configuration_file"

vi "$new_configuration_file"

./apply_configuration.sh "$new_configuration_file" "$program_file" "$current_configuration_file" || exit $?

# TODO: Get the Arduino's path
# TODO: Compile and upload the program file to the Arduino
