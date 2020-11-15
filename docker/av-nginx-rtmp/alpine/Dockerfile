ARG NGINX_VERSION=1.18.0
ARG NGINX_RTMP_VERSION=1.2.1


##############################
# Build the NGINX-build image.
FROM alpine:3.12 as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

# Build dependencies.
RUN apk add --update \
  build-base \
  ca-certificates \
  curl \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
  musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-http_ssl_module \
  --with-debug \
  --with-cc-opt="-Wimplicit-fallthrough=0" && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install


# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

##########################
# Build the release image.
FROM alpine:3.12

ENV HOSTNAME 127.0.0.1
ENV PORT_HLS 8080
ENV PORT_HTTP 80
ENV PORT_SSL 443
ENV PORT_RTMP 1935

EXPOSE $PORT_RTMP/tcp $PORT_HLS/tcp $PORT_HTTP/tcp $PORT_SSL/tcp

RUN apk add --update \
  ca-certificates \
  gettext \
  openssl \
  pcre \
  lame \
  libogg \
  curl \
  libass \
  libvpx \
  libvorbis \
  libwebp \
  libtheora \
  opus \
  rtmpdump \
  x264-dev \
  x265-dev


# Create directories.
RUN  mkdir /testav \
&& mkdir /testav/log \ 
&& chmod 0777 /testav/log \
&& mkdir /testav/config \ 
&& mkdir -p /etc/nginx \
&& mkdir -p /etc/nginx/sbin \ 
&& mkdir -p /etc/nginx/conf \ 
&& mkdir -p /etc/nginx/logs \  
&& mkdir -p /etc/nginx/html 

# Copy binairies
COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"

RUN echo '<!DOCTYPE html>\n\
<html lang="en">\n\
<head>\n\
    <meta charset="UTF-8">\n\
    <title>Live Streaming</title>\n\
    <link href="//vjs.zencdn.net/7.8.2/video-js.min.css" rel="stylesheet">\n\
    <script src="//vjs.zencdn.net/7.8.2/video.min.js"></script>\n\
    <script src="https://cdn.jsdelivr.net/npm/videojs-contrib-eme@3.7.0/dist/videojs-contrib-eme.min.js"></script>\n\
 </head>\n\
 <body>\n\
<video id="player" class="video-js vjs-default-skin" height="360" width="640" controls preload="none">\n\
    <source src="http://'$HOSTNAME:$PORT_HLS'/hls/stream.m3u8" type="application/x-mpegURL" />\n\
 </video>\n\
 <script>\n\
    var player = videojs("#player");\n\
 </script>\n\
 </body>\n\
 <p>HOSTNAME: '$HOSTNAME'</p>\n\
 <p>PORT_HLS: '$PORT_HLS'</p>\n\
 <p>PORT_HTML: '$PORT_HTTP'</p>\n\
 <p>PORT_RTMP: '$PORT_RTMP'</p>\n\
 </html>\n' > /usr/local/nginx/html/player.html

RUN echo "worker_processes  1;\n\
error_log  /testav/log/nginxerror.log debug;\n\
events {\n\
    worker_connections  1024;\n\
 }\n\
http {\n\
    include       mime.types;\n\
    default_type  application/octet-stream;\n\
    keepalive_timeout  65;\n\
    tcp_nopush on;\n\
    directio 512;\n\
    server {\n\
        sendfile        on;\n\
        listen       "$PORT_HTTP";\n\
        server_name  localhost;\n\
        location /stat {\n\
            rtmp_stat all;\n\
            rtmp_stat_stylesheet stat.xsl;\n\
        }\n\
        location /stat.xsl {\n\
            root /usr/build/nginx-rtmp-module;\n\
        }\n\
        location /control {\n\
            rtmp_control all;\n\
        }\n\
        error_page   500 502 503 504  /50x.html;\n\
        location = /50x.html {\n\
            root   html;\n\
        }\n\
    }\n\
    server {\n\
        sendfile        off;\n\
        listen "$PORT_HLS";\n\
        location /hls {\n\
            add_header 'Cache-Control' 'no-cache';\n\
            add_header 'Access-Control-Allow-Origin' '*' always;\n\
            add_header 'Access-Control-Expose-Headers' 'Content-Length';\n\
            if (\$request_method = 'OPTIONS') {\n\
                add_header 'Access-Control-Allow-Origin' '*';\n\
                add_header 'Access-Control-Max-Age' 1728000;\n\
                add_header 'Content-Type' 'text/plain charset=UTF-8';\n\
                add_header 'Content-Length' 0;\n\
                return 204;\n\
            }\n\
            types {\n\
                application/dash+xml mpd;\n\
                application/vnd.apple.mpegurl m3u8;\n\
                video/mp2t ts;\n\
            }\n\
            root /mnt/;\n\
        }\n\
    }\n\
 }\n\
rtmp {\n\
    server {\n\
        listen "$PORT_RTMP";\n\
        ping 30s;\n\
        notify_method get;\n\
        buflen 5s;\n\
        chunk_size 4000;\n\
        application live {\n\
            live on;\n\
            interleave on;\n\
            hls on;\n\
            hls_path /mnt/hls/;\n\
            hls_fragment 3;\n\
            hls_playlist_length 60;\n\
        }\n\
    }\n\
}\n" > /etc/nginx/nginx.conf


COPY docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh 
ENTRYPOINT ["/docker-entrypoint.sh"]
