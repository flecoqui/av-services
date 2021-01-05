# av-rtmp-sim alpine
Live RTMP stream simulator.
This container use the file camera-300s.mkv to emulate Live RTMP stream.

This container will run a RTMP ingress server.

# Building the image
You can build the image using docker build command line.
For instance:

            docker build -t flecoqui/av-rtmp-sim-alpine .


# Environment variables:

- RTMP_URL: the RTMP url to stream live RTMP. Default value: rtmp://localhost:1935/live/stream

# Running the image
You can run the image using docker run command line.
For instance:

            docker run -it -e RTMP_URL=rtmp://192.168.0.1:1935/live/stream flecoqui/av-rtmp-sim-alpine 


# Using docker-compose
You can use docker-compose to start the container:

            docker-compose up -d

stop the container:

            docker-compose down


