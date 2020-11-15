# build image
docker build -t flecoqui/av-nginx-rtmp-alpine .
# run image
docker run  flecoqui/av-nginx-rtmp-alpine
#sample convert incoming rtsp stream into rtmp
docker run flecoqui/av-nginx-rtmp-alpine
