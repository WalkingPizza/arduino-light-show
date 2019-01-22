
# Serial Communication

Arduinos are able to communicate with a connected computer via a serial port. This opens up the possibility of using data collected by an Arduino in many more ways, than it could be by software run on the Arduino itself.

In Unix-like systems a _serial port_ is considered a _device_, and is therefore represented as a _file_.
The scripts and programs in this folder are used for the purpose of configuring, reading and writing from the file representing the Arduino.

---

### `arduino_path.sh`
This script is used to get the file path of the device representing the Arduino. 
It simply scans the `/dev` folder for devices that could possibly represent the Arduino. If there are multiple options, it prompts the user to select which device should be used. The path of the chosen devices is then printed to `stdout`.

--- 

### `open_serial_port.c`
This program currently opens a port with a supplied path, and configures that port. Currently it simply prints the file descriptor of the port to `stdout`, when complete.
Ultimately this program will probably turn into a library.
