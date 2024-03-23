ARG TARGETARCH
ARG NGINX_VERSION

ARG NGINX_VER=${NGINX_VERSION}
ARG OPENSSL_VER=openssl-3.1.5+quic

ARG LUAJIT_INC=/usr/include/luajit-2.1
ARG LUAJIT_LIB=/usr/lib

ARG DTR_VER=1.25.1
ARG RCP_VER=1.25.3

ARG NB_VER=master
ARG NCP_VER=master
ARG HMNM_VER=v0.37
ARG NDK_VER=v0.3.3
ARG NJS_VER=0.8.3
ARG LNM_VER=v0.10.26
ARG LRC_VER=v0.1.28
ARG LRL_VER=v0.13
ARG NHG2M_VER=3.4
ARG CSNB_VER=v1.0.7

ARG CONFIG="\
		--prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/run/nginx/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-libatomic \
        --with-pcre \
        --with-pcre-jit \
        --with-openssl="/src/openssl" \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_geoip_module=dynamic \
        --with-http_xslt_module=dynamic \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_geoip_module=dynamic \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --add-module=/src/ngx_brotli \
        --add-module=/src/ngx_cache_purge \
        --add-module=/src/headers-more-nginx-module \
        --add-module=/src/ngx_devel_kit \
        --add-module=/src/njs/nginx \
        --add-module=/src/lua-nginx-module \
        --add-dynamic-module=/src/ngx_http_geoip2_module \
	"

FROM imoize/alpine-s6:3.19 AS build

ARG TARGETARCH
ARG NGINX_VER
ARG OPENSSL_VER

ARG LUAJIT_INC
ARG LUAJIT_LIB

ARG DTR_VER
ARG RCP_VER

ARG NB_VER
ARG NCP_VER
ARG HMNM_VER
ARG NDK_VER
ARG NJS_VER
ARG LNM_VER
ARG LRC_VER
ARG LRL_VER
ARG NHG2M_VER
ARG CSNB_VER

ARG CONFIG

WORKDIR /src
# Requirements
RUN apk add --no-cache --virtual .build-deps \ 
        autoconf \
        automake \
        build-base \
        ca-certificates \
        cmake \
        curl-dev \
        geoip-dev \
        git \
        libtool \
        linux-headers \
        libatomic_ops-dev \
        libxml2-dev \
        libxslt-dev \
        libfuzzy2-dev \
        lmdb-dev \
        libmaxminddb-dev \
        luajit-dev \
        lua5.1-dev \
        patch \
        pcre2-dev \
        yajl-dev \
        zlib-dev
# Openssl
RUN git clone https://github.com/quictls/openssl --branch "$OPENSSL_VER" /src/openssl
# Nginx
RUN wget https://nginx.org/download/nginx-"$NGINX_VER".tar.gz -O - | tar xzC /src && \
    mv /src/nginx-"$NGINX_VER" /src/nginx && \
    wget https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_"$DTR_VER"%2B.patch -O /src/nginx/1.patch && \
    wget https://raw.githubusercontent.com/openresty/openresty/master/patches/nginx-"$RCP_VER"-resolver_conf_parsing.patch -O /src/nginx/2.patch && \
    cd /src/nginx && \
    patch -p1 </src/nginx/1.patch && \
    patch -p1 </src/nginx/2.patch && \
    rm /src/nginx/*.patch && \
# modules
    git clone --recursive https://github.com/google/ngx_brotli --branch "$NB_VER" /src/ngx_brotli && \
    git clone --recursive https://github.com/nginx-modules/ngx_cache_purge --branch "$NCP_VER" /src/ngx_cache_purge && \
    git clone --recursive https://github.com/openresty/headers-more-nginx-module --branch "$HMNM_VER" /src/headers-more-nginx-module && \
    git clone --recursive https://github.com/vision5/ngx_devel_kit --branch "$NDK_VER" /src/ngx_devel_kit && \
    git clone --recursive https://github.com/nginx/njs --branch "$NJS_VER" /src/njs && \
    git clone --recursive https://github.com/openresty/lua-nginx-module --branch "$LNM_VER" /src/lua-nginx-module && \
    git clone --recursive https://github.com/openresty/lua-resty-core --branch "$LRC_VER" /src/lua-resty-core && \
    git clone --recursive https://github.com/openresty/lua-resty-lrucache --branch "$LRL_VER" /src/lua-resty-lrucache && \
    git clone --recursive https://github.com/leev/ngx_http_geoip2_module --branch "$NHG2M_VER" /src/ngx_http_geoip2_module && \
    git clone --recursive https://github.com/crowdsecurity/cs-nginx-bouncer --branch "$CSNB_VER" /src/cs-nginx-bouncer && \
# Crowdsec
    cd /src/cs-nginx-bouncer && \
    make && \
    tar xzf crowdsec-nginx-bouncer.tgz && \
    mv crowdsec-nginx-bouncer-* crowdsec-nginx-bouncer && \
    sed -i "/lua_package_path/d" /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/nginx/crowdsec_nginx.conf && \
    sed -i "s|/etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf|/config/crowdsec/crowdsec.conf|g" /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/nginx/crowdsec_nginx.conf && \
    sed -i "s|API_KEY=.*|API_KEY=|g" /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf && \
    sed -i "s|ENABLED=.*|ENABLED=false|g" /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf && \
    sed -i "s|API_URL=.*|API_URL=http://127.0.0.1:8080|g" /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf && \
    sed -i "s|BAN_TEMPLATE_PATH=.*|BAN_TEMPLATE_PATH=/config/crowdsec/ban.html|g" /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf && \
    sed -i "s|CAPTCHA_TEMPLATE_PATH=.*|CAPTCHA_TEMPLATE_PATH=/config/crowdsec/captcha.html|g" /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf && \
    sed -i "s|BOUNCING_ON_TYPE=all|BOUNCING_ON_TYPE=ban|g" /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf && \
    echo "APPSEC_URL=http://127.0.0.1:7422" | tee -a /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf && \
    echo "APPSEC_FAILURE_ACTION=deny" | tee -a /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf
# Configure
RUN mkdir -p /var/run/nginx/ && \
    cd /src/nginx && \
    ./configure $CONFIG \
        --with-cc-opt="-Os -fstack-clash-protection -Wformat -Werror=format-security -fno-plt -g" \
        --with-ld-opt="-Wl,--as-needed,-O1,--sort-common -Wl,-z,pack-relative-relocs" && \
# Build & Install
    make -j "$(nproc)" && \
    make -j "$(nproc)" install && \
    strip -s /usr/sbin/nginx && \
    strip -s /usr/lib/nginx/modules/*.so && \
    cd /src/lua-resty-core && \
    make -j "$(nproc)" install PREFIX=/usr/local/ && \
    cd /src/lua-resty-lrucache && \
    make -j "$(nproc)" install PREFIX=/usr/local/ && \
    perl /src/openssl/configdata.pm --dump && \
    rm -rf \
        /etc/nginx/html/ \
        /etc/nginx/*.default && \
	mkdir /etc/nginx/conf.d/ && \
    # Bring in gettext so we can get `envsubst`, then throw
	# the rest away. To do this, we need to install `gettext`
	# then move `envsubst` out of the way so `gettext` can
	# be deleted completely, then move `envsubst` back.
	apk add --no-cache --virtual .gettext gettext && \
	\
	scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /usr/bin/envsubst \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u > /tmp/runDeps.txt

FROM imoize/alpine-s6:3.19 

# ACME.SH Env
ENV LE_WORKING_DIR=/usr/local/acme.sh
ENV LE_CONFIG_HOME=/config/acme.sh

COPY --from=build /etc/nginx                        /etc/nginx
COPY --from=build /usr/sbin/nginx                   /usr/sbin/
COPY --from=build /var/run/nginx/                   /var/run/nginx/
COPY --from=build /usr/lib/nginx/modules/*.so       /usr/lib/nginx/modules/
COPY --from=build /usr/local/lib/perl5/site_perl    /usr/local/lib/perl5/site_perl
COPY --from=build /usr/local/lib/lua                /usr/local/lib/lua
COPY --from=build /usr/bin/envsubst                 /usr/local/bin/envsubst
COPY --from=build /tmp/runDeps.txt                  /tmp/runDeps.txt

COPY --from=build /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/lib/plugins            /usr/local/lib/lua/plugins
COPY --from=build /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/lib/crowdsec.lua       /usr/local/lib/lua/crowdsec.lua
COPY --from=build /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/templates/ban.html     /defaults/crowdsec/ban.html
COPY --from=build /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/templates/captcha.html /defaults/crowdsec/captcha.html
COPY --from=build /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/lua-mod/config_example.conf    /defaults/crowdsec/crowdsec.conf
COPY --from=build /src/cs-nginx-bouncer/crowdsec-nginx-bouncer/nginx/crowdsec_nginx.conf      /defaults/nginx/samples/crowdsec_nginx.conf

RUN \
	apk add --no-cache --virtual .nginx-rundeps $(cat /tmp/runDeps.txt) \
    apache2-utils \
    libidn \
    libcurl \
    libxml2 \
    libxslt \
    libfuzzy2 \
    libstdc++ \
    lmdb \
    lua5.1-libs \
    lua5.1-lzlib \
    lua5.1-socket \
    openssl \
    patch \
    yajl && \
    \
    apk add --no-cache --virtual .lua-rundeps \
    build-base \
    lua5.1-dev \
    lua5.1-sec \
    luarocks5.1 && \
    luarocks-5.1 install lua-cjson && \
    luarocks-5.1 install lua-resty-http && \
    luarocks-5.1 install lua-resty-string && \
    luarocks-5.1 install lua-resty-openssl && \
    apk del --no-cache --purge .lua-rundeps && \
	mkdir -p /var/log/nginx /var/cache/nginx && \
	ln -s /usr/lib/nginx/modules /etc/nginx/modules && \
    rm -rf \
        /tmp/* \
        /var/cache/apk/* \
        /usr/local/lib/luarocks \
        /tmp/runDeps.txt

COPY src/ /

WORKDIR /config
EXPOSE 80 443