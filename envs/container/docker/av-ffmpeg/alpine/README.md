# av-ffmpeg alpine

## Overview
This av-service av-ffmpeg for alpine is a container running ffmpeg.
By default this container embeds a MKV file which could be used by ffmpeg.
Using this MKV file, ffmpeg could encod this file into a new video file, ffmpeg could also stream this file using a specific protocol.

## Using av-ffmpeg alpine
It's recommended to use and manage the av-ffmpeg alpine service with the avtool.sh command line tool.

### Pre-requisites
As avtool.sh is a Linux bash file, you could run this tool from a machine or virtual machine running Ubuntu 20.04 LTS.

1. Ensure git is installed running the following command

```bash
    sudo apt-get install git
```

2. Clone the av-services repository on your machine

```bash
    mkdir $HOME/git
    cd $HOME/git
    git clone https://github.com/flecoqui/av-services.git
    cd av-services/envs/container/docker/av-ffmpeg/alpine 
```
3. Run avtool.sh -a install to install docker 

```bash
    avtool.sh -a install
```


### Installing the host machine

### Deploying/Undeploying av-ffmpeg alpine service

### Starting/Stopping av-ffmpeg alpine service

### Testing av-ffmpeg alpine service

# Building the image
You can build the image using docker build command line.
For instance:

            docker build -t av-services/av-ffmpeg-alpine .


# Running the image
You can run the image using docker run command line.
For instance:

            docker run  av-services/av-ffmpeg-alpine


For instance sample to convert incoming rtsp stream into rtmp:

            docker run flecoqui/av-ffmpeg-alpine -v verbose -i rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov -strict -2 -c:a aac -b:a 192k -ar 44100 -r 30 -g 60 -keyint_min 60 -b:v 2000000 -c:v libx264 -preset veryfast  -profile main -level 3.0 -pix_fmt yuv420p -bufsize 1800k -maxrate 400k    -f flv rtmp://172.17.0.2:1935/live/stream


