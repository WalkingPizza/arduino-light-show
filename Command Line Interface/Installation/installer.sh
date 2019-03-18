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
# 0: success
# 1: download of the repository failed
# 2: the user does not want to reinstall
# 3: the installation of the Arduino-CLI failed

# TODO: Add a different "supporting files" destination for Linux


#-Constants-------------------------------------#


# The function wrapping all constant-declarations for this script.
function declare_constants {
   # A URL to the Arduino Light Show repository.
   readonly repository_url='https://github.com/WalkingPizza/arduino-light-show/archive/master.zip'
   # The name of the folder as which the repository above will be unarchived.
   readonly repository_folder='arduino-light-show-master'
   # A hardcoded path to the CLI-utilities, needed for bootstrapping the installation.
   readonly cli_utilities='Command Line Interface/Utilities/utilities.sh'
   # A unique temporary working directory used as sandbox for the installation process.
   readonly working_directory=`mktemp -d`

   return 0
}


#-Functions-------------------------------------#


# Sets up a certain environment for the further steps in the installation process.
# After running this function the current working directory is "$working_directory", which contains
# a folder "$repository_folder" which contains all of the contents ot the Arduino Light Show
# repository. Furthermore the folder for the CLI's supporting files exists and is empty.
#
# Return status:
# 0: success
# 1: download of the repository failed
# 2: the user does not want to reinstall
function setup_installation_environment_ {
   # Moves into the installation process' "sandbox".
   cd "$working_directory"

   echo 'Downloading Arduino Light Show CLI:'

   # Tries to download the repository into the "$repository_folder.zip" archive. If that is not
   # possible an error is printed and a return on failure occurs.
   if ! curl -Lk --progress-bar -o "$repository_folder.zip" "$repository_url"; then
      echo "Error: failed to download repository at \"$repository_url\"" >&2
      return 1
   fi

   echo 'Unpacking Arduino Light Show CLI...'

   # Unzips the archive into the "$repository_folder" and removes the archive.
   unzip "$repository_folder.zip" &>/dev/null
   rm "$repository_folder.zip"

   # Imports CLI-utilities.
   . "$repository_folder/$cli_utilities"

   # Gets the path of the folder in which the CLI's supporting files are supposed to be placed.
   local -r cli_supporing_files_destination=`location_of_ --cli-supporting-files-destination`

   # Creates the folder for the CLI's supporting files if none exists. If one already exists, the
   # user is prompted to choose whether they want to empty it and reinstall. If the user chooses not
   # to reinstall a return on failure occurs.
   if [ -d "$cli_supporing_files_destination" ]; then
      # Prompts the user and asks them for their decision.
      echo 'It seems you have already run this installation.' >&2
      echo 'Do you want to reinstall? [y or n]' >&2
      succeed_on_approval_ || return 2

      # This is only executed if the user chose to reinstall.
      # Removes the existing CLI's supporting files folder.
      rm -r "$cli_supporing_files_destination/"
   fi

   # Creates the CLI's supporting files folder.
   mkdir -p "$cli_supporing_files_destination"

   return 0
}

# Installs the Ardunio-CLI as specified by <utility file: file locations>.
#
# Return status:
# 0: success
# 1: download of the Arduino-CLI failed
# 2: the downloaded file has an unexpected format
# 3: the installation of the Arduino-CLI failed
function install_arduino_cli_ {
   # Declares local constants.
   local -r archive='arduino_cli.zip'
   local -r unzipped_folder='arduino_cli'

   echo 'Downloading Arduino CLI:'

   # Tries to download the Ardunio-CLI archive into the "$archive" folder. If that doesn't work an
   # error is printed and a return on failure occurs.
   if ! curl --progress-bar -o $archive "`location_of_ --arduino-cli-source`"; then
      echo 'Error: failed to download Arduino CLI' >&2
      return 1
   fi

   echo 'Installing Arduino CLI...'

   # Unzips the archive into the "$unzipped_folder" and removes the archive.
   silently- unzip $archive -d $unzipped_folder
   rm $archive

   # Checks if the archive contains exactly one file (expected to be the Arduino-CLI script). If it
   # doesn't an error is printed and a return on failure occurs.
   local -r unzipped_files=`ls -1 $unzipped_folder`
   if ! [ `wc -l <<< "$unzipped_files"` -eq 1 ]; then
      echo 'Error: Arduino CLI installer changed' >&2
      return 2
   fi

   # Moves all files in the "$unzipped_folder" (so only the Arduino-CLI script) to its final
   # destination and renames it as specified by <utility file: file locations>. Any temporary
   # folders are removed as well.
   local -r arduino_cli_destination=`location_of_ --arduino-cli-destination`
   mv $unzipped_folder/* "$arduino_cli_destination"
   rm -r $unzipped_folder

   # Makes sure that the Ardunio-CLI is now properly installed. If not an error is printed and a
   # return on failure occurs.
   if ! silently- command -v "`basename "$arduino_cli_destination"`"; then
      echo 'Error: Arduino CLI installation failed' >&2
      return 3
   fi

   echo 'Installed Arduino CLI.'
   return 0
}

# Sets a flag in the uninstaller-script, indicating the Arduino-CLI should also be removed when
# uninstalling the Arduino Light Show CLI.
#
# Return status:
# 0: success
# 1: the uninstaller does not contain the required flag
function set_uninstall_ardunio_cli_flag_ {
   # Gets the path of the uninstaller-script, relative to the repository as specified by
   # <utility file: file locations>.
   local -r repo_path="`location_of_ --repo-cli-directory`/`location_of_ --cli-uninstaller`"
   # Gets the path to the uninstaller-script as specified by <utility file: file locations>.
   local -r uninstaller_script="$repository_folder/$repo_path"
   # Gets the regular expression used to search for the "uninstall Arduino CLI flag"-tag as
   # specified by <utility file: regular expressions>.
   local -r tag_pattern=`regex_for_ --uninstall-arduino-cli-flag-tag`
   # Gets the line in the uninstaller-script containing the "uninstall Arduino CLI flag"-tag as
   # specified by <utility file: regular expressions>.
   local -r flag_tag_line=$(egrep -n "$tag_pattern" "$uninstaller_script")

   # Makes sure that a line with the flag-tag was found, or returns on failure.
   [ -n "$flag_tag_line" ] || return 1
   # Gets the line number of the flag itself.
   local -r flag_line_number=$[`cut -d : -f 1 <<< "$flag_tag_line"` + 1]

   # Replaces "=false" with "=true" in the uninstaller-script's flag line.
   sed -i '' -e "$flag_line_number s/=false/=true/" "$uninstaller_script"

   return 0
}

# Installs the Ardunio Light Show CLI by copying the CLI script as well as the CLI's supporting
# files to their destinations as specified by <utility file: file locations>.
function install_lightshow_cli {
   # Gets the folder in which the CLI is supposed to be installed as specified by <utility file:
   # file locations>.
   local -r cli_supporing_files_destination=`location_of_ --cli-supporting-files-destination`
   # Gets the repository-internal relative path to the repository's CLI-folder as specified by
   # <utility file: file locations>.
   local -r repository_cli_directory=`location_of_ --repo-cli-directory`

   echo 'Installing Arduino Light Show CLI...'

   # Moves all CLI supporting non-utility files as specified by <utility file: file locations> to
   # the CLI's supporting files folder. Moving the utility-files would disrupt the further
   # execution of this script.
   location_of_ --cli-scripts | while read script_location; do
      # Constructs the destination of the script in a way that maintains the same directory
      # structure as is present in the repository.
      local destination="$cli_supporing_files_destination/$script_location"
      # Creates intermediate directories if needed and moves the script to its destination.
      mkdir -p "`dirname "$destination"`"
      mv "$repository_folder/$repository_cli_directory/$script_location" "$destination"
   done

   # Copies all CLI supporting utility files as specified by <utility file: file locations> to the
   # CLI's supporting files folder. Moving the utility-files would disrupt the further execution of
   # this script.
   location_of_ --cli-utilities | while read utility_location; do
      # Constructs the destination of the file in a way that maintains the same directory
      # structure as is present in the repository.
      local destination="$cli_supporing_files_destination/$utility_location"
      # Creates intermediate directories if needed and copies the file to its destination.
      mkdir -p "`dirname "$destination"`"
      cp -R "$repository_folder/$repository_cli_directory/$utility_location" "$destination"
   done

   # Moves the CLI-command to its destination as specified by <utility file: file locations>.
   mv "$repository_folder/$repository_cli_directory/`location_of_ --cli-command`" \
      "`location_of_ --cli-command-destination`"

   echo 'Installed Arduino Light Show CLI.'
   return 0
}


#-Main------------------------------------------#


declare_constants "$@"

# Makes sure the temporary working directory is always cleared upon exiting.
trap "rm -rf \"$working_directory\"" EXIT

setup_installation_environment_ || exit $? #RS+2=2

# Makes sure the Arduino-CLI is installed. If not, it's installed before continuing.
if ! silently- command -v arduino-cli; then
   install_arduino_cli_ || exit 3 #RS=3
   set_uninstall_ardunio_cli_flag_
fi

install_lightshow_cli

echo 'Installation complete.'
exit 0
