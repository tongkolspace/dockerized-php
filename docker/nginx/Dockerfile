FROM ubuntu:22.04

LABEL maintainer="Todi Adiyatmo <todiadiyatmo@gmail.com>"
LABEL org.label-schema.vendor="Tongkolspace"
LABEL org.label-schema.name="nginx-ee"


# Install wget and curl (necessary for the script)
RUN apt-get update && apt-get install -yq tzdata  wget curl software-properties-common unzip iputils-ping wget nano logrotate cron\
    && ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime  \
    && dpkg-reconfigure -f noninteractive tzdata \
    && add-apt-repository ppa:wordops/nginx-wo -uy && apt-get update \
    && apt install nginx-custom nginx-wo -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN  wget https://github.com/VirtuBox/nginx-config/archive/refs/heads/master.zip -P /tmp \
    && unzip /tmp/master.zip -d /tmp \
    && mv /tmp/nginx-config-master/common /etc/nginx/ \
    && cp -r /tmp/nginx-config-master/conf.d/* /etc/nginx/conf.d \
    && rm -rf /tmp/*

# Expose ports 80 and 443 for HTTP and HTTPS traffic
EXPOSE 80 443

# Set the default command to start Nginx in the foreground
CMD service cron start && nginx -g 'daemon off;'
