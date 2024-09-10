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

if [ "$ROLE_WEB" = "true" ]; then
    cat /home/app/supervisor/conf.d/nginx.conf >> /home/app/supervisor/supervisord-app.conf
    add_newline
fi

if [ "$ROLE_PHP_FPM" = "true" ]; then
    cat /home/app/supervisor/conf.d/php-fpm.conf >> /home/app/supervisor/supervisord-app.conf
    add_newline
fi

# Run supervisord with the generated configuration
exec /usr/bin/supervisord -c /home/app/supervisor/supervisord-app.conf