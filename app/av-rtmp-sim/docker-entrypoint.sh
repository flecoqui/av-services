#!/bin/sh
<<<<<<< HEAD
set -e

ffmpeg -v verbose  -re -stream_loop -1 -i camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb   -f flv $RTMP_URL

=======

while [ : ]
do
ffmpeg -v verbose  -re -stream_loop -1 -i camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb   -f flv $RTMP_URL
sleep 5
done
>>>>>>> af5defaf45abbfbc07ce36e54f4a9ee265066bad

