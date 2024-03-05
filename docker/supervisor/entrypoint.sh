#!/bin/sh

env >> /etc/environment

# start cron in the foreground (replacing the current process)
# exec cron -f 
# exec "$@"

# Ensure /etc/cron.d/cronjob is empty
> /etc/cron.d/cronjob

# Add content from /tmp/cronjob to /etc/cron.d/cronjob
cat /tmp/cronjob > /etc/cron.d/cronjob

# Give execution rights on the cron job
chown root:root /etc/cron.d/cronjob
chmod 0644 /etc/cron.d/cronjob

# Add cronjob
crontab -u root /etc/cron.d/cronjob

# Run supervisor
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
