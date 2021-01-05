# av-ffmpeg ubuntu
FFMPEG Ubuntu container.

This container will run the FFMPEG command with the docker run arguments.

# Building the image
You can build the image using docker build command line.
For instance:

            docker build -t flecoqui/av-ffmpeg-ubuntu .


# Running the image
You can run the image using docker run command line.
For instance:

            docker run  flecoqui/av-ffmpeg-ubuntu


For instance sample to convert incoming rtsp stream into rtmp:

            docker run flecoqui/av-ffmpeg-ubuntu -v verbose -i rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov -strict -2 -c:a aac -b:a 192k -ar 44100 -r 30 -g 60 -keyint_min 60 -b:v 2000000 -c:v libx264 -preset veryfast  -profile main -level 3.0 -pix_fmt yuv420p -bufsize 1800k -maxrate 400k    -f flv rtmp://172.17.0.2:1935/live/stream


