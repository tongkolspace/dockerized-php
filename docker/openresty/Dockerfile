FROM openresty/openresty:1.21.4.1-0-jammy

# Copy EasyEngine nginx configuration files
RUN mkdir -p /var/log/nginx; \
    mkdir -p /usr/local/openresty/nginx/conf/conf.d
COPY conf /usr/local/openresty/nginx/conf

EXPOSE 80