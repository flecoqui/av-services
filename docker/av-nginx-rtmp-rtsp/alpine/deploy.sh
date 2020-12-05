# build image
docker build -t flecoqui/av-nginx-rtmp-rtsp-alpine .
# run image
docker run -it  flecoqui/av-nginx-rtmp-alpine 
docker run -it -p 80:80/tcp  -p 8080:8080/tcp -p 443:443/tcp    -p 1935:1935/tcp -p 5443:443/tcp flecoqui/av-nginx-rtmp-rtsp-alpine 
docker run -it -p 80:80/tcp  -p 8080:8080/tcp    -p 1935:1935/tcp -p 443:443/tcp -p 8554:8554/tcp -e HOSTNAME=mymachine.mydomain.com -d flecoqui/av-nginx-rtmp-rtsp-alpine

docker-compose up -d
docker-compose down
docker push  flecoqui/av-nginx-rtmp-alpine 
#sample convert incoming rtsp stream into rtmp
docker run flecoqui/av-nginx-rtmp-alpine
ffmpeg.exe -v verbose -f dshow -i video="Integrated Webcam":audio="Microphone (Realtek(R) Audio)"  -video_size 1280x720 -strict -2 -c:a aac -b:a 192k -ar 44100 -r 30 -g 60 -keyint_min 60 -b:v 2000000 -c:v libx264 -preset veryfast  -profile main -level 3.0 -pix_fmt yuv420p -bufsize 1800k -maxrate 400k    -f flv rtmp://localhost:1935/live/stream

curl https://mymachine.mydomain.com/player.html --verbose -vk

