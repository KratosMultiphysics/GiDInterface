FROM ubuntu

RUN apt-get update && \
    apt-get install -y dos2unix && \
    apt-get clean

WORKDIR /tmp
COPY create-release.sh create-release.sh
RUN dos2unix create-release.sh
RUN chmod 755 /tmp/create-release.sh

CMD /tmp/create-release.sh
# docker build -t linux_releaser -f linux-releaser.dockerfile .
# docker run --rm -v ${PWD}/dist:/tmp/dist linux_releaser