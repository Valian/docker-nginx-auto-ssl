# docker-nginx-auto-ssl
Docker image for automatic generation of SSL certs using Let's encrypt and Open Resty, with reasonable SSL settings. 
You can specify allowed domains using ENV variable, and easily override `nginx.conf` to your needs. 

This is possible thanks to [OpenResty](https://github.com/openresty/openresty) and [lua-resty-auto-ssl](https://github.com/GUI/lua-resty-auto-ssl).

# Usage

Simply run:
```Bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  valian/docker-nginx-auto-ssl
```

Created certs are kept in `/etc/resty-auto-ssl` directory. It's volume by default, but you may want to mount it to some directory on the host.

All options:  
**ALLOWED_DOMAINS** - [lua pattern](http://lua-users.org/wiki/PatternsTutorial) of allowed domains. We're using `string.match`  
**DIFFIE_HELLMAN** - force regeneration of `dhparam.pem`. If not specified, default one is used.

Advanced usage:
```Bash
docker run -d \
  --name nginx-auto-ssl \
  --restart on-failure \
  -p 80:80 \
  -p 443:443 \
  -e ALLOWED_DOMAINS=.*example.com \
  -e DIFFIE_HELLMAN=true \
  -v ssl-data:/etc/resty-auto-ssl \
  valian/docker-nginx-auto-ssl
```

# Custom `nginx.conf`

Currently, image just generates SSL certs on-the-fly. You have to provide your own configuration to be able to use image.

Example `Dockerfile`:
```Dockerfile
FROM valian/docker-nginx-auto-ssl

COPY nginx.conf /usr/local/openresty/nginx/conf/
```

Minimal working `nginx.conf`:
```nginx
events {
  worker_connections 1024;
}

http {

  include resty-http.conf;

  server {
    listen 443 ssl;

    include ssl.conf;
    include resty-server-https.conf;
    
    # you should add provide your own locations here
    
  }

  server {
    listen 80 default_server;

    include resty-server-http.conf;
  }
}
```
