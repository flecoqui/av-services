#!/bin/sh
set -e

ffmpeg -v verbose  -re -stream_loop -1 -i camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb   -f flv $RTMP_URL


