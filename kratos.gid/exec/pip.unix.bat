#!/bin/bash
# OutputFile: "$2/$1.info"
# ErrorFile: "$2/$1.err"
#delete previous result file
rm -f "$2/$1*.post.bin"
rm -f "$2/$1*.post.res"
rm -f "$2/$1*.post.msh"
rm -f "$2/$1.info"
rm -f "$2/$1.err"
rm -f "$2/$1.flavia.dat"

export PYTHONPATH=%python_home%
export PYTHONHOME=%python_home%

# Run Python using the script MainKratos.py
$python_home/python3 MainKratos.py > "$2/$1.info" 2> "$2/$1.err"