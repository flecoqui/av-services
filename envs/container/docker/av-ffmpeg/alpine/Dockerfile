FROM alpine:3.12 
# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv

# install ffmpeg 
RUN apk add ffmpeg 
CMD ["@"]
