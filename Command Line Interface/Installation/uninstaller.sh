#!/bin/bash

# This script uninstalls all of the components installed for the Arduino Light Show CLI to run.
# Files are only moved to the trash-folder, so the process can be undone.

# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports CLI utilities.
. "$dot/../Utilities/utilities.sh"


#-Constants-------------------------------------#


# UNINSTALL-ARDUINO-CLI-FLAG
readonly uninstall_arduino_cli=false

# Sets the trash folder path according to the operating system.
case "`uname -s`" in
   Darwin*) readonly trash_folder='~/.Trash' ;;
   Linux*)  readonly trash_folder='/home/$USER/.local/share/Trash' ;;
esac


#-Main-Program----------------------------------#


echo 'Are you sure you want to uninstall the Arduino Light Show CLI? [ENTER or ESC]'
get_approval_or_exit_ || exit 1
echo 'Uninstalling...'

[ "$uninstall_arduino_cli" = true ] && rm "`location_of --arduino-cli-destination`"
rm "`location_of --cli-command-destination`/`location_of --cli-command`"

# The echo has to appear before this file deletes itself.
echo 'Uninstalling complete'
rm -r "`location_of --cli-supporting-files-destination`"
