/*
 * Opens the serial port for a given device path, and prints the resulting file
 * descriptor to stdout.
 * If the port could not be opened no file descriptor is printed, and a non-zero
 * value is returned.
 *
 * Information on how to open and configure a serial port was taken from:
 * https://www.cmrr.umn.edu/~strupp/serial.html
 * Parts of the page are quoted in comments below.
 *
 * NOTES:
 * It might be desirable to remove the `O_NDELAY`-flag when opening the port.
 */

 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <unistd.h>
 #include <fcntl.h>

/*
 * "The two most important POSIX functions are tcgetattr(3) and tcsetattr(3).
 *  These get and set terminal attributes, respectively; you provide a pointer
 *  to a termios structure that contains all of the serial options available:"
 *
 * `termios` structure members:
 *
 * `c_cflag` 	 Control options
 * `c_lflag`	 Line options
 * `c_iflag`	 Input options
 * `c_oflag`	 Output options
 * `c_cc`	    Control characters
 * `c_ispeed`	 Input baud (new interface)
 * `c_ospeed`	 Output baud (new interface)
 */
#include <termios.h>

// Opens a port with a given path, and returns its file descriptor.
// If the port could not be opened `-1` is returned.
int open_port(char* path) {
   // Gets the file descriptor for the given device/port.
   // * `O_RDONLY` opens the file in read mode
   // * `O_NOCTTY` "If you don't specify this then any input (such as keyboard
   //               abort signals and so forth) will affect your process."
   // * `O_NDELAY` "If you do not specify this flag, your process will be put
   //               to sleep until the DCD signal line is the space voltage."
   int file_descriptor = open(path, O_RDONLY | O_NOCTTY | O_NDELAY);

   // If a valid file descriptor was received, options on the file are
   // configured.
   if (file_descriptor != -1) {
      // Normally "[i]f no characters are available, the call will block (wait)
      // until characters come in, an interval timer expires, or an error
      // occurs."
      // But "[t]he read function can be made to return immediately [...]. The
      // FNDELAY option causes the read function to return 0 if no characters
      // are available on the port."
      fcntl(file_descriptor, F_SETFL, FNDELAY);
   }

   return file_descriptor;
}

// Sets the baud rate for the file associated with a given file descriptor.
//
// "The baud rate is stored in different places depending on the operating
// system. Older interfaces store the baud rate in the c_cflag member [...],
// while newer implementations provide the c_ispeed and c_ospeed members that
// contain the actual baud rate value.
// The cfsetospeed(3) and cfsetispeed(3) functions are provided to set the baud
// rate in the termios structure regardless of the underlying operating system
// interface."
void set_baud_rate(speed_t baud_rate, int file_descriptor) {
   struct termios file_options;

   // Writes the current options of the file associated with the file descriptor
   // into the `file_options` struct.
   tcgetattr(file_descriptor, &file_options);

   // Sets the input baud rate to the pre-defined value.
   cfsetispeed(&file_options, baud_rate);

   // "Most systems do not support different input and output speeds, so be
   // sure to set both to the same value for maximum portability."
   cfsetospeed(&file_options, baud_rate);

   // * `CLOCAL`: causes the CD-signal to be ignored
   //   (https://en.wikipedia.org/wiki/Data_Carrier_Detect)
   //
   // * `CREAD`: "If CREAD is set the receiver is enabled; otherwise no
   //             characters shall be received."
   //   (https://www.mkssoftware.com/docs/man5/struct_termios.5.asp)
   file_options.c_cflag |= (CLOCAL | CREAD);

   // Applies the options in the `file_options` to the file associated with the
   // file descriptor.
   //
   // `TCSAFLUSH` causes any buffers to be flushed, before applying the options.
   // This could be necessary to avoid misaligning any data already written to a
   // buffer.
   tcsetattr(file_descriptor, TCSAFLUSH, &file_options);
}

int main(int argc, char** argv) {
   // Asserts that there is exactly one command line argument.
   if (argc != 2) {
      fprintf(stderr, "Error: `%s` expects exactly one argument.\n", __FILE__);
      return 1;
   }

   // Gets the file descriptor for the device passed as command line argument.
   char* device_path = argv[1];
   int device_file_descriptor = open_port(device_path);

   // Prints an error to stderr and returns with an error-value, if the port
   // could not be opened (file descriptor is `-1`).
   if (device_file_descriptor == -1) {
      fprintf(
         stderr, "Error: `%s` was unable to open \"%s\"\n",
         __FILE__, device_path
      );
      return 2;
   }

   // Sets a pre-defined baud rate for the device.
   set_baud_rate(B115200, device_file_descriptor);

   // Prints the file descriptor and returns successfully.
   printf("%d\n", device_file_descriptor);
   return 0;
}
