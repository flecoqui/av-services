# av-ffmpeg ubuntu

## Overview
This av-service av-ffmpeg for ubuntu is a container running ffmpeg.
By default this container embeds a MKV file which could be used by ffmpeg.
Using this MKV file, ffmpeg could encod this file into a new video file, ffmpeg could also stream this file using a specific protocol.

## Using av-ffmpeg ubuntu
It's recommended to use and manage the av-ffmpeg ubuntu service with the avtool.sh command line tool.

### Installing the pre-requisites on the host machine
As avtool.sh is a Linux bash file, you could run this tool from a machine or virtual machine running Ubuntu 18.04 LTS.

1. Ensure git is installed running the following command

```bash
    sudo apt-get install git
```

2. Clone the av-services repository on your machine

```bash
    mkdir $HOME/git
    cd $HOME/git
    git clone https://github.com/flecoqui/av-services.git
    cd av-services/envs/container/docker/av-ffmpeg/ubuntu 
```
3. Run avtool.sh -a install to install docker 

```bash
    ./avtool.sh -a install
```

### Deploying/Undeploying av-ffmpeg ubuntu service
Once the pre-requisites are installed, you can build the av-ffmpeg ubuntu container.


1. Run the following command to build and run the container

```bash
    ./avtool.sh -a deploy
```

When you run avtool.sh for the first time, it creates a file called .avtoolconfig to store the av-ffmpeg configuration. By default, the file contains these parameters:

```bash
    AV_IMAGE_NAME=av-ffmpeg-ubuntu
    AV_IMAGE_FOLDER=av-services
    AV_CONTAINER_NAME=av-ffmpeg-ubuntu-container
    AV_VOLUME=data1
    AV_FFMPEG_COMMAND="ffmpeg -y -nostats -loglevel 0  -i ./camera-300s.mkv -codec copy /data1/camera-300s.mp4"
    AV_TEMPDIR=/tmp/tmp.TblgL0Cm4d
```

Below further information about the parameters in the file .avtoolconfig:

| Variables | Description |
| ---------------------|:-------------|
| AV_IMAGE_NAME | The suffix of the image name   |
| AV_IMAGE_FOLDER | The image folder, the image name will be ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}  |
| AV_CONTAINER_NAME | The name of the container  |
| AV_VOLUME | The name of the voluume mounted in the container to exchange files with the host machine  |
| AV_FFMPEG_COMMAND | The ffmpeg command, the defualt command encod the local MKV file into a MP4 file stored in the mounted volume  |
| AV_TEMPDIR | The directory on the host machine used to mount a volume in the container |



### Starting/Stopping av-ffmpeg ubuntu service
Once the image is built you can start and stop the container .


1. Run the following command to start the container

```bash
    ./avtool.sh -a start
```
By default the container will run the following command to encod the MKV file:


```bash
    ffmpeg -y -nostats -loglevel 0  -i ./camera-300s.mkv -codec copy /${AV_VOLUME}/camera-300s.mp4
```


2. If the container is still running, you can run the following command to stop the container

```bash
    ./avtool.sh -a stop
```

3. If the container is still running, you can run the following command to get the status of the container

```bash
    ./avtool.sh -a status
```

### Testing av-ffmpeg ubuntu service
Once the image is built you can test if the container is fully functionning.

1. Run the following command to test the container

```bash
    ./avtool.sh -a test
```

For this container, the test feature will check if the output MP4 file has been created in the mounted volume.



