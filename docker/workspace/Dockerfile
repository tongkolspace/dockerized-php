FROM easyengine/php8.1:v4.6.7

LABEL maintainer="Todi Adiyatmo <todiadiyatmo@gmail.com>"
LABEL org.label-schema.schema-version="1.0.0"
LABEL org.label-schema.vendor="Tongkolspace"
LABEL org.label-schema.name="workspace"

USER  root
RUN set -ex; \
    apt-get update; \
	apt-get install -y --no-install-recommends \
        rsync \
        git \
        curl \
        vim \
        nano \
        ca-certificates \
        inetutils-ping \
        gnupg \
        ntp \
        cron \
        supervisor \
    &&  rm -rf /etc/cron.*/* \
    # # #####################################
    # # # Node & NPM
    # # #####################################
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |  gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && NODE_MAJOR=20 \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" |  tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install nodejs -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # # #####################################
    # # # Add exec-www wrapper
    # # #####################################
    && echo "" >> /root/.bashrc  \
    && echo "exec-www() {" >> /root/.bashrc  \
    && echo "    su -s /bin/sh www-data -c \"\$*\"" >> /root/.bashrc  \
    && echo "}" >> /root/.bashrc \
    && echo "" >> /root/.bashrc  \
    ######################################
    # Add user workspace and asign id=1000
    ######################################
    && useradd -u 1000 -g www-data -G www-data workspace

COPY entrypoint.sh /entrypoint.sh

WORKDIR  /var/www/html

ENTRYPOINT ["/entrypoint.sh"]
