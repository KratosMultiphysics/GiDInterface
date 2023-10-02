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
rm -fr "$2/gid_output"
rm -fr "$2/vtk_output"

# include .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# gid redefines LD_LIBRARY_PATH to its own libs directory
# and maintains OLD_LD_LIBRARY_PATH with previous settings
# therefore, we use the OLD_LD_LIBRARY_PATH and prepend the path to the kratos libs
if [ "$OLD_LD_LIBRARY_PATH" != "" ]; then
    export LD_LIBRARY_PATH="$kratos_bin_path/libs":$OLD_LD_LIBRARY_PATH
else
    # do not add the ':'
    export LD_LIBRARY_PATH="$kratos_bin_path/libs"
fi

# Prevents the PYTHONHOME error from happening and isolate possible python repacks present
# in the system and interfeering with runkratos
export PYTHONPATH=$kratos_bin_path:$PYTHONPATH


export PATH=$kratos_bin_path\libs;$PATH
export PYTHONHOME=$python_home

KERNEL_NAME="linux"


# Run Python using the script MainKratos.py
$python_path/python3 MainKratos.py > "$2/$1.info" 2> "$2/$1.err"