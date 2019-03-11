#!/bin/bash

# This script uninstalls all of the components installed for the Arduino Light Show CLI to run.
# Files are only moved to the trash-folder, so the process can be undone.

# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports CLI utilities.
. "$dot/../utilities.sh"

echo 'Are you sure you want to uninstall the Arduino Light Show CLI? [ENTER or ESC]'
get_approval_or_exit_ || exit 1
