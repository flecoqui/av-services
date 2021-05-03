ARG AV_HOSTNAME=localhost
ARG AV_PORT_RTMP=1935
ARG AV_PORT_RTSP=8554

##############################
# Build the RTSP-build image.
FROM ubuntu:20.04 as build-rtsp

# Build dependencies.
RUN apt-get -y update  \
  && apt-get -y install wget


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

ARG AV_HOSTNAME
ARG AV_PORT_RTMP
ARG AV_PORT_RTSP

ENV HOSTNAME $AV_HOSTNAME
ENV PORT_RTMP $AV_PORT_RTMP
ENV PORT_RTSP $AV_PORT_RTSP


RUN apt-get -y update  \
  && apt-get -y install ffmpeg

# Create directories.
RUN  mkdir /testav \
&& mkdir /testav/log \ 
&& chmod 0777 /testav/log \
&& mkdir /testav/config 

# Copy binairies
COPY --from=build-rtsp /usr/local/bin/rtsp-simple-server / 
COPY --from=build-rtsp /usr/local/bin/rtsp-simple-server.yml /
RUN sed -i 's/rtmpDisable: no/rtmpDisable: yes/g'  /rtsp-simple-server.yml 

COPY docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh 

EXPOSE $PORT_RTMP/tcp  $PORT_RTSP/tcp

CMD /docker-entrypoint.sh
