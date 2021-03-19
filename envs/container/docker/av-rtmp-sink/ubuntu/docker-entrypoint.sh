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
    <source src="http://'$HOSTNAME:$PORT_HLS'/live/stream.m3u8" type="application/x-mpegURL" />
 </video>
 <script>
    var player = videojs("#player");
 </script>
 </body>
 <p>HOSTNAME: '$HOSTNAME'</p>
 <p>PORT_HTTP: '$PORT_HTTP' - URL: 'http://$HOSTNAME:$PORT_HTTP/player.html'</p>
 <p>PORT_SSL: '$PORT_SSL' - URL: 'https://$HOSTNAME:$PORT_SSL/player.html'</p>
 <p>PORT_RTMP: '$PORT_RTMP' - URL: 'rtmp://$HOSTNAME:$PORT_RTMP/live/stream'</p> 
 <p>PORT_HLS: '$PORT_HLS' - URL: 'http://$HOSTNAME:$PORT_HLS/live/stream.m3u8'</p>
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
        location /live {
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
            hls_path /mnt/live/;
            hls_fragment 3;
            hls_playlist_length 60;
        }
    }
}" > /etc/nginx/nginx.conf
/usr/local/nginx/sbin/nginx -g "daemon off;" 
#exec /usr/local/nginx/sbin/nginx  
#exec /bin/sh



