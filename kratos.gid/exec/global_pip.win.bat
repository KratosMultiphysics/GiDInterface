REM @ECHO OFF
REM Identification for arguments
REM basename                          = %1
REM Project directory                 = %2
REM Problem directory                 = %3

REM OutputFile: "%2\%1.info"
REM ErrorFile: "%2\%1.err"

REM Remove previous calculation files and results
DEL "%2\%1.info"
DEL "%2\%1.err"
DEL "%2\%1*.post.bin"
DEL "%2\%1*.post.res"
DEL "%2\%1*.post.msh"

REM Install dependencies if needed
pip install numpy
pip install KratosFluidDynamicsApplication

@REM Calculate! 
python MainKratos.py > "%2\\%1.info" 2> "%2\\%1.err"
