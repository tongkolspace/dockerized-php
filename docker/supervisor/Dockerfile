FROM tongkolspace/workspace:8.2-v1.0.1

LABEL maintainer="Todi Adiyatmo <todiadiyatmo@gmail.com>"
LABEL org.label-schema.vendor="Tongkolspace"
LABEL org.label-schema.name="supervisor"

USER  root
RUN set -ex; \
    apt-get update; \
	apt-get install -y --no-install-recommends \
        cron \
        supervisor \
    &&  rm -rf /etc/cron.*/* 

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
WORKDIR  /var/www/html
ENTRYPOINT ["/entrypoint.sh"]