REM @ECHO OFF
REM Identification for arguments
REM basename                          = %1
REM Project directory                 = %2
REM Problem directory                 = %3

REM OutputFile: "%2\%1.info"
REM ErrorFile: "%2\%1.err"

@REM if case_path environment variable is defined use it, change directory to it
cd %case_path%

REM Remove previous calculation files and results
DEL "%case_path%\%1.info"
DEL "%case_path%\%1.err"
DEL "%case_path%\%1*.post.bin"
DEL "%case_path%\%1*.post.res"
DEL "%case_path%\%1*.post.msh"

set PYTHONPATH=%python_home%
set PYTHONHOME=%python_home%

@REM Calculate!
%python_home%/python.exe MainKratos.py > "%case_path%\%1.info" 2> "%case_path%\%1.err"
