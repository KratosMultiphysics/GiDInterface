
set krversion=9.3
set pyversion=3.11.2-alpine3.17
echo "Building kratos %krversion% on python %pyversion%"
docker build --build-arg version=%krversion% --build-arg pyversion=%pyversion% -t kratos-run:%krversion%-py%pyversion% .
docker tag kratos-run:%krversion% fjgarate/kratos-run:%krversion%
@REM docker push fjgarate/kratos-run:%krversion%

@REM docker build -t -t kratos-run:latest .
@REM docker tag kratos-run:latest fjgarate/kratos-run:latest
@REM docker push fjgarate/kratos-run:latest