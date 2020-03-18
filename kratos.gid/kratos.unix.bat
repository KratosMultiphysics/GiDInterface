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

# include .bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi



# gid redefines LD_LIBRARY_PATH to its own libs directory
# and maintains OLD_LD_LIBRARY_PATH with previous settings
# therefore, we use the OLD_LD_LIBRARY_PATH and prepend the path to the kratos libs
if [ "$OLD_LD_LIBRARY_PATH" != "" ]; then
    export LD_LIBRARY_PATH="$3/exec/Kratos/bin/Release":"$3/exec/Kratos/bin/Release/libs":$OLD_LD_LIBRARY_PATH
else
    # do not add the ':'
    export LD_LIBRARY_PATH="$3/exec/Kratos/bin/Release":"$3/exec/Kratos/bin/Release/libs"
fi

# Prevents the PYTHONHOME error from happening and isolate possible python repacks present
# in the system and interfeering with runkratos
# export PYTHONHOME="$3/exec/Kratos/bin/Release"
export PYTHONPATH="$3/exec/Kratos/bin/Release/python34.zip":"$3/exec/Kratos/bin/Release":$PYTHONPATH


# if mac
KERNEL=`uname -s`
if [ $KERNEL = "Darwin" ]; then
    KERNEL_NAME="macosx"
    export DYLD_LIBRARY_PATH="$3/exec/Kratos/bin/Release":"$3/exec/Kratos/bin/Release/libs":$DYLD_LIBRARY_PATH
    export DYLD_FALLBACK_LIBRARY_PATH="$3/exec/Kratos/bin/Release":"$3/exec/Kratos/bin/Release/libs":$DYLD_FALLBACK_LIBRARY_PATH
    export PYTHONPATH="$3/exec/Kratos/bin/Release/Lib":"$3/exec/Kratos/bin/Release/Lib/lib-dynload/":$PYTHONPATH
    export PYTHONHOME="$3/exec/Kratos/bin/Release"
else
    KERNEL_NAME="linux"
fi

# Run Python using the script MainKratos.py
"$3/exec/Kratos/bin/Release/runkratos" MainKratos.py > "$2/$1.info" 2> "$2/$1.err"
