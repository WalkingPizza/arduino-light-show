#!/bin/bash


#-Constant-Declarations-------------------------#

# Turns on alias expansion explicitly, as the shell will be non-interactive.
shopt -s expand_aliases
# Creates a convenience alias for the `report_exit_status_assertion` function.
alias report_if_status_is='report_exit_status_assertion $LINENO '

declare -r test_command='../generate_threshold_configuration_file.sh'
declare -r test_ino_file='test_GTCF_ino_file.ino'
declare -r test_configuration_file='test_GTCF_threshold_configuration'


#-Functions-------------------------------------#


# Runs a given command while removing all of its output to stdout and stderr. `$?` remains the same.
function silent {
   $@ &> /dev/null
   return $?
}

# Takes a test-identifier, an expected exit status and optionally an explicit last exit status
# (otherwise `$?` is used). This function prints a description, representing the success status of
# a test with the given identifier.
function report_exit_status_assertion {
   # Takes the last exit status as `exit_status`, unless one is explicitly provided as `$3`.
   local -i exit_status=$?; if [ -n "$3" ]; then exit_status=$3; fi

   if [ $exit_status -eq "$2" ]; then
      echo -e "> Test[$1]\tOK"
   else
      echo -e "> Test[$1]\tNO: Expected exit status $2, but got $exit_status"
   fi
}


#-Test-Setup------------------------------------#


touch $test_ino_file


#-Tests-----------------------------------------#

# Test: No command line argument

silent $test_command
report_if_status_is 1


# Test: Non-existing file

silent $test_command invalid_file_path
report_if_status_is 2


# Test: Non-`.ino` file

# Creates a temporary file not ending in ".ino".
temporary_file=`mktemp`
non_ino_file="${temporary_file}_"
mv "$temporary_file" "$non_ino_file"

silent $test_command "$non_ino_file"
report_if_status_is 3

# Removes the temporary file.
rm "$non_ino_file"


# Test: Existing (empty) `.ino`-file

> $test_ino_file

silent $test_command $test_ino_file $test_configuration_file
report_if_status_is 0


# Test: Configuration file creation

# TODO: Implement



# Test: Duplicate microphone identifiers

cat << END > $test_ino_file
// #threshold "A"
// #threshold "B"
// #threshold "A"
END

silent $test_command $test_ino_file $test_configuration_file
report_if_status_is 4


# Test: Malformed declaration body

cat << END > $test_ino_file
// #threshold "A"
const int a = 1;

// #threshold "B"
int b = 2;
END

silent $test_command $test_ino_file $test_configuration_file
report_if_status_is 5


# Test: Perfect `.ino`-file

cat << END > $test_ino_file
// #threshold "A"
const int a = 1;

// #threshold "B"
const int b = 2;
END

silent $test_command $test_ino_file $test_configuration_file

# Performs some more elaborate success testing.
exit_status=$?
expected_result=$'A: 1\nB: 2'
if [ "`cat $test_configuration_file`" != "$expected_result" ]; then
   echo -e "> Test[$LINENO]\tNO: Expected different output to configuration file"
else
   report_if_status_is 0 $exit_status
fi


# Test: Messy `.ino`-file

cat << END > $test_ino_file
// #threshold "#threshold #1"
const int a = 1;

// #threshold "ignored threshold bacause of the :"
const int b = 0;

// #threshold "ignored threshold bacause of the " "
const int c = 0;

// #threshold "valid threshold"
const int _3complicated5Me = 0123456789;

for (int i = 0; i < 10; i++) {
   printf("Index: %d", i);
}

// #threshol "ignored threshold declaration"
int thisDoesntMatter = -1;

// #threshold "ignored again
char againDoesntMatter = -2;
END

silent $test_command $test_ino_file $test_configuration_file

# Performs some more elaborate success testing.
exit_status=$?
expected_result=$'#threshold #1: 1\nvalid threshold: 0123456789'
if [ "`cat $test_configuration_file`" != "$expected_result" ]; then
   echo -e "> Test[$LINENO]\tNO: Expected different output to configuration file"
else
   report_if_status_is 0 $exit_status
fi


#-Test-Cleanup------------------------------------#


silent rm $test_ino_file
silent rm $test_configuration_file
