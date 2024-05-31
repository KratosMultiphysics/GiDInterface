set VERSION=9.5.1
@REM git checkout master
@REM git fetch -p
@REM git pull -p
@REM set BRANCH=Release-%VERSION%
@REM git branch %BRANCH%
@REM git checkout %BRANCH%
cd ..
mkdir dist
set FOLDER=dist\kratos-%VERSION%
mkdir %FOLDER%
xcopy /s/e/y/q kratos.gid %FOLDER%\kratos.gid\
copy LICENSE.md %FOLDER%\kratos.gid\LICENSE.md
copy README.md %FOLDER%\kratos.gid\README.md

set RELEASE_FILE=kratos-%VERSION%-win-64.zip
del /f /q %RELEASE_FILE% 2>NUL
powershell.exe -noprofile -command "Compress-Archive -Path '%FOLDER%\*' -DestinationPath %RELEASE_FILE%"
del /f /q .\dist\%RELEASE_FILE% 2>NUL
move %RELEASE_FILE% .\dist\%RELEASE_FILE%
echo "Windows version created -> kratos-%VERSION%-win-64"

cd ./dockers
docker build -t linux_releaser -f linux-releaser.dockerfile .
set PWD=%cd%
docker run --rm -v "%PWD%\..\dist:/tmp/dist" linux_releaser

echo "Linux version created -> kratos-%VERSION%-linux-64"