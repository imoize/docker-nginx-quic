# Nginx http3 Docker Image

NGINX is a web server that can be also used as a reverse proxy, load balancer, and HTTP cache. Recommended for high-demanding sites due to its ability to provide faster content.

[![Github Build Status](https://img.shields.io/github/actions/workflow/status/imoize/docker-nginx-quic/build.yml?color=458837&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=build&logo=github)](https://github.com/imoize/docker-nginx-quic/actions?workflow=build)
[![GitHub](https://img.shields.io/static/v1.svg?color=3C79F5&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=imoize&message=GitHub&logo=github)](https://github.com/imoize/docker-nginx-quic)
[![GitHub Package Repository](https://img.shields.io/static/v1.svg?color=3C79F5&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=imoize&message=GitHub%20Package&logo=github)](https://github.com/imoize/docker-nginx-quic/pkgs/container/nginx-quic)
[![Docker Pulls](https://img.shields.io/docker/pulls/imoize/nginx-quic.svg?color=3C79F5&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=pulls&logo=docker)](https://hub.docker.com/r/imoize/nginx-quic)

## Supported Architectures

Multi-platform available trough docker manifest. Simply pulling using `latest` tag should retrieve the correct image for your arch.

The architectures supported by this image:

| Architecture | Available |
| :----: | :----: |
| x86-64 | ✅ |
| arm64 | ✅ |

## Usage

Here are some example to help you get started creating a container, easiest way to setup is using docker-compose or use docker cli.

- **docker-compose (recommended)**

```yaml
---
version: "3.9"
services:
  nginx-quic:
    image: imoize/nginx-quic:latest
    container_name: nginx-quic
    ports:
      - 80:80
      - 443:443
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Asia/Jakarta
    volumes:
      - /path/to/app/data:/config
    restart: always
```

- **docker cli**

```bash
docker run -d \
  --name=nginx-quic \
  -p 80:80
  -p 443:443 \
  -e PUID=1001 \
  -e PGID=1001 \
  -e TZ=Asia/Jakarta \
  -v /path/to/app/data:/config \
  --restart always \
  imoize/nginx-quic:latest
```

## Available environment variables:

| Name                      | Description                                            | Default Value |
| ------------------------- | ------------------------------------------------------ | ------------- |
| PUID                      | User UID                                               |               |
| PGID                      | Group GID                                              |               |
| TZ                        | Specify a timezone see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List).       | UTC          |
| S6_VERBOSITY              | Controls the verbosity of s6-rc. See [this.](https://github.com/just-containers/s6-overlay?tab=readme-ov-file#customizing-s6-overlay-behaviour)    | 1             |

## Configuration

### Environment variables

When you start the nginx-quic image, you can adjust the configuration of the instance by passing one or more environment variables either on the `docker-compose` file or on the `docker run` command line. Please note that some variables are only considered when the container is started for the first time. If you want to add a new environment variable:

- **for `docker-compose` add the variable name and value:**

```yaml
nginx-quic:
    ...
    environment:
      - PUID=1001
      - TZ=Asia/Jakarta
      - S6_VERBOSITY=2
    ...
```

- **for manual execution add a `-e` option with each variable and value:**

```bash
  docker run -d \
  -e PUID=1001 \
  -e TZ=Asia/Jakarta \
  -e S6_VERBOSITY=2 \
  imoize/nginx-quic:latest
```

## Volume

### Persisting your application

If you remove the container all your data will be lost, and the next time you run the image the data and config will be reinitialized. To avoid this loss of data, you should mount a volume that will persist even after the container is removed.

For persistence you should map directory inside container in `/config` path to host directory as data volumes. Application state will persist as long as directory on the host are not removed.

**e.g:** `/path/to/app/data:/config`

```yaml
nginx-quic:
    ...
    environment:
      - PUID=1001
    volumes:
      - /path/to/app/data:/config
    ...
```

`/config` folder contains nginx relevant configuration files.

## User / Group Identifiers

For example: `PUID=1001` and `PGID=1001`, to find yours user `id` and `gid` type `id <your_username>` in terminal.
```bash
  $ id your_username
    uid=1001(user) gid=1001(group) groups=1001(group)
```

## Issue certificate and install with acme.sh

### Request certificate

1. Access shell inside container
```bash
docker exec -it nginx-quic bash
```

2. Request new certificate

```bash
DOMAIN="YOUR-DOMAIN"

export CF_Token="Your_Cloudflare_DNS_API_Key_Goes_here"

acme.sh --issue --dns dns_cf --ocsp-must-staple -d "$DOMAIN" -d "*.${DOMAIN}"
```

3. Install certificate

```bash
DOMAIN="YOUR-DOMAIN"

CERT_DIR="/config/ssl/acme/${DOMAIN}"

mkdir -p "$CERT_DIR"

acme.sh -d "$DOMAIN" \
--install-cert \
--cert-file "${CERT_DIR}/${DOMAIN}.cer" \
--key-file "${CERT_DIR}/${DOMAIN}.key" \
--ca-file "${CERT_DIR}/ca.cer" \
--fullchain-file "${CERT_DIR}/fullchain.cer" \
--reloadcmd "chown -R $PUID:$PGID /config/ssl/acme && s6-svc -1 -h -r /run/service/svc-nginx"
```
### Edit nginx config

If /config is bind-mount to host then you can edit in your host folder directly.

1. Edit config in /config/nginx/site-confs/default.conf, don't forget to replace YOUR-DOMAIN. should look like this : 

```bash
server {
    listen      80;
    listen [::]:80;

    server_name YOUR-DOMAIN;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}
server {
    listen      443 ssl;
    listen [::]:443 ssl;

    listen      443 quic;
    listen [::]:443 quic;

    server_name YOUR-DOMAIN;

    # uncomment
    include /config/nginx/conf.d/headers.conf;
```

2. By default this image using self-signed certificate, Edit config in /config/nginx/conf.d/ssl.conf, don't forget to replace YOUR-DOMAIN. should look like this : 

```bash
# self-signed certificate
# ssl_certificate /config/ssl/self-signed/cert.crt;
# ssl_certificate_key /config/ssl/self-signed/cert.key;

# acme letsencrypt certificate
ssl_certificate /config/ssl/acme/YOUR-DOMAIN/fullchain.cer;
ssl_certificate_key /config/ssl/acme/YOUR-DOMAIN/YOUR-DOMAIN.key;

# OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /config/ssl/acme/YOUR-DOMAIN/fullchain.cer;
```
3. Restart your container to take effect.

## Crowdsec
1. Install crowdsec.
2. open `/path/to/crowdsec/acquis.d/appsec.yaml` and fill it with:
```yaml
listen_addr: 0.0.0.0:7422
appsec_config: crowdsecurity/virtual-patching
name: myAppSecComponent
source: appsec
labels:
  type: appsec
```
3. open `/path/to/crowdsec/acquis.d/nginx.yaml` and fill it with:
```yaml
filenames:
  - /var/log/nginx/access.log
labels:
  type: nginx
---
source: docker
container_name:
 - nginx
labels:
  type: nginx
```

4. run `docker exec crowdsec cscli bouncers add nginx-bouncer` and save the output
5. open `/config/crowdsec/crowdsec.conf`
6. set `ENABLED` to `true`
7. use the output of step 4 as `API_KEY`
8. save the file

## Contributing

We'd love for you to contribute to this container. You can submitting a [pull request](https://github.com/imoize/docker-nginx-quic/pulls) with your contribution.

## Issues

If you encountered a problem running this container, you can create an [issue](https://github.com/imoize/docker-nginx-quic/issues).