FROM ubuntu

WORKDIR /tmp
COPY create-release.sh create-release.sh
RUN chmod 755 /tmp/create-release.sh

CMD /tmp/create-release.sh
# docker build -t linux_releaser -f linux-releaser.dockerfile .
# docker run -v ${PWD}/dist:/tmp/dist linux_releaser