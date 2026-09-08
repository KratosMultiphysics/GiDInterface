#!/bin/bash
# OutputFile: "$2/$1.info"
# ErrorFile: "$2/$1.err"
cd "$case_path"
#delete previous result file
rm -f "$case_path/$1*.post.bin"
rm -f "$case_path/$1*.post.res"
rm -f "$case_path/$1*.post.msh"
rm -f "$case_path/$1.info"
rm -f "$case_path/$1.err"
rm -f "$case_path/$1.flavia.dat"

export PYTHONPATH=%python_home%
export PYTHONHOME=%python_home%

# Run Python using the script MainKratos.py
$python_home/python3 MainKratos.py > "$case_path/$1.info" 2> "$case_path/$1.err"