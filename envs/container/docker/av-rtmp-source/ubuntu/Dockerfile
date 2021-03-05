FROM ubuntu:20.04 

ENV RTMP_URL rtmp://localhost:1935/live/stream

# ffmpeg container
RUN apt-get -y update \
 && apt-get -y install ffmpeg wget
# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv
 # copy entrypoint bash file
COPY docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh

CMD /docker-entrypoint.sh

