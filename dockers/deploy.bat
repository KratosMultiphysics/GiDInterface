set krversion=10.3.0
set pyversion=3.11
@REM 3.10.10-alpine3.17
echo "Building kratos %krversion% on python %pyversion%"
docker build --build-arg krversion=%krversion% --build-arg pyversion=%pyversion% -t kratos-run:%krversion% -t kratos-run:latest .

docker tag kratos-run:%krversion% fjgarate/kratos-run:%krversion%
docker push fjgarate/kratos-run:%krversion%

docker tag kratos-run:latest fjgarate/kratos-run:latest
docker push fjgarate/kratos-run:latest