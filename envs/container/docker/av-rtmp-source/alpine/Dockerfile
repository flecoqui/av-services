FROM alpine:3.12 
ENV RTMP_URL rtmp://localhost:1935/live/stream
# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv

COPY docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh
# ffmpeg container
RUN apk add ffmpeg 
CMD /docker-entrypoint.sh

