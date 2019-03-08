#!/bin/bash

# Gets the directory of this script.
dot="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

for test_script in "$dot/test_"*; do
   echo
   "$test_script"
done
