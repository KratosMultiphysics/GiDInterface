REM @ECHO OFF
REM Identification for arguments
REM basename                          = %1
REM Project directory                 = %2
REM Problem directory                 = %3

REM OutputFile: "%2\%1.info"
REM ErrorFile: "%2\%1.err"

DEL "%2\%1.info"
DEL "%2\%1.err"

@REM set PATH=%3\\exec\\kratos;%3\\exec\\kratos\\libs;%PATH%

REM Run Python using the script MainKratos.py
%run_kratos_exe% .\MainKratos.py > "%2\\%1.info" 2> "%2\\%1.err"