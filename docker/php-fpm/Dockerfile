FROM easyengine/php8.2:v4.6.7

LABEL maintainer="Todi Adiyatmo <todiadiyatmo@gmail.com>"
LABEL org.label-schema.vendor="Tongkolspace"
LABEL org.label-schema.name="php-fpm"

USER  root
    ######################################
    # Add user workspace and asign id=1000
    ######################################
RUN useradd -u 1000 -g www-data -G www-data workspace \
    && groupadd workspace -g 1000  \
    && usermod -a -G workspace workspace \
    && mkdir /home/workspace  \
    && chown workspace:workspace /home/workspace

USER  www-data
