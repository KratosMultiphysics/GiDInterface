#!/bin/bash
# OutputFile: "$2/$1.info"
# ErrorFile: "$2/$1.err"
#delete previous result file
cd "$case_path"
rm -f "$case_path/$1*.post.bin"
rm -f "$case_path/$1*.post.res"
rm -f "$case_path/$1*.post.msh"
rm -f "$case_path/$1.info"
rm -f "$case_path/$1.err"
rm -f "$case_path/$1.flavia.dat"

export PYTHONPATH=""
export PYTHONHOME=""


# Run Python using the script MainKratos.py
$python_path MainKratos.py > "$case_path/$1.info" 2> "$case_path/$1.err"