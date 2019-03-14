#!/bin/bash

# This script uninstalls all of the components installed for the Arduino Light Show CLI to run.
# This includes:
# * the Arduino Light Show CLI script
# * the Arduino Light Show CLI's supporting files
# * the Arduino CLI, if it had to be installed by the installer script
# Any of these files are only moved to the trash-folder, so the process can be undone manually.
#
# Return status:
# TODO: Add return status documentation

# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports CLI utilities.
. "$dot/../Utilities/utilities.sh"


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants_ {
   # A flag set by the installer script, determining whether the Arduino CLI should be deleted upon
   # uninstallation as well.
   # UNINSTALL-ARDUINO-CLI-FLAG
   readonly uninstall_arduino_cli=false

   # Sets the trash-folder path according to the operating system. If an unknown operating system is
   # encountered an error is printed and a return on status 1 occurs.
   case "`uname -s`" in
      Darwin*) readonly trash="$HOME/.Trash" ;;
      Linux*)  readonly trash="/home/$USER/.local/share/Trash" ;;
      *) echo 'Error: uninstallation is not possible on the current operating system'; return 1
   esac

   return 0 # EHC
}


#-Main------------------------------------------#


declare_constants_ "$@" || exit 1

# Gets confirmation from the user that uninstallation should be performed. If approval is not given
# an exit on status 1 occurs.
echo 'Are you sure you want to uninstall the Arduino Light Show CLI? [ENTER or ESC]'
get_approval_or_exit_ || exit 2
echo 'Uninstalling...'

# Deletes the Arduino CLI as specified by <utility file: file locations>, if the "uninstall Arduino
# CLI"-flag is set.
if [ "$uninstall_arduino_cli" = true ]; then
   mv -f "`location_of --arduino-cli-destination`" "$trash" &> /dev/null
fi

# Deletes the CLI script as specified by <utility file: file locations>.
mv -f "`location_of --cli-command-destination`/`location_of --cli-command`" "$trash" &> /dev/null
# Deletes the CLI's supporting files folder as specified by <utility file: file locations>.
mv -f "`location_of --cli-supporting-files-destination`" "$trash" &> /dev/null

echo 'Uninstalling complete'
exit 0 # EHC
