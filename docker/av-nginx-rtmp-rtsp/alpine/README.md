# av-nginx-rtmp-rtsp alpine
RTMP ingress adaptor container supporting RTMP egress, HLS egress.

This container will run a RTMP ingress server.

# Building the image
You can build the image using docker build command line.
For instance:

            docker build -t flecoqui/av-nginx-rtmp-rtsp-alpine .


# Running the image
You can run the image using docker run command line.
For instance:

            docker run -it  flecoqui/av-nginx-rtmp-rtsp-alpine 
            docker run -it -p 80:80/tcp  -p 8080:8080/tcp -p 443:443/tcp    -p 1935:1935/tcp -p 5443:443/tcp flecoqui/av-nginx-rtmp-rtsp-alpine 


# Environment variables:

- HOSTNAME: the host name of the container. Default value: localhost
- PORT_HLS: the HLS TCP port. Default value: 8080
- PORT_HTTP: the HTTP port. Default value: 80
- PORT_SSL: the SSL port. Default value: 443
- PORT_RTMP: the RTMP port. Default value: 1935
- PORT_RTSP: the RTSP port. Default value: 8554

For instance, the command line below set the HOSTNAME variable:

            docker run -it -p 80:80/tcp  -p 8080:8080/tcp    -p 1935:1935/tcp -p 443:443/tcp -p 8554:8554/tcp -e HOSTNAME=127.0.0.1  -d flecoqui/av-nginx-rtmp-rtsp-alpine

# Using docker-compose
You can use docker-compose to start the container:

            docker-compose up -d

stop the container:

            docker-compose down


# Testing the container with ffmpeg
Run the container locally with docker:

            docker run flecoqui/av-nginx-rtmp-rtsp-alpine

With ffmpeg stream the video associated with your webcam towards the RTMP server:

            ffmpeg.exe -v verbose -f dshow -i video="Integrated Webcam":audio="Microphone (Realtek(R) Audio)"  -video_size 1280x720 -strict -2 -c:a aac -b:a 192k -ar 44100 -r 30 -g 60 -keyint_min 60 -b:v 2000000 -c:v libx264 -preset veryfast  -profile main -level 3.0 -pix_fmt yuv420p -bufsize 1800k -maxrate 400k    -f flv rtmp://localhost:1935/live/stream

Using av-rtmp-sim-alpine container to emulate live stream from MKV file. The hostname in the rtmp url needs to be the local ip address associated with the av-nginx-rtmp-rtsp-alpine container, you can get this address with the 'docker inspect' command. For instance:


                docker run -it -d -e RTMP_URL=rtmp://172.17.0.2:1935/live/stream flecoqui/av-rtmp-sim-alpine


Open the url https://mymachine.mydomain.com/player.html to play the HLS stream:

        curl https://mymachine.mydomain.com/player.html --verbose -vk


# Urls

RTMP url:
rtmp://$HOSTNAME:$PORT_RTMP/live/stream 

RTSP url:
rtsp://$HOSTNAME:$PORT_RTSP/rtsp/stream   

HLS url:
http://$HOSTNAME:$PORT_HLS/hls/stream.m3u8

