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

# Run Python using the script MainKratos.py
docker run -v "$2:/model" --rm --name "$1" $kratos_docker_image > "$2/$1.info" 2> "$2/$1.err"
# docker run -v "%2:/model" --rm --name "%1" %kratos_docker_image% > "%2\\%1.info" 2> "%2\\%1.err"