FROM ubuntu:20.04 

RUN apt-get -y update \
 && apt-get -y install ffmpeg wget

# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv

CMD ["@"]
