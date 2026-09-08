#!/bin/bash
# OutputFile: "$case_path/$1.info"
# ErrorFile: "$case_path/$1.err"
#delete previous result file
cd "$case_path"
rm -f "$case_path/$1*.post.bin"
rm -f "$case_path/$1*.post.res"
rm -f "$case_path/$1*.post.msh"
rm -f "$case_path/$1.info"
rm -f "$case_path/$1.err"
rm -f "$case_path/$1.flavia.dat"

# Run Python using the script MainKratos.py
docker run -v "$case_path:/model" --rm --name "$1" $kratos_docker_image > "$case_path/$1.info" 2> "$case_path/$1.err"
# docker run -v "%case_path%:/model" --rm --name "%1" %kratos_docker_image% > "%case_path%\\%1.info" 2> "%case_path%\\%1.err"