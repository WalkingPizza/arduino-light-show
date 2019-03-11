#!/bin/bash

# This script installs all of the components needed for the Arduino Light Show CLI to run.
# Everything is kept in the "~/Library/Application Scripts/Arduino Light Show CLI" directory.

# This script expects the URL of the repository as command line argument.

# TODO: Add proper documentation to this file

# TODO: Add an uninstaller that also remembers whether the Arduino-CLI was preinstalled


#-Constants-------------------------------------#


readonly repository_location=$1
readonly repository_folder='arduino-light-show'
readonly cli_utilities='utilites.sh'
readonly working_directory=`mktemp -d`


#-Functions-------------------------------------#


trap cleanup EXIT
function cleanup {
   rm -r "$working_directory"
}

function setup_installation_environment_ {
   # Clone the repository into a specific folder in the working directory.
   cd "$working_directory"

   if ! git clone "$repository_location:$repository_folder"; then
      echo "Error: could not clone repository \"$repository_location\"" >&2
      return 1
   fi

   # Import CLI utilities.
   . "$repository_folder/$cli_utilities"

   # Gets the folder in which the CLI is supposed to be installed.
   local cli_scripts_destination=`location_of --cli-scripts-destination`

   # Create or empty the CLI-folder depending on whether exists, or abort if the user chooses
   # to.
   if [ -d "$cli_scripts_destination" ]; then
      echo 'It seems you have already run this installation.' >&2
      echo 'Do you want to reinstall? [ENTER or ESC]'
      get_approval_or_exit_ || return 2

      rm -r "$cli_scripts_destination/"*
   else
      mkdir "$cli_scripts_destination"
   fi
}

function install_arduino_cli_ {
   # Local constants.
   local archive='arduino_cli.zip'
   local unzipped_folder='arduino_cli'

   # Download the Ardunio-CLI archive.
   if ! curl -so $archive "`location_of --arduino-cli-source`"; then
      echo 'Error: failed to download Arduino CLI' >&2
      return 3
   fi

   # Unzip and remove the archive.
   unzip $archive -d $unzipped_folder
   rm $archive

   # Abort if the archive contained more than one file.
   local unzipped_files=`ls -1 $unzipped_folder`
   if ! [ `wc -l <<< "$unzipped_files"` -eq 1 ]; then
      echo 'Error: Arduino CLI installer changed' >&2
      rm -r $unzipped_folder
      return 4
   fi

   # Move the unzipped file (the Arduino-CLI command) to its final destination and clean up.
   mv $unzipped_folder/* "`location_of --arduino-cli-destination`"
   rm -r $unzipped_folder

   # Make sure that the Ardunio-CLI is nor properly installed.
   if ! command arduino-cli &> /dev/null; then
      echo 'Error: Arduino CLI installation failed' >&2
      return 5
   fi
}

function set_uninstaller_flags {
   # TODO: Implement
}

function install_lightshow_cli {
   # Gets the folder in which the CLI is supposed to be installed.
   local cli_scripts_destination=`location_of --cli-scripts-destination`

   # Move all of the files needed for the CLI to work to the CLI-folder.
   while read script_location; do
      mv "$repository_folder/$script_location" "$cli_scripts_destination"
   done <<< "`location_of --cli-scripts`"

   # Moves the CLI-command to its intended directory.
   mv "$repository_folder/`location_of --cli-command`" |
      "`location_of --cli-command-destination`"
}


#-Main-Program----------------------------------#


# Abort if Git is not installed.
if ! command git &> /dev/null; then
   echo 'The Arduino Light Show installer requires Git. Please install it first.'
   exit 6
fi

# Setup directories, functions and variables needed for the installation process.
setup_installation_environment_ || exit $?

# Install the Arduino-CLI if it is not yet installed.
if ! command arduino-cli &> /dev/null; then
   echo 'Installing Arduino CLI...'
   install_arduino_cli_ || exit $?

   set_uninstaller_flags
fi

# Install the Arduino Light Show CLI.
echo 'Installing Arduino Light Show CLI...'
install_lightshow_cli
echo 'Installation complete'
