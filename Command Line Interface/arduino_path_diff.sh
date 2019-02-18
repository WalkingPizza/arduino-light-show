#!/bin/bash

# This script prompts the user to briefly un- and then replug the Arduino. By monitoring the '/dev'
# folder, it should therefore be possible to track, which device was added (which would then be the
# Arduino).
# If a suitable device was detected, its path is printed to stdout. Otherwise the program exits on a
# non-zero exit status.
#
# Exit status:
# 0: An Arduino-device was found an printed to stdout.
# 1: No fitting Arduino-device was found.
# 2: The user chose to quit the program.


#-Constants-------------------------------------#


if [ -n "$1" ]; then
   declare -r device_folder=${1%/};
else
   declare -r device_folder='/dev'
fi


#-Functions-------------------------------------#


#-Main-Program----------------------------------#
