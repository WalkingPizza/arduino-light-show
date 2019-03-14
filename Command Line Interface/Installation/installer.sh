#!/bin/bash

# This script installs all of the components needed for the Arduino Light Show CLI to run.
# This includes:
# * the Arduino-CLI (if not preinstalled)
# * an Arduino Light Show CLI script in some "$PATH"-directory
# * supporting files for the Arduino Light Show CLI script
# The exact directories and names of all of these files are specified by <utility file:
# file locations>.
# A connection to the internet is required as this script may download files.
#
# For the purpose of bootstrapping the installation process, this script expects certain
# preconditions pertaining to certain files' locations. These can be gathered from the constant
# declarations below.
#
# Return status:
# TODO: Add return status documentation

# TODO: Add a different "supporting files" destination for Linux
# TODO: Figure out a good silencing strategy


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   # A URL to the Arduino Light Show repository.
   readonly repository_location='https://github.com/WalkingPizza/arduino-light-show.git'
   # The name of the folder into which the repository above will be cloned.
   readonly repository_folder='arduino-light-show'
   # A hardcoded path to the CLI-utilities, needed for bootstrapping the installation.
   readonly cli_utilities='Command Line Interface/Utilities/utilities.sh'
   # A unique temporary working directory used as sandbox for the installation process.
   readonly working_directory=`mktemp -d`

   return 0 # EHC
}


#-Functions-------------------------------------#


# Sets up a certain environment for the further steps in the installation process.
# After running this function the current working directory is "$working_directory", which contains
# a folder "$repository_folder" which contains all of the contents ot the Arduino Light Show
# repository. Furthermore the folder for the CLI's supporting files exists and is empty.
# If Git is not installed, the function returns early on return status 1.
function setup_installation_environment_ {
   # Moves into the installation process' "sandbox".
   cd "$working_directory"

   # Tries to download the current version of the repository into the "$repository_folder" folder.
   # If that is not possible because Git is not installed, an error is printed and a return on exit
   # status 1 occurs.
   if ! git clone "$repository_location" "$repository_folder" &> /dev/null; then
      echo "Error: could not clone repository \"$repository_location\"" >&2
      return 1
   fi

   # Imports CLI-utilities.
   . "$repository_folder/$cli_utilities"

   # Gets the path of the folder in which the CLI's supporting files are supposed to be placed.
   local -r cli_supporing_files_destination=`location_of --cli-supporting-files-destination`

   # Creates the folder for the CLI's supporting files if none exists. If one already exists, the
   # user is prompted to choose whether they want to empty it and reinstall. If the user chooses not
   # to reinstall a return on status 2 occurs.
   if [ -d "$cli_supporing_files_destination" ]; then
      # Prompts the user and asks them for their decision.
      echo 'It seems you have already run this installation.' >&2
      echo 'Do you want to reinstall? [ENTER or ESC]' >&2
      get_approval_or_exit_ || return 2

      # This is only executed if the user chose to reinstall.
      # Removes all of the files contained within the CLI's supporting files folder.
      rm -r "$cli_supporing_files_destination/"*
   else
      # Creates the CLI's supporting files folder.
      mkdir -p "$cli_supporing_files_destination"
   fi

   return 0 # EHC
}

# Installs the Ardunio-CLI as specified by <utility file: file locations>.
function install_arduino_cli_ {
   # Declares local constants.
   local -r archive='arduino_cli.zip'
   local -r unzipped_folder='arduino_cli'

   # Tries to download the Ardunio-CLI archive into the "$archive" folder. If that doesn't work an
   # error is printed and a return on status 3 occurs.
   if ! curl -so $archive "`location_of --arduino-cli-source`"; then
      echo 'Error: failed to download Arduino CLI' >&2
      return 3
   fi

   # Unzips the archive into the "$unzipped_folder" and removes the archive.
   unzip $archive -d $unzipped_folder &> /dev/null
   rm $archive

   # Checks if the archive contains exactly one file (expected to be the Arduino-CLI script). If it
   # doesn't an error is printed and a return on status 4 occurs.
   local -r unzipped_files=`ls -1 $unzipped_folder`
   if ! [ `wc -l <<< "$unzipped_files"` -eq 1 ]; then
      echo 'Error: Arduino CLI installer changed' >&2
      return 4
   fi

   # Moves all files in the "$unzipped_folder" (so only the Arduino-CLI script) to its final
   # destination and renames it as specified by <utility file: file locations>. Any temporary
   # folders are removed as well.
   local -r arduino_cli_destination=`location_of --arduino-cli-destination`
   mv $unzipped_folder/* "$arduino_cli_destination"
   rm -r $unzipped_folder

   # Makes sure that the Ardunio-CLI is now properly installed. If not an error is printed and a
   # return on status 5 occurs.
   if ! command -v "`basename "$arduino_cli_destination"`" &> /dev/null; then
      echo 'Error: Arduino CLI installation failed' >&2
      return 5
   fi

   return 0 # EHC
}

# Sets a flag in the uninstaller-script, indicating the Arduino-CLI should also be removed when
# uninstalling the Arduino Light Show CLI.
function set_uninstall_ardunio_cli_flag_ {
   # Gets the path of the uninstaller-script, relative to the repository as specified by
   # <utility file: file locations>.
   local -r relative_path="`location_of --repo-cli-directory`/`location_of --cli-uninstaller`"
   # Gets the path to the uninstaller-script as specified by <utility file: file locations>.
   local -r uninstaller="$repository_folder/$relative_path"
   # Gets the line in the uninstaller-script containing the "uninstall Arduino CLI flag"-tag as
   # specified by <utility file: regular expressions>.
   local -r flag_tag_line=$(egrep -n "$(regex_for --uninstall-arduino-cli-flag-tag)" "$uninstaller")

   # Makes sure that a line with the flag-tag was found. If not a return on status 6 occurs.
   [ -n "$flag_tag_line" ] || return 6
   # Gets the line number of the flag itself.
   local -r flag_line_number=$(( `cut -d : -f 1 <<< "$flag_tag_line"` + 1 ))

   # Replaces "=false" with "=true" in the uninstaller-script's flag line.
   sed -i '' -e "$flag_line_number s/=false/=true/" "$uninstaller"

   return 0 # EHC
}

# Installs the Ardunio Light Show CLI by copying the CLI script as well as the CLI's supporting
# files to their destinations as specified by <utility file: file locations>.
function install_lightshow_cli {
   # Gets the folder in which the CLI is supposed to be installed as specified by <utility file:
   # file locations>.
   local -r cli_supporing_files_destination=`location_of --cli-supporting-files-destination`
   # Gets the repository-internal relative path to the repository's CLI-folder as specified by
   # <utility file: file locations>.
   local -r repository_cli_directory=`location_of --repo-cli-directory`

   # Moves all CLI supporting non-utility files as specified by <utility file: file locations> to
   # the CLI's supporting files folder. Moving the utility-files would disrupt the further
   # execution of this script.
   while read script_location; do
      # Constructs the destination of the script in a way that maintains the same directory
      # structure as is present in the repository.
      local destination="$cli_supporing_files_destination/$script_location"
      # Creates intermediate directories if needed and moves the script to its destination.
      mkdir -p "`dirname "$destination"`"
      mv "$repository_folder/$repository_cli_directory/$script_location" "$destination"
   done <<< "`location_of --cli-scripts`"

   # Copies all CLI supporting utility files as specified by <utility file: file locations> to the
   # CLI's supporting files folder. Moving the utility-files would disrupt the further execution of
   # this script.
   while read utility_location; do
      # Constructs the destination of the file in a way that maintains the same directory
      # structure as is present in the repository.
      local destination="$cli_supporing_files_destination/$utility_location"
      # Creates intermediate directories if needed and copies the file to its destination.
      mkdir -p "`dirname "$destination"`"
      cp -R "$repository_folder/$repository_cli_directory/$utility_location" "$destination"
   done <<< "`location_of --cli-utilities`"

   # Moves the CLI-command to its destination as specified by <utility file: file locations>.
   mv "$repository_folder/$repository_cli_directory/`location_of --cli-command`" \
      "`location_of --cli-command-destination`"

   return 0 # EHC
}


#-Main------------------------------------------#


declare_constants "$@"

# Makes sure the temporary working directory is always cleared upon exiting.
trap "rm -rf \"$working_directory\"" EXIT

# Makes sure Git is installed. If not an error is printed and an exit on status 7 occurs.
if ! command -v git &> /dev/null; then
   echo 'The Arduino Light Show installer requires Git. Please install it first.'
   exit 7
fi

setup_installation_environment_ || exit $?

# Makes sure the Arduino-CLI is installed. If not, it's installed before continuing.
if ! command -v arduino-cli &> /dev/null; then
   echo 'Installing Arduino CLI...'
   install_arduino_cli_ || exit $?

   set_uninstall_ardunio_cli_flag_ # NF
fi

# Installs the Arduino Light Show CLI.
echo 'Installing Arduino Light Show CLI...'
install_lightshow_cli
echo 'Installation complete'

exit 0 # EHC
