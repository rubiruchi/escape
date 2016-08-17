FROM ubuntu:14.04.5
MAINTAINER Janos Czentye <czentye@tmit.bme.hu>
LABEL Description="ESCAPE: Multi-domain Orchestrator" Project="UNIFY" version="2.0"
COPY . /home/escape/
COPY docker/.ssh/ /root/.ssh/
WORKDIR /home/escape
RUN apt-get update && apt-get install -y git wget &&\
    # Set locale to avoid annoying warnings
    locale-gen en_US.UTF-8 &&\
    export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
# Install MdO dependencies
RUN ./install-dep.sh -c
# REST-APIs:  Service Layer  |  Resource Orchestration Layer  |  Cf-Or
EXPOSE 8008 8888 8889
# Start ESCAPE by default
ENTRYPOINT ["./escape.py"]
# Default parameter is debug logging
CMD ["-d", "-c", "docker/default-docker.config"]