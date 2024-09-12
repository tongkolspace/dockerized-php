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
    add_newline
fi

# Run supervisord with the generated configuration
exec /usr/bin/supervisord -c /home/app/supervisor/supervisord-app.conf