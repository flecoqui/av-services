#!/bin/sh
set -e

openssl req -x509 -nodes -days 365 -subj "/C=CA/ST=QC/O=$COMPANYNAME, Inc./CN=$HOSTNAME" -addext "subjectAltName=DNS:$HOSTNAME" -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt;
echo '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Live Streaming</title>
    <link href="//vjs.zencdn.net/7.8.2/video-js.min.css" rel="stylesheet">
    <script src="//vjs.zencdn.net/7.8.2/video.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/videojs-contrib-eme@3.7.0/dist/videojs-contrib-eme.min.js"></script>
 </head>
 <body>
<video id="player" class="video-js vjs-default-skin" height="360" width="640" controls preload="none">
    <source src="http://'$HOSTNAME:$PORT_HLS'/hls/stream.m3u8" type="application/x-mpegURL" />
 </video>
 <script>
    var player = videojs("#player");
 </script>
 </body>
 <p>HOSTNAME: '$HOSTNAME'</p>
 <p>PORT_HLS: '$PORT_HLS'</p>
 <p>PORT_HTTP: '$PORT_HTTP'</p> 
 <p>PORT_SSL: '$PORT_SSL'</p>
 <p>PORT_RTMP: '$PORT_RTMP'</p>
 </html>' > /usr/local/nginx/html/player.html

echo "worker_processes  1;
error_log  /testav/log/nginxerror.log debug;
events {
    worker_connections  1024;
 }
http {
    include       mime.types;
    default_type  application/octet-stream;
    keepalive_timeout  65;
    tcp_nopush on;
    directio 512;
    server {
        sendfile        on;
        listen       "$PORT_HTTP" default_server;
        listen [::]:$PORT_HTTP default_server;
        server_name  $HOSTNAME;
        listen "$PORT_SSL" ssl default_server;
        listen [::]:$PORT_SSL ssl http2 default_server;
        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;

        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }
        location /stat.xsl {
            root /usr/build/nginx-rtmp-module;
        }
        location /control {
            rtmp_control all;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
    server {
        sendfile        off;
        listen "$PORT_HLS";
        location /hls {
            add_header 'Cache-Control' 'no-cache';
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length';
            if (\$request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                add_header 'Content-Length' 0;
                return 204;
            }
            types {
                application/dash+xml mpd;
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            root /mnt/;
        }
    }
 }
rtmp {
    server {
        listen "$PORT_RTMP";
        ping 30s;
        notify_method get;
        buflen 5s;
        chunk_size 4000;
        application live {
            live on;
            interleave on;
            hls on;
            hls_path /mnt/hls/;
            hls_fragment 3;
            hls_playlist_length 60;
        }
    }
}" > /etc/nginx/nginx.conf

# Start the nginx process
/usr/local/nginx/sbin/nginx -g "daemon off;" & 
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start nginx: $status"
  exit $status
fi

# Start the rtsp process
/rtsp-simple-server &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start rtsp: $status"
  exit $status
fi

# Start the ffmpeg process
#ffmpeg  -i rtmp://127.0.0.1:1935/live/stream  -framerate 25 -video_size 640x480  -pix_fmt yuv420p -bsf:v h264_mp4toannexb -profile:v baseline -level:v 3.2 -c:v libx264 -x264-params keyint=120:scenecut=0 -c:a aac -b:a 128k -ar 44100 -f rtsp -muxdelay 0.1 rtsp://127.0.0.1:8554/test 
ffmpeg  -i rtmp://127.0.0.1:1935/live/stream  -f rtsp  rtsp://127.0.0.1:8554/test &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start rtsp: $status"
  exit $status
fi



# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
  ps aux |grep nginx |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep rtsp-simple-server |grep -q -v grep
  PROCESS_2_STATUS=$?
  ps aux |grep ffmpeg |grep -q -v grep
  PROCESS_3_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 -o $PROCESS_3_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done


