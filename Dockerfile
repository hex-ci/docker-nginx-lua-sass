FROM alpine:3.7

LABEL maintainer="Hex <hex@codeigniter.org.cn>"

ENV NGINX_VERSION 1.12.2
ENV DEVEL_KIT_MODULE_VERSION 0.3.0
ENV LUA_MODULE_VERSION 0.10.13
ENV LIBSASS_VERSION 3.5.4

ENV LUAJIT_LIB=/usr/lib
ENV LUAJIT_INC=/usr/include/luajit-2.1

RUN addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && apk update --no-cache \
    && apk upgrade --no-cache \
    && apk add --no-cache lua5.1-lzlib \
    && apk add --no-cache --virtual .build-deps \
       gcc \
       g++ \
       libc-dev \
       make \
       automake \
       autoconf \
       libtool \
       file \
       openssl-dev \
       pcre-dev \
       zlib-dev \
       linux-headers \
       curl \
       libxslt-dev \
       gd-dev \
       geoip-dev \
       luajit-dev \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL https://github.com/simplresty/ngx_devel_kit/archive/v$DEVEL_KIT_MODULE_VERSION.tar.gz -o ndk.tar.gz \
    && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v$LUA_MODULE_VERSION.tar.gz -o lua.tar.gz \
    && curl -fSL https://github.com/sass/libsass/archive/$LIBSASS_VERSION.tar.gz -o libsass.tar.gz \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && tar -zxC /usr/src -f ndk.tar.gz \
    && tar -zxC /usr/src -f lua.tar.gz \
    && tar -zxC /usr/src -f libsass.tar.gz \
    && rm nginx.tar.gz ndk.tar.gz lua.tar.gz libsass.tar.gz \
    && cd /usr/src/libsass-$LIBSASS_VERSION \
    && autoreconf --force --install \
    && ./configure --disable-tests --disable-static \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && ./configure \
       --prefix=/etc/nginx \
       --sbin-path=/usr/sbin/nginx \
       --modules-path=/usr/lib/nginx/modules \
       --conf-path=/etc/nginx/nginx.conf \
       --error-log-path=/var/log/nginx/error.log \  
       --http-log-path=/var/log/nginx/access.log \
       --pid-path=/var/run/nginx.pid \
       --lock-path=/var/run/nginx.lock \
       --http-client-body-temp-path=/var/cache/nginx/client_temp \
       --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
       --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
       --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
       --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
       --user=nginx \
       --group=nginx \
       --with-http_ssl_module \
       --with-http_realip_module \
       --with-http_addition_module \
       --with-http_sub_module \
       --with-http_dav_module \
       --with-http_flv_module \
       --with-http_mp4_module \
       --with-http_gunzip_module \
       --with-http_gzip_static_module \
       --with-http_random_index_module \
       --with-http_secure_link_module \
       --with-http_stub_status_module \
       --with-http_auth_request_module \
       --with-http_xslt_module=dynamic \
       --with-http_image_filter_module=dynamic \
       --with-http_geoip_module=dynamic \
       --with-threads \
       --with-stream \
       --with-stream_ssl_module \
       --with-stream_ssl_preread_module \
       --with-stream_realip_module \
       --with-stream_geoip_module=dynamic \
       --with-http_slice_module \
       --with-mail \
       --with-mail_ssl_module \
       --with-compat \
       --with-file-aio \
       --with-http_v2_module \
       --add-module=/usr/src/ngx_devel_kit-$DEVEL_KIT_MODULE_VERSION \
       --add-module=/usr/src/lua-nginx-module-$LUA_MODULE_VERSION \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && rm -rf /etc/nginx/html/ \
    && mkdir /etc/nginx/conf.d/ \
    && mkdir -p /usr/share/nginx/html/ \
    && install -m644 html/index.html /usr/share/nginx/html/ \
    && install -m644 html/50x.html /usr/share/nginx/html/ \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    && strip /usr/sbin/nginx* \
    && strip /usr/lib/nginx/modules/*.so \
    && strip /usr/local/lib/*.so \
    && strip /usr/lib/*.so.* \
    && strip /usr/lib/lua/5.1/*.so \
    && strip /usr/lib/engines/*.so \
    && rm -rf /usr/src \
    && rm -rf /var/cache/apk/* \
    && rm -rf /usr/local/include/* \
    && cp -a /usr/lib/libstdc++.so* /tmp/ \
    \
    # Bring in gettext so we can get `envsubst`, then throw
    # the rest away. To do this, we need to install `gettext`
    # then move `envsubst` out of the way so `gettext` can
    # be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
       scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
         | tr ',' '\n' \
         | sort -u \
         | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps \
    && apk del .build-deps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    && mv /tmp/libstdc++.so* /usr/lib/ \
    \
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx.vh.default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
