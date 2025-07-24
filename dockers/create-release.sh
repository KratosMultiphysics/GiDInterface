#!/bin/bash

# Change directory to the specified directory
cd /tmp/dist/kratos-10.3.0/
find . -type f -name "*.unix.bat" -print0 | xargs -0 dos2unix

# Add execute permission to all .bat files in the directory
# chmod 755 *.bat

# Create a tgz file from the directory
tar -czf ../kratos-10.3.0-linux-64.tgz *

