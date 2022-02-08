@echo off
cd %1
echo "Installing python 3.9.9 from www.python.org"
rem --Download python installer
rem Curl is included in windows since 2018
curl -ssL "https://www.python.org/ftp/python/3.9.9/python-3.9.9-amd64.exe" -o python-installer.exe

rem --Install python
python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
del python-installer.exe
echo "Python 3.9.9 installed"

pause