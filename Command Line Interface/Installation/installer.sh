#!/bin/bash

# This script installs all of the components needed for the Arduino Light Show CLI to run.
# Everything is kept in the "~/Library/Application Scripts/Arduino Light Show CLI" directory.
#
# Install command:
# `curl -sSfLO 'https://raw.githubusercontent.com/WalkingPizza/arduino-light-show/master/Command%20Line%20Interface/Installation/install_files'; curl -sSfL 'https://raw.githubusercontent.com/WalkingPizza/arduino-light-show/master/Command%20Line%20Interface/Installation/installer.sh' | bash`


#-Constants-------------------------------------#


declare -r cli_folder="$HOME/Library/Application Scripts/Arduino Light Show CLI"
declare -r script_path="$PWD/installer.sh"
declare -r install_files_list="$PWD/install_files"
declare -r install_files_directory=`head -n 1 "$install_files_list"`


#-Functions-------------------------------------#


function install_arduino_cli_ {
   # Defines needed constants.
   local install_folder='arduino_cli_install'
   local archive_name='arduino_cli.zip'
   local ardunio_cli_url='https://downloads.arduino.cc/arduino-cli/arduino-cli-latest-osx.zip'

   mkdir $install_folder &> /dev/null
   cd $install_folder &> /dev/null

   if ! curl -o $archive_name $ardunio_cli_url &> /dev/null; then
      echo 'Error: failed to download Arduino CLI' >&2
      exit 1
   fi
   unzip $archive_name &> /dev/null
   rm $archive_name &> /dev/null

   if ! [ $(wc -l <<< $(ls -1)) -eq 1 ]; then
      echo 'Error: Arduino CLI installer changed' >&2
      exit 2
   fi

   mv * /usr/local/bin/arduino-cli &> /dev/null

   cd .. &> /dev/null
   rm -r $install_folder &> /dev/null

   if ! command arduino-cli &> /dev/null; then
      echo 'Error: Arduino CLI installation failed' >&2
      exit 3
   fi
}


#-Main-Program----------------------------------#


# Install the Arduino-CLI if it is not yet installed.
if ! command arduino-cli &> /dev/null; then
   echo 'Installing Arduino CLI...'
   install_arduino_cli_ || exit $?
fi

# Exit if there has already been an installation.
if [ -d "$cli_folder" ]; then
   echo 'It seems you have already run this installation.' >&2
   echo "Delete \`$cli_folder\` if you want to reinstall." >&2
   exit 4
fi

echo 'Installing Arduino Light Show CLI...'

# Create and move to the Arduino Light Show CLI folder.
mkdir "$cli_folder"
cd "$cli_folder"

# Pulls all of the files needed for the CLI to work.
while read file_url; do
   curl -O -sSfL "$install_files_directory/$file_url"
done <<< "`tail -n +3 "$install_files_list"`"

# Add execute permissions to all script files.
chmod u+x *.sh

echo 'Installation complete'

# TODO: Uncomment this when deploying
# rm "$script_path"

# TODO: Uncomment this when deploying
# rm "$install_files_list"
