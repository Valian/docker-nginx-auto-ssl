#!/bin/bash

RESTY_CONF_DIR="/usr/local/openresty/nginx/conf"
NGINX_CONF_DIR="/etc/nginx/conf.d"

# openresty will change it later on his own, right now we're just giving it access
chmod 777 /etc/resty-auto-ssl

# we want to keep dhparam.pem in volume, to generate just one time
if [ ! -f "/etc/resty-auto-ssl/dhparam.pem" ]; then
  if [ -n "$DIFFIE_HELLMAN" ]; then
    openssl dhparam -out /etc/resty-auto-ssl/dhparam.pem 2048
  else
    cp ${RESTY_CONF_DIR}/dhparam.pem /etc/resty-auto-ssl/dhparam.pem
  fi
fi


# if $SITES is defined, we should prepare configuration files
# example usage:
#
# -e SITES="db.example.com=localhost:5432;app.example.com=http://localhost:8080"
#
# it will create 2 files:
#
# 1. /etc/nginx/conf.d/db.example.com.conf using $SERVER_ENDPOINT=localhost:5432 and $SERVER_NAME=db.example.com
# 2. /etc/nginx/conf.d/app.example.com.conf using $SERVER_ENDPOINT=localhost:8080 and $SERVER_NAME=app.example.com

if [ -n "$SITES" ]; then
  # lets read all backends, separated by ';'
  IFS=\; read -a SITES_SEPARATED <<<"$SITES"

  # for each backend (in form of server_name=endpoint:port) we create proper file
  for NAME_EQ_ENDPOINT in "${SITES_SEPARATED[@]}"; do
    RAW_SERVER_ENDPOINT=${NAME_EQ_ENDPOINT#*=}
    export SERVER_NAME=${NAME_EQ_ENDPOINT%=*}
    export SERVER_ENDPOINT=${RAW_SERVER_ENDPOINT#*//}  # it clears url scheme, like http:// or https://
    envsubst '$SERVER_NAME $SERVER_ENDPOINT' \
    < ${RESTY_CONF_DIR}/server-proxy.conf \
    > ${NGINX_CONF_DIR}/${SERVER_NAME}.conf
  done
  unset SERVER_NAME SERVER_ENDPOINT


# if $SITES isn't defined, let's check if $NGINX_CONF_DIR is empty
elif [ ! "$(ls -A ${NGINX_CONF_DIR})" ]; then
  # if yes, just copy default server (similar to default from docker-openresty, but using https)
  cp ${RESTY_CONF_DIR}/server-default.conf ${NGINX_CONF_DIR}/default.conf
fi


if [ "$FORCE_HTTPS" == "true" ]; then
  # only do this, if it's first run
  if ! grep -q "force-https.conf" ${RESTY_CONF_DIR}/resty-server-http.conf
  then
    echo "include force-https.conf;" >> ${RESTY_CONF_DIR}/resty-server-http.conf
  fi
fi


# let's substitute $ALLOWED_DOMAINS, $LETSENCRYPT_URL and $RESOLVER_ADDRESS into OpenResty configuration
envsubst '$ALLOWED_DOMAINS,$LETSENCRYPT_URL,$RESOLVER_ADDRESS' \
  < ${RESTY_CONF_DIR}/resty-http.conf \
  > ${RESTY_CONF_DIR}/resty-http.conf.copy \
  && mv ${RESTY_CONF_DIR}/resty-http.conf.copy ${RESTY_CONF_DIR}/resty-http.conf

exec "$@"