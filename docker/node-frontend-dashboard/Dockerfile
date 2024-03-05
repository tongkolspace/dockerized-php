FROM node:21-bookworm

RUN set -ex; \
    apt-get update; \
	apt-get install -y --no-install-recommends \
    curl \
    vim \
    nano \
    ca-certificates \
    inetutils-ping 

WORKDIR /usr/src/service
EXPOSE 8080
USER node
