ARG NGINX_VERSION=1.18.0
ARG NGINX_RTMP_VERSION=1.2.1
ARG AV_COMPANYNAME=Company
ARG AV_HOSTNAME=localhost
ARG AV_PORT_HLS=8080
ARG AV_PORT_HTTP=80
ARG AV_PORT_SSL=443
ARG AV_PORT_RTMP=1935
ARG AV_PORT_RTSP=8554

##############################
# Build the NGINX-build image.

FROM aler9/rtsp-simple-server AS server
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
  --with-http_v2_module \
  --with-debug \
  --with-cc-opt="-Wimplicit-fallthrough=0" && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install


# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

##########################
# Build the release image.
FROM alpine:3.12
ARG AV_COMPANYNAME
ARG AV_HOSTNAME
ARG AV_PORT_HLS
ARG AV_PORT_HTTP
ARG AV_PORT_SSL
ARG AV_PORT_RTMP
ARG AV_PORT_RTSP

ENV COMPANYNAME $AV_COMPANYNAME
ENV HOSTNAME $AV_HOSTNAME
ENV PORT_HLS $AV_PORT_HLS
ENV PORT_HTTP $AV_PORT_HTTP
ENV PORT_SSL $AV_PORT_SSL
ENV PORT_RTMP $AV_PORT_RTMP
ENV PORT_RTSP $AV_PORT_RTSP

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
&& mkdir /testav/config 

# Copy binairies
COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx

# install openssl used to create ssl certificates
RUN apk add openssl;
# install ffmpeg
RUN apk add ffmpeg 
# install rtsp-simple-server
COPY --from=server /rtsp-simple-server /rtsp-simple-server
COPY --from=server /rtsp-simple-server.yml /rtsp-simple-server.yml
# disable rtmp ingestion for rtsp-simple-server
RUN sed -i 's/rtmpDisable: no/rtmpDisable: yes/g'  ./rtsp-simple-server.yml

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"

COPY ./docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh 

EXPOSE $PORT_RTMP/tcp $PORT_HLS/tcp $PORT_HTTP/tcp $PORT_SSL/tcp $PORT_RTSP/tcp

CMD /docker-entrypoint.sh
