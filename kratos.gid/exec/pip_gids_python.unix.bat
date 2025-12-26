#!/bin/bash
# OutputFile: "$2/$1.info"
# ErrorFile: "$2/$1.err"
#delete previous result file
cd "$case_path"
rm -f "./$1*.post.bin"
rm -f "./$1*.post.res"
rm -f "./$1*.post.msh"
rm -f "./$1.info"
rm -f "./$1.err"
rm -f "./$1.flavia.dat"

export PYTHONPATH=""
export PYTHONHOME=""


# Run Python using the script MainKratos.py
$python_path MainKratos.py > "./$1.info" 2> "./$1.err"