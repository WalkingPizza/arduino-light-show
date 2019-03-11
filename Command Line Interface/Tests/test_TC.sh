#!/bin/bash

# Gets the directory of this script.
dot=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
# Imports testing utilities.
. "$dot/utilities.sh"


#-Constant-Declarations-------------------------#


readonly test_command="$dot/../Scripts/threshold_configuration.sh"
readonly test_ino_file="$dot/test_TC_ino_file.ino"


#-Test-Setup------------------------------------#


echo "* Testing \``basename "$test_command"`\` in \`${BASH_SOURCE##*/}\`:"
silent touch "$test_ino_file"


#-Tests-----------------------------------------#


# Test: No command line argument

silent "$test_command"
report_if_status_is 1


# Test: Non-existing file

silent "$test_command" invalid_file_path
report_if_status_is 2


# Test: Non-`.ino` file

# Creates a temporary file not ending in ".ino".
temporary_file=`mktemp`
non_ino_file="${temporary_file}_"
mv "$temporary_file" "$non_ino_file"

silent "$test_command" "$non_ino_file"
report_if_status_is 3

# Removes the temporary file.
silent rm "$non_ino_file"


# Test: Existing (empty) `.ino`-file

> "$test_ino_file"

silent "$test_command" "$test_ino_file"
report_if_status_is 0


# Test: Duplicate microphone identifiers

cat << END > "$test_ino_file"
// #threshold "A"
// #threshold "B"
// #threshold "A"
END

silent "$test_command" "$test_ino_file"
report_if_status_is 4


# Test: Malformed declaration body

cat << END > "$test_ino_file"
// #threshold "A"
const int a = 1;

// #threshold "B"
int b = 2;
END

silent "$test_command" "$test_ino_file"
report_if_status_is 5


# Test: Perfect `.ino`-file

cat << END > "$test_ino_file"
// #threshold "A"
const int a = 1;

// #threshold "B C"
const int bc = 2;
END

output=`silent --stderr "$test_command" "$test_ino_file"`
report_if_output_matches "$output" $'A: 1\nB C: 2'


# Test: Messy `.ino`-file

cat << END > "$test_ino_file"
// #threshold "#threshold #1"
const int a = 1;

// #threshold "valid threshold"
const int _3complicated5Me = 123456789;

// #threshold "ignored threshold because of the " "
const int c = 0;

// #threshold "ignored threshold bacause of the :"
const int b = 0;

for (int i = 0; i < 10; i++) {
   printf("Index: %d", i);
}

// #threshold "b"
const int _2complicated4Me = 123;

// #threshol "ignored threshold declaration"
int thisDoesntMatter = -1;

// #threshold "ignored again
char againDoesntMatter = 'a';
END

output=`silent --stderr "$test_command" "$test_ino_file"`
report_if_output_matches "$output" $'#threshold #1: 1\nvalid threshold: 123456789\nb: 123'


#-Test-Cleanup------------------------------------#


silent rm "$test_ino_file"
exit 0
