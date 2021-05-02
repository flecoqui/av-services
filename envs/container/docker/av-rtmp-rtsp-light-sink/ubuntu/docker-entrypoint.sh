#!/bin/sh
#set -e

cat <<EOF > /ffmpegrtmprtsploop.sh
while [ : ]
do
ffmpeg -f flv -listen 1  -i rtmp://0.0.0.0:$PORT_RTMP/live/stream   -c copy  -f rtsp rtsp://127.0.0.1:$PORT_RTSP/live/stream
sleep 1
done
EOF

chmod +x   /ffmpegrtmprtsploop.sh


# Start the rtsp process
export RTSP_PROTOCOLS=tcp 
export RTSP_RTSPPORT=$PORT_RTSP
/rtsp-simple-server &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start rtsp: $status"
  exit $status
fi

# Start the ffmpeg rtmp rtsp process
/ffmpegrtmprtsploop.sh &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start  ffmpeg rtmp rtsp : $status"
  exit $status
fi


# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
  ps aux |grep rtsp-simple-server |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep ffmpeg |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    if [[ $PROCESS_1_STATUS -ne 0 ]] ; then echo "rtsp-simple-server process stopped"; fi
    if [[ $PROCESS_2_STATUS -ne 0 ]] ; then echo "ffmpeg process stopped"; fi
    echo "One of the processes has already exited. Stopping the container"
    exit 1
  fi
done


