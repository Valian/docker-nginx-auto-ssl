# docker-nginx-auto-ssl
![build](https://img.shields.io/docker/build/valian/docker-nginx-auto-ssl.svg)
![build](https://img.shields.io/docker/pulls/valian/docker-nginx-auto-ssl.svg)

Docker image for automatic generation of SSL certs using Let's encrypt and Open Resty, with reasonable SSL settings. 
You can specify allowed domains and simple proxies using ENV variables, and easily override `nginx.conf` to your needs. 

This is possible thanks to [OpenResty](https://github.com/openresty/openresty) and [lua-resty-auto-ssl](https://github.com/GUI/lua-resty-auto-ssl).

**Image status**: used in production. Some backward-compatible changes may be added in the future.

# Usage

Basic usage:
```Bash
docker run -d \
  -p 80:80 \
  -p 443:443 \
  valian/docker-nginx-auto-ssl
```

Created certs are kept in `/etc/resty-auto-ssl` directory. It's volume by default, but you may want to mount it to some directory on the host.

Available configuration options: 

 | Variable | Example | Description
 | --- | --- | ---|
 | ALLOWED_DOMAINS | `(www\|api).example.com`, `example.com`, `([a-z]+.)?example.com` | [lua pattern](http://lua-users.org/wiki/PatternsTutorial) of allowed domains. Internally, we're using `string.match`. By default we accept all domains | 
 | DIFFIE_HELLMAN | `true` | Force regeneration of `dhparam.pem`. If not specified, default one is used. |
 | SITES | `db.com=localhost:5432; *.app.com=localhost:8080`, `_=localhost:8080` | Shortcut for defining multiple proxies, in form of `domain1=endpoint1; domain2=endpoint2`. Default template for proxy is [here](https://github.com/Valian/docker-nginx-auto-ssl/blob/master/snippets/server-proxy.conf). Name `_` means default server, just like in nginx configuration |
 | FORCE_HTTPS | `true`, `false` | If `true`, automatically adds location to `resty-server-http.conf` redirecting traffic from http to https. `true` by default. |
 

If you want to proxy multiple sites (probably the most common case, that's why I've made it possible to achieve without custom configuration):

```Bash
docker run -d \
  --name nginx-auto-ssl \
  --restart on-failure \
  -p 80:80 \
  -p 443:443 \
  -e ALLOWED_DOMAINS=example.com \
  -e SITES='example.com=localhost:5432;*.example.com=localhost:8080' \
  valian/docker-nginx-auto-ssl
```

All options:
```Bash
docker run -d \
  --name nginx-auto-ssl \
  --restart on-failure \
  -p 80:80 \
  -p 443:443 \
  -e ALLOWED_DOMAINS=example.com \
  -e SITES='example.com=localhost:5432;*.example.com=localhost:8080' \
  -e DIFFIE_HELLMAN=true \
  -v ssl-data:/etc/resty-auto-ssl \
  valian/docker-nginx-auto-ssl
```

# Customization

## Includes from `/etc/nginx/conf.d/*.conf`

Additional server blocks are automatically loaded from `/etc/nginx/conf.d/*.conf`. If you want to provide your own configuration, you can either use volumes or create custom image.

Example server configuration (for example, named `server.conf`)

```nginx
server {
  listen 443 ssl default_server;
  
  # remember about this line!
  include resty-server-https.conf;

  location / {
    proxy_pass http://app;
  }
  
  location /api {
    proxy_pass http://api;
  }
}
```

Volumes way

```Bash
# instead of $PWD, use directory with your custom configurations
docker run -d \
  --name nginx-auto-ssl \
  --restart on-failure \
  -p 80:80 \
  -p 443:443 \
  -v $PWD:/etc/nginx/conf.d
  valian/docker-nginx-auto-ssl
```

Custom image way

```Dockerfile
FROM valian/docker-nginx-auto-ssl

# instead of . use directory with your configurations
COPY . /etc/nginx/conf.d
```

```Bash
docker build -t docker-nginx-auto-ssl .
docker run [YOUR_OPTIONS] docker-nginx-auto-ssl
```


## Using `$SITES` with your own template

You have to override `/usr/local/openresty/nginx/conf/server-proxy.conf` either using volume or custom image. Basic templating is implemented for variables `$SERVER_NAME` and `$SERVER_ENDPOINT`. 

Example template:

```nginx
server {
  listen 443 ssl;
  server_name $SERVER_NAME;

  include resty-server-https.conf;

  location / {
    proxy_pass http://$SERVER_ENDPOINT;
  }
}
```


## Your own `nginx.conf`

If you have custom requirements and other customization options are not enough, you can easily provide your own configuration.

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
  
  # required
  include resty-http.conf;

  server {
    listen 443 ssl;
    
    # required
    include resty-server-https.conf;
    
    # you should add your own locations here    
  }

  server {
    listen 80 default_server;
    
    # required
    include resty-server-http.conf;
  }
}
```

Minimal `nginx.conf` with support for `$SITES` and `conf.d` includes

```nginx
events {
  worker_connections 1024;
}

http {

  include resty-http.conf;

  server {
    listen 80 default_server;
    include resty-server-http.conf;
  }
  
  # you can insert your blocks here or inside conf.d
  
  include /etc/nginx/conf.d/*.conf;
}
```

Build and run it using
```Bash
docker build -t docker-nginx-auto-ssl .
docker run [YOUR_OPTIONS] docker-nginx-auto-ssl
```

# CHANGELOG

* **29-05-2017** - Fixed duplicate redirect location after container restart #2
* **19-12-2017** - Support for `$SITES` variable   
* **2-12-2017** - Dropped HSTS by default  
* **25-11-2017** - Initial release  


# LICENCE

MIT
