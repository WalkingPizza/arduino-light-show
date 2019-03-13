#!/bin/bash

# This script installs all of the components needed for the Arduino Light Show CLI to run.
# Everything is kept in the "~/Library/Application Scripts/Arduino Light Show CLI" directory.

# TODO: Add documentation
# TODO: Add a different supporting files destination for Linux


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   readonly repository_location='https://github.com/WalkingPizza/arduino-light-show/tree/master'
   readonly repository_folder='arduino-light-show'
   readonly cli_utilities='Command Line Interface/Utilities/utilities.sh'
   readonly working_directory=`mktemp -d`
}


#-Functions-------------------------------------#


trap cleanup EXIT
function cleanup {
   rm -rf "$working_directory"
}

function setup_installation_environment_ {
   # Clone the repository into a specific folder in the working directory.
   cd "$working_directory"

   # Downloads the current version of the repository.
   if ! git clone "$repository_location" "$repository_folder"; then
      echo "Error: could not clone repository \"$repository_location\"" >&2
      return 1
   fi

   # Import CLI utilities.
   . "$repository_folder/$cli_utilities"

   # Gets the folder in which the CLI is supposed to be installed.
   local cli_supporing_files_destination=`location_of --cli-supporting-files-destination`

   # Create or empty the CLI-folder depending on whether one exists, or abort if the user chooses
   # to.
   if [ -d "$cli_supporing_files_destination" ]; then
      echo 'It seems you have already run this installation.' >&2
      echo 'Do you want to reinstall? [ENTER or ESC]'
      get_approval_or_exit_ || return 2

      rm -r "$cli_supporing_files_destination/"*
   else
      mkdir -p "$cli_supporing_files_destination"
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
   unzip $archive -d $unzipped_folder &> /dev/null
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
   if ! command -v arduino-cli &> /dev/null; then
      echo 'Error: Arduino CLI installation failed' >&2
      return 5
   fi
}

function set_uninstall_ardunio_cli_flag {
   uninstaller_script="$repository_folder/$repository_cli_directory/`location_of --cli-uninstaller`"
   flag_tag_line=$(egrep -n "$(regex_for --uninstall-arduino-cli-flag-tag)" "$uninstaller_script")
   flag_line_number=`cut -d : -f 1 <<< "$flag_tag_line"`

   # Replace "=false" with "=true" in the uninstaller-file's flag line.
   sed -i '' -e "$flag_line_number s/=false/=true/" "$uninstaller_script"
}

function install_lightshow_cli {
   # Get the folder in which the CLI is supposed to be installed.
   local cli_supporing_files_destination=`location_of --cli-supporting-files-destination`
   # Get the relative path to the CLI-folder within the repo.
   local repository_cli_directory=`location_of --repo-cli-directory`

   # Move all of the CLI-scripts to the CLI-folder.
   while read script_location; do
      local destination="$cli_supporing_files_destination/$script_location"
      mkdir -p "`dirname "$destination"`"
      mv "$repository_folder/$repository_cli_directory/$script_location" "$destination"
   done <<< "`location_of --cli-scripts`"

   # Copy all of the CLI-utilities to the CLI-folder (as they might still be needed for the
   # execution of this script).
   while read utility_location; do
      local destination="$cli_supporing_files_destination/$utility_location"
      mkdir -p "`dirname "$destination"`"
      cp -R "$repository_folder/$repository_cli_directory/$utility_location" "$destination"
   done <<< "`location_of --cli-utilities`"

   # Move the CLI-command to its intended directory.
   mv "$repository_folder/$repository_cli_directory/`location_of --cli-command`" \
      "`location_of --cli-command-destination`"
}


#-Main-Program----------------------------------#


declare_constants "$@"

# Abort if Git is not installed.
if ! command -v git &> /dev/null; then
   echo 'The Arduino Light Show installer requires Git. Please install it first.'
   exit 6
fi

# Setup directories, functions and variables needed for the installation process.
setup_installation_environment_ || exit $?

# Install the Arduino-CLI if it is not yet installed.
if ! command -v arduino-cli &> /dev/null; then
   echo 'Installing Arduino CLI...'
   install_arduino_cli_ || exit $?

   set_uninstall_ardunio_cli_flag
fi

# Install the Arduino Light Show CLI.
echo 'Installing Arduino Light Show CLI...'
install_lightshow_cli
echo 'Installation complete'
