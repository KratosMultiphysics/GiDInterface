REM @ECHO OFF
REM Identification for arguments
REM basename                          = %1
REM Project directory                 = %2
REM Problem directory                 = %3

REM OutputFile: "%2\%1.info"
REM ErrorFile: "%2\%1.err"

DEL "%2\%1.info"
DEL "%2\%1.err"

set PATH=%run_kratos_exe%;%run_kratos_exe%\\libs;%PATH%

REM Run Python using the script MainKratos.py
%run_kratos_exe%\\runkratos .\MainKratos.py > "%2\\%1.info" 2> "%2\\%1.err"