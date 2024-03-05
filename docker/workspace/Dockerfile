FROM easyengine/php8.2:v4.6.7

LABEL maintainer="Todi Adiyatmo <todiadiyatmo@gmail.com>"
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
    &&  rm -rf /etc/cron.*/* \
    # # #####################################
    # # # Node & NPM
    # # #####################################
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key |  gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && NODE_MAJOR=20 \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" |  tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install nodejs nano iputils-ping traceroute redis-tools -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    ######################################
    # Add user workspace and asign id=1000
    ######################################
    && useradd -u 1000 -g www-data -G www-data workspace \
    && groupadd workspace -g 1000  \
    && usermod -a -G workspace workspace \
    && mkdir /home/workspace  \
    && chown workspace:workspace /home/workspace

USER  workspace
WORKDIR  /var/www/html
CMD []