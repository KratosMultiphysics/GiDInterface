set krversion=10.3.0
set pyversion=3.12
@REM 3.10.10-alpine3.17
echo "Building kratos %krversion% on python %pyversion%"
set SCRIPT_DIR=%~dp0
set ROOT_DIR=%SCRIPT_DIR%..

docker build --build-arg pyversion=%pyversion% -f "%ROOT_DIR%\dockers\dockerfile" -t kratos-run:%krversion% -t kratos-run:latest "%ROOT_DIR%"

docker tag kratos-run:%krversion% fjgarate/kratos-run:%krversion%
docker push fjgarate/kratos-run:%krversion%

docker tag kratos-run:latest fjgarate/kratos-run:latest
docker push fjgarate/kratos-run:latest