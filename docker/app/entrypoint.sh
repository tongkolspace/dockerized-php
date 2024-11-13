#!/bin/sh

add_newline() {
    echo "" >> /home/app/supervisor/supervisord-app.conf
}

cat /home/app/supervisor/conf.d/supervisord.conf > /home/app/supervisor/supervisord-app.conf
add_newline

if [ "$ROLE_BACKGROUND" = "true" ]; then
    cat /home/app/supervisor/conf.d/background.conf >> /home/app/supervisor/supervisord-app.conf
    add_newline
    # crontab /home/app/cron/wordpress.cron
fi

if [ "$ROLE_NGINX" = "true" ]; then
    cat /home/app/supervisor/conf.d/nginx.conf >> /home/app/supervisor/supervisord-app.conf
    add_newline

    # Update .htpasswd
    if [ -n "$ADMIN_PANEL_USERNAME" ] && [ -n "$ADMIN_PANEL_PASSWORD" ]; then
        htpasswd -bc /etc/nginx/.htpasswd "$ADMIN_PANEL_USERNAME" "$ADMIN_PANEL_PASSWORD"
    fi
fi

if [ "$ROLE_PHP_FPM" = "true" ]; then
    cat /home/app/supervisor/conf.d/php-fpm.conf >> /home/app/supervisor/supervisord-app.conf
    
    # Copy custom.ini.template to custom.ini
    rm /etc/php/8.2/fpm/conf.d/custom.ini
    cp /etc/php/8.2/fpm/conf.d/custom.ini.template /etc/php/8.2/fpm/conf.d/custom.ini

    # Modify custom.ini based on REDIS_PASSWORD
    if [ -n "$REDIS_PASSWORD" ]; then
        sed -i "s/^session.save_path =.*/session.save_path = \"tcp:\/\/${REDIS_HOST}:6379?auth=${REDIS_PASSWORD}\"/" /etc/php/8.2/fpm/conf.d/custom.ini
    else
        sed -i "s/^session.save_path =.*/session.save_path = \"tcp:\/\/${REDIS_HOST}:6379\"/" /etc/php/8.2/fpm/conf.d/custom.ini
    fi
    
    add_newline
fi

# Set default value for REDIS_HOST if not provided
REDIS_HOST=${REDIS_HOST:-redis}

# Use envsubst to replace variables and write to the final config file
envsubst  < /etc/nginx/conf.d/upstream.conf.template > /etc/nginx/conf.d/upstream.conf

# Run supervisord with the generated configuration
exec /usr/bin/supervisord -c /home/app/supervisor/supervisord-app.conf