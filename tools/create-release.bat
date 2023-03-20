set VERSION=9.3.3
git checkout master
git fetch -p
git pull -p
@REM set BRANCH=Release-%VERSION%
@REM git branch %BRANCH%
@REM git checkout %BRANCH%
cd ..
mkdir dist
set FOLDER=dist\kratos-%VERSION%-win-64\kratos.gid
mkdir %FOLDER%
xcopy /s/e/y kratos.gid %FOLDER%
