#!/bin/bash

# Change directory to the specified directory
cd /tmp/dist/kratos-9.3.3/

# Add execute permission to all .bat files in the directory
# chmod 755 *.bat

# Create a tgz file from the directory
tar -czf ../kratos-9.3.3-linux-64.tgz *

