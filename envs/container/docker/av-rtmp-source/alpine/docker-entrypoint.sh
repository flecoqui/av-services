#!/bin/sh

while [ : ]
do
echo "ffmpeg -v verbose  -re -stream_loop -1 -i /camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb   -f flv $RTMP_URL"
ffmpeg -v verbose  -re -stream_loop -1 -i /camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb   -f flv $RTMP_URL
sleep 5
done

