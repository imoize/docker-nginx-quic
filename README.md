# Nginx http3 Docker Image

This docker image is intended for use as a webserver

## Issue certificate and install with acme.sh

### Request certificate

1. Access shell inside container
```bash
docker exec -it nginx bash
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

1. Edit config in /config/nginx/site-confs/default.conf, dont forget to replace YOUR-DOMAIN. should look like this : 

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

    # include more config
    include /config/nginx/conf.d/security.conf; #add this
```

2. By default this image using self-signed certificate, Edit config in /config/nginx/conf.d/ssl.conf, dont forget to replace YOUR-DOMAIN. should look like this : 

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
7. use the output of step 5 as `API_KEY`
8. save the file