ARG NGINX_VERSION=1.18.0
ARG NGINX_RTMP_VERSION=1.2.1


##############################
# Build the NGINX-build image.
FROM ubuntu:20.04 as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

# Build dependencies.
RUN apt-get -y update  \
  && apt-get -y install  build-essential curl g++ \
  gcc \
  make \
  libpcre3 libpcre3-dev libssl-dev zlib1g-dev \
  ca-certificates \
  curl \
  libc-dev \
  musl-dev \
  openssl \
  pkgconf wget



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

RUN cd /tmp && \
  wget https://github.com/aler9/rtsp-simple-server/releases/download/v0.12.2/rtsp-simple-server_v0.12.2_linux_amd64.tar.gz && \
  tar xvfz rtsp-simple-server_v0.12.2_linux_amd64.tar.gz && \
  cp ./rtsp-simple-server /usr/local/bin/ && \
  cp ./rtsp-simple-server.yml /usr/local/bin/ 

# Cleanup.
RUN rm -rf /var/cache/* /tmp/*

##########################
# Build the release image.
FROM ubuntu:20.04

ENV COMPANYNAME Company
ENV HOSTNAME localhost
ENV PORT_HLS 8080
ENV PORT_HTTP 80
ENV PORT_SSL 443
ENV PORT_RTMP 1935
ENV PORT_RTSP 8554


RUN apt-get -y update  \
  && apt-get -y install \
  ca-certificates \
  gettext \
  openssl \
  lame \
  curl \
  rtmpdump 



# Create directories.
RUN  mkdir /testav \
&& mkdir /testav/log \ 
&& chmod 0777 /testav/log \
&& mkdir /testav/config 

# Copy binairies
COPY --from=build-nginx /usr/local/nginx /usr/local/nginx
COPY --from=build-nginx /etc/nginx /etc/nginx
COPY --from=build-nginx /usr/local/bin/rtsp-simple-server /usr/local/bin/rtsp-simple-server 
COPY --from=build-nginx /usr/local/bin/rtsp-simple-server.yml /usr/local/bin/rtsp-simple-server.yml 

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"

COPY docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh 

EXPOSE $PORT_RTMP/tcp $PORT_HLS/tcp $PORT_HTTP/tcp $PORT_SSL/tcp $PORT_RTSP/tcp

CMD ./docker-entrypoint.sh
