#!/bin/bash -xe

if [ -n "$PASSWORD" ]; then 
    htpasswd -c -b /etc/nginx/.htpasswd "$USERNAME" "$PASSWORD"
else
    sed -i '/auth_basic/d' /opt/app-root/etc/nginx.d/labguides.conf
fi

chown -R nginx:nginx /var/lib/nginx

exec /usr/sbin/nginx -g 'daemon off;'
