set VERSION=10.3.0
@REM git checkout master
@REM git fetch -p
@REM git pull -p
@REM set BRANCH=Release-%VERSION%
@REM git branch %BRANCH%
@REM git checkout %BRANCH%

@REM check if docker is on
docker --version > NUL 2>&1
if %errorlevel% neq 0 ( 
    echo "Docker is not installed or not running. Please install Docker and try again."
    exit /b 1
)


@REM run python prepare-release-files.py
python prepare-release-files.py

git commit -am "Release %VERSION% preparation"

git tag -f Release-%version%
git push --tags --force

cd ..
mkdir dist
set FOLDER=dist\kratos-%VERSION%
@REM delete the folder recursive if it exists
if exist %FOLDER% rmdir /s /q %FOLDER%
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