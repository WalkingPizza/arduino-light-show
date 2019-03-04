#!/bin/bash

# Import testing utilities.
. utilities.sh


#-Constant-Declarations-------------------------#


readonly test_command='../apply_configuration.sh'
readonly test_ino_file='test_AC_ino_file.ino'
readonly test_configuration='test_AC_configuration'


#-Test-Setup------------------------------------#


echo "* Testing \``basename $test_command`\` in \`${BASH_SOURCE##*/}\`:"
silent touch $test_ino_file
silent touch $test_configuration


#-Tests-----------------------------------------#


# Test: Invalid file-paths

silent $test_command invalid_file $test_ino_file
report_if_status_is 1

silent $test_command $test_configuration invalid_file
report_if_status_is 1


# Test: Non-`.ino` file as second argument

silent $test_command $test_configuration $test_configuration
report_if_status_is 2


# Test: Malformed configuration entries

echo 'invalid' > $test_configuration
echo $'some valid: 123\nother valid: 001' > $test_configuration
silent $test_command $test_configuration $test_ino_file
report_if_status_is 3

echo 'invalid: 123;' > $test_configuration
silent $test_command $test_configuration $test_ino_file
report_if_status_is 3

echo 'invalid 456' > $test_configuration
silent $test_command $test_configuration $test_ino_file
report_if_status_is 3

echo ':nvalid: 456' > $test_configuration
silent $test_command $test_configuration $test_ino_file
report_if_status_is 3

echo 'invalid:9' > $test_configuration
silent $test_command $test_configuration $test_ino_file
report_if_status_is 3


# Test: Configuration with duplicate microphone-identifier

echo $'duplicate: 1\nother: 2\nduplicate: 3' > $test_configuration
silent $test_command $test_configuration $test_ino_file
report_if_status_is 4


# Test: Valid, equally sized configurations

echo $'first: 10\nsecond: 20\nthird: 30' > $test_configuration
cat << END > $test_ino_file
int something_before;

// #threshold "one"
const int threshold_declaration_0_value = 1;

int something_inbetween;

// #threshold "two"
const int threshold_declaration_1_value = 2;

// #threshold "three"
const int threshold_declaration_2_value = 3;

int something_after;
END

expected_output=`cat << END
int something_before;

// #threshold "first"
const int threshold_declaration_0_value = 10;

// #threshold "second"
const int threshold_declaration_1_value = 20;

// #threshold "third"
const int threshold_declaration_2_value = 30;

// #threshold-declarations-end

int something_inbetween;



int something_after;
END`

silent $test_command $test_configuration $test_ino_file
report_if_output_matches "`cat $test_ino_file`" "$expected_output"


# Test: Valid, equally sized, dense configurations

echo $'first: 10\nsecond: 20\nthird: 30' > $test_configuration
cat << END > $test_ino_file
int something_before;
// #threshold "one"
const int threshold_declaration_0_value = 1;
int something_inbetween;
// #threshold "two"
const int threshold_declaration_1_value = 2;
// #threshold "three"
const int threshold_declaration_2_value = 3;
int something_after;
END

expected_output=`cat << END
int something_before;
// #threshold "first"
const int threshold_declaration_0_value = 10;

// #threshold "second"
const int threshold_declaration_1_value = 20;

// #threshold "third"
const int threshold_declaration_2_value = 30;

// #threshold-declarations-end
int something_inbetween;
int something_after;
END`

silent $test_command $test_configuration $test_ino_file
report_if_output_matches "`cat $test_ino_file`" "$expected_output"


# Test: Valid, non-equally sized configurations

echo $'first: 10\nsecond: 20\nthird: 30' > $test_configuration
cat << END > $test_ino_file
int something_before;
// #threshold "just this one"
const int threshold_declaration_0_value = 987654321;
int something_after;
END

expected_output=`cat << END
int something_before;
// #threshold "first"
const int threshold_declaration_0_value = 10;

// #threshold "second"
const int threshold_declaration_1_value = 20;

// #threshold "third"
const int threshold_declaration_2_value = 30;

// #threshold-declarations-end
int something_after;
END`

silent $test_command $test_configuration $test_ino_file
report_if_output_matches "`cat $test_ino_file`" "$expected_output"


#-Test-Cleanup------------------------------------#


silent rm $test_ino_file
silent rm $test_configuration

# TODO: Find out why "test_AC_ino_file.ino-e" appears when running this test
rm 'test_AC_ino_file.ino-e'

exit 0
