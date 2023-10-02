REM @ECHO OFF
REM Identification for arguments
REM basename                          = %1
REM Project directory                 = %2
REM Problem directory                 = %3

REM OutputFile: "%2\%1.info"
REM ErrorFile: "%2\%1.err"

DEL "%2\%1.info"
DEL "%2\%1.err"
DEL "%2\%1*.post.bin"
DEL "%2\%1*.post.res"
DEL "%2\%1*.post.msh"
DEL "%2\%1.info"
DEL "%2\%1.err"
DEL "%2\%1.flavia.dat"
DEL "%2\gid_output"
DEL "%2\vtk_output"

@REM echo "Launching on Compiled for windows -> %kratos_bin_path%" > .run


set PATH=E:\Deploy_Deltares\libs;%PATH%
set PYTHONPATH=E:\Deploy_Deltares
set PYTHONHOME=C:\Users\garat\AppData\Local\Programs\Python\Python311


set PATH=%kratos_bin_path%\libs;%PATH%
set PYTHONPATH=%kratos_bin_path%
REM pythonhome is the parent directory of %python_path%

set PYTHONHOME=""
%python_path% -c "import os; print (os.environ)" > "%2\\%1.1info" 2> "%2\\%1.1err"
REM Run Python using the script MainKratos.py
%python_path% MainKratos.py > "%2\\%1.info" 2> "%2\\%1.err"