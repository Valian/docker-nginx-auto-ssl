#!/bin/sh

# openresty will change it later on his own, right now we're just giving it access
chmod 777 /etc/resty-auto-ssl

# we want to keep dhparam.pem in volume, to generate just one time
if [ ! -f "/etc/resty-auto-ssl/dhparam.pem" ]; then
  if [ -n "$DIFFIE_HELLMAN" ]; then
    openssl dhparam -out /etc/resty-auto-ssl/dhparam.pem 2048
  else
    cp /usr/local/openresty/nginx/conf/dhparam.pem /etc/resty-auto-ssl/dhparam.pem
  fi
fi

envsubst '$ALLOWED_DOMAINS' < /usr/local/openresty/nginx/conf/resty-http.conf > /usr/local/openresty/nginx/conf/resty-http.conf.copy
mv /usr/local/openresty/nginx/conf/resty-http.conf.copy /usr/local/openresty/nginx/conf/resty-http.conf

exec "$@"