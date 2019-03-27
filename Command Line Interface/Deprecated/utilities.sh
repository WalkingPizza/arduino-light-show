# Prints out a given list of device paths, having merged any "tty"-prefixed device onto a
# corresponding "cu"-prefixed device (if one exists).
#
# Arguments:
# <list of device paths>
function merge_tty_onto_cu {
   # Prints all of the devices whose name does not start with "tty".
   egrep -v '^tty' <<< "$1"

   # Iterates over all of the devices starting with "tty", adding only those "tty"-devices to the
   # final devices that do not have an equivalent "cu"-device.
   egrep '^tty' <<< "$1" | while read -r tty_device; do
      # Prints the "tty"-device if there is no matching "cu"-device.
      egrep -q "^\s*${tty_device/tty/cu}\s*\$" <<< "$1" || echo "$tty_device"
   done

   return 0
}
