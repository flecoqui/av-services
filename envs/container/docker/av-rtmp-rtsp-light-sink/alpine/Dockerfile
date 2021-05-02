ARG AV_HOSTNAME=localhost
ARG AV_PORT_RTMP=1935
ARG AV_PORT_RTSP=8554
##############################
FROM aler9/rtsp-simple-server AS server
##########################
# Build the release image.
FROM alpine:3.12
ARG AV_HOSTNAME
ARG AV_PORT_RTMP
ARG AV_PORT_RTSP

ENV HOSTNAME $AV_HOSTNAME
ENV PORT_RTMP $AV_PORT_RTMP
ENV PORT_RTSP $AV_PORT_RTSP

# Create directories.
RUN  mkdir /testav \
&& mkdir /testav/log \ 
&& chmod 0777 /testav/log \
&& mkdir /testav/config 

# install ffmpeg
RUN apk add ffmpeg 
# install rtsp-simple-server
COPY --from=server /rtsp-simple-server /rtsp-simple-server
COPY --from=server /rtsp-simple-server.yml /rtsp-simple-server.yml
# disable rtmp ingestion for rtsp-simple-server
RUN sed -i 's/rtmpDisable: no/rtmpDisable: yes/g'  ./rtsp-simple-server.yml

COPY ./docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh 

EXPOSE $PORT_RTMP/tcp  $PORT_RTSP/tcp

CMD /docker-entrypoint.sh
