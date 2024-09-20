ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}
LABEL Maintainer="Todi <t@tonjoo.id>"
LABEL Description="PHP Web App Container"
ARG PHP_VERSION=8.2
ENV EDITOR=nano
ENV HOME=/home/app

# Setup document root
WORKDIR /var/www/html

# Install necessary packages and PHP
# Install necessary packages and PHP
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    add-apt-repository ppa:wordops/nginx-wo -uy && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    nginx-custom \
    nginx-wo \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-bcmath \
    gettext-base \
    apache2-utils \
    iproute2 \
    tzdata \
    iputils-ping \
    redis-tools \
    nano \
    supervisor && \
    apt-get autoremove -y && \
    apt-get purge -y --auto-remove && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Remove existing ubuntu user and create new app user
RUN if getent passwd ubuntu > /dev/null; then \
        userdel -r ubuntu; \
    fi && \
    if getent group ubuntu > /dev/null; then \
        groupdel ubuntu; \
    fi && \
    groupadd -g 1000 app && \
    useradd -u 1000 -g app -d /home/app -s /bin/bash -m app && \
    mkdir -p /tmp/nginx && \
    chown -R app:app /tmp/nginx


# Install WP-CLI
ENV PAGER=cat
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Nginx Config
RUN rm -rf /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*
COPY ./docker/app/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/app/nginx/common /etc/nginx/common
COPY ./docker/app/nginx/conf.d /etc/nginx/conf.d
COPY ./docker/app/nginx/sites-available /etc/nginx/sites-available
COPY ./docker/app/nginx/sites-available/wordpress.conf /etc/nginx/sites-enabled/wordpress.conf
COPY ./docker/app/nginx/snippets /etc/nginx/snippets
COPY ./docker/app/nginx/empty /etc/nginx/empty

# Web Apps
COPY --chown=app  --chmod=555 ./wordpress /var/www/html/
COPY --chown=app  --chmod=555 ./admin /var/www/admin/

RUN chmod 755 /var/www/html/wp-content

# PHP-FPM Config
COPY ./docker/app/php-fpm/php-fpm-prod.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY ./docker/app/php-fpm/php-prod.ini /etc/php/${PHP_VERSION}/fpm/conf.d/custom.ini

RUN ln -s /usr/sbin/php-fpm${PHP_VERSION} /usr/bin/php-fpm

# Supervisor Config
COPY --chown=app ./docker/app/supervisor /home/app/supervisor
COPY --chown=app ./docker/app/cron /home/app/cron

# Expose ports
EXPOSE 8000 57710

COPY --chown=app ./docker/app/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN chown -R app:app /run /var/lib/nginx /var/log/nginx /usr/local/bin/wp /etc/nginx
USER app

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]