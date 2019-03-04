#!/bin/bash

for test_script in test_*; do
   echo 
   ./$test_script
done
