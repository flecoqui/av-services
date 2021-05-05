# av-rtmp-rtsp-light-sink alpine container running in IoT Edge device 

## Overview
This av-service av-rtmp-rtsp-light-sink for alpine is a container running nginx RTMP server which convert an incoming RTMP stream into RTSP stream. 
This av-service is used in IoT Edge device with Live Video Analytics to convert an incoming RTMP stream into a RTSP stream to feed Live Video Analytics AI components.
When you will deploy this component with avtool.sh, it will deploy a complete LVA infrastructure with IoT Edge Hub, Azure Container Registry, Azure Media Services (so far mandatory to deploy Live Video Analytics), Azure Storage, Azure Virtual Machine acting as IoT Edge device and running docker.
When you will start, stop this component with avtool.sh, it will start, stop the rtmpsource container in the IoT Edge device.
When you will test this component with avtool.sh, it will test automatically the following scenarios:
- RTMP to RTSP adaptor
- LVA Motion Detection

At least, when the rtmpsource will be fed with a Live RTMP stream, you could consume the following streams with VLC:  
RTSP URL: rtsp://\<IoTEdgeVMName\>.\<REGION\>.cloudapp.azure.com:8554/rtsp/stream  
SSH command: ssh \<VMAdmin\>@\<IoTEdgeVMName\>.\<REGION\>.cloudapp.azure.com  


## Using av-rtmp-rtsp-light-sink alpine
It's recommended to use and manage the av-rtmp-rtsp-light-sink alpine service with the avtool.sh command line tool.

### Installing the pre-requisites on the host machine
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
    cd av-services/envs/container/docker/av-rtmp-rtsp-light-sink/alpine 
```
1. Run avtool.sh -a install to install the pre-requisite ffmpeg, Azure Client, ... 

```bash
    ./avtool.sh -a install
```

### Deploying/Undeploying av-rtmp-rtsp-light-sink alpine service
Once the pre-requisites are installed, you can deploy the Live Analytics infrastructure (IoT Edge Hub, Azure Container Registry, Azure Media Services, Azure Storage, Azure Virtual Machine acting as IoT Edge device and running docker) and build the av-rtmp-rtsp-light-sink alpine container.


1. Run the following command to build and run the container

```bash
    ./avtool.sh -a deploy
```

When you run avtool.sh for the first time, it creates a file called .avtoolconfig to store the av-rtmp-rtsp-light-sink in LVA configuration. By default, the file contains these parameters:

```bash
    AV_RESOURCE_GROUP=av-rtmp-rtsp-lva-rg
    AV_RESOURCE_REGION=eastus2
    AV_IMAGE_NAME=av-rtmp-rtsp-light-sink-alpine
    AV_IMAGE_FOLDER=av-services
    AV_CONTAINER_NAME=av-rtmp-rtsp-light-sink-alpine-container
    AV_EDGE_DEVICE=rtmp-rtsp-lva-device
    AV_PORT_RTMP=1935
    AV_PREFIXNAME=rtmprtsplva
    AV_VMNAME=rtmprtsplvavm
    AV_CONTAINERNAME=avchunks
    AV_LOGIN=avvmadmin
    AV_PASSWORD={YourPassword}
    AV_HOSTNAME=rtmprtsplvavm.eastus2.cloudapp.azure.com
    AV_PORT_RTMP=1935
    AV_PORT_RTSP=8554
    AV_TEMPDIR=
    AV_STORAGENAME=
    AV_SASTOKEN=
    AV_IOTHUB=
    AV_IOTHUB_CONNECTION_STRING=
    AV_DEVICE_CONNECTION_STRING=
    AV_CONTAINER_REGISTRY=
    AV_CONTAINER_REGISTRY_DNS_NAME=
    AV_CONTAINER_REGISTRY_USERNAME=
    AV_CONTAINER_REGISTRY_PASSWORD=
    AV_SUBSCRIPTION_ID=
    AV_AMS_ACCOUNT=
    AV_AAD_TENANT_ID=
    AV_AAD_SERVICE_PRINCIPAL_ID=
    AV_AAD_SERVICE_PRINCIPAL_SECRET=
```

Below further information about the input parameters in the file .avtoolconfig:
It's important before running ./avtool.sh -a deploy to define the following input parameters:
- AV_PREFIXNAME: The name prefix used for all the Azure resources. As the Azure Container Registry name and the virtual machine name depends on this prefix, if a deployment as already used the same prefix, your deployment will fail because of a name conflict in Azure (by default rtmprtsplva)  
- AV_PASSWORD: The password for the Virtual Machine running IoT Edge. 

Below the list of input parameters:

| Variables | Description |
| ---------------------|:-------------|
| AV_RESOURCE_GROUP | The name of the resource group where LVA infrastructure will be deployed (av-rtmp-rtsp-lva-rg by default) |
| AV_RESOURCE_REGION | The Azure region where LVA infrastructure will be deployed (eastus2 by default)  |
| AV_SERVICE | The name of the service  (by default av-rtmp-rtsp-light-sink)  |
| AV_FLAVOR | The flavor of this service   (by default alpine)  |
| AV_IMAGE_NAME | The suffix of the image name  (by default ${AV_SERVICE}-${AV_FLAVOR}) |
| AV_IMAGE_FOLDER | The image folder, the image name will be ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}  |
| AV_CONTAINER_NAME | The name of the container (by default av-rtmp-rtsp-light-sink-alpine-container)  |
| AV_EDGE_DEVICE | The name of the Edge device (by default rtmp-rtsp-lva-device)  |
| AV_PREFIXNAME | The name prefix used for all the Azure resources (by default rtmprtsplva)  |
| AV_VMNAME | The name of the virtual machien running IoT Edge  (by default "$AV_PREFIXNAME"vm)  |
| AV_HOSTNAME | The host name of the container. Default value: "$AV_VMNAME"."$AV_RESOURCE_REGION".cloudapp.azure.com  |
| AV_CONTAINERNAME | The name of the container in Azure Storage Account where the video and audio chunks will be stored (by default avchunks)  |
| AV_LOGIN | The login for the Virtual Machine running IoT Edge. Default value: avvmadmin  |
| AV_PASSWORD | The password for the Virtual Machine running IoT Edge. Default value:   |
| AV_HOSTNAME | The host name of the container. Default value: localhost  |
| AV_PORT_RTMP | The RTMP port. Default value: 1935  |
| AV_PORT_RTSP | The RTSP port. Default value: 8554  |
| AV_TEMPDIR | The directory on the host machine used to store MKV and MP4 files for the tests |


When the service is running and fed with a RTMP stream, the following urls could be used for the tests:

RTMP URL: rtmp://\<IoTEdgeVMName\>.\<REGION\>.cloudapp.azure.com:1935/live/stream  
RTSP URL: rtsp://\<IoTEdgeVMName\>.\<REGION\>.cloudapp.azure.com:8554/rtsp/stream  
SSH command: ssh \<VMAdmin\>@\<IoTEdgeVMName\>.\<REGION\>.cloudapp.azure.com  


Below the output parameters:

| Variables | Description |
| ---------------------|:-------------|
| AV_RESOURCE_GROUP | The name of the resource group where LVA infrastructure will be deployed (av-rtmp-rtsp-lva-rg by default) |
| AV_STORAGENAME |The name of the sotrage account created|
| AV_SASTOKEN | The Shared Access Signature for the storage account|
| AV_IOTHUB | The IoT Hub name |
| AV_IOTHUB_CONNECTION_STRING |The IoT Hub connection string |
| AV_DEVICE_CONNECTION_STRING |The IoT Device connection string|
| AV_CONTAINER_REGISTRY |The Azure Container Registry name |
| AV_CONTAINER_REGISTRY_DNS_NAME |The Azure Container Registry login server name |
| AV_CONTAINER_REGISTRY_USERNAME |The Azure Container Registry user name|
| AV_CONTAINER_REGISTRY_PASSWORD |The Azure Container Registry password|
| AV_SUBSCRIPTION_ID |The Azure Subscription ID |
| AV_AMS_ACCOUNT |The Azure Media Service Account (not used but mandatory for LVA)|
| AV_AAD_TENANT_ID |The Azure AD Tenant ID used for the authentication with Azure Media Services|
| AV_AAD_SERVICE_PRINCIPAL_ID |The Azure AD Service Principal ID used for the authentication with Azure Media Services|
| AV_AAD_SERVICE_PRINCIPAL_SECRET |The Azure AD Service Principal Secret used for the authentication with Azure Media Services|

### Starting/Stopping av-rtmp-rtsp-light-sink alpine service
Once the rtmpsource service is built and deployed you can start and stop the container .


1. Run the following command to start the container in IoT Edge Device

```bash
    ./avtool.sh -a start
```

1. If the container is still running, you can run the following command to stop the container in IoT Edge Device

```bash
    ./avtool.sh -a stop
```

3. If the container is still running, you can run the following command to get the status of the container in IoT Edge Device

```bash
    ./avtool.sh -a status
```

### Testing av-rtmp-rtsp-light-sink alpine service in IoT Edge Device
Once the image is built you can test if the container is fully functionning.

1. Run the following command to test the container

```bash
    ./avtool.sh -a test
```

For this container, the test feature will check if the output MP4 files have been created in the temporary folder from output RTSP url.

By default for the tests, it will test automatically the following scenarios:
- RTMP to RTSP adaptor
- LVA Motion Detection

For this test, we use an incoming Live RTMP stream created from a MKV file using the following ffmpeg command:

```bash
    ffmpeg -hide_banner -loglevel error  -re -stream_loop -1 -i "${AV_TEMPDIR}"/camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb   -f flv rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/live/stream
```


If on the host machine a Webcam is installed, you can use this webcam to generate the incoming RTMP stream using the following ffmpeg command:

```bash
    ffmpeg.exe -v verbose -f dshow -i video="Integrated Webcam":audio="Microphone (Realtek(R) Audio)"  -video_size 1280x720 -strict -2 -c:a aac -b:a 192k -ar 44100 -r 30 -g 60 -keyint_min 60 -b:v 2000000 -c:v libx264 -preset veryfast  -profile main -level 3.0 -pix_fmt yuv420p -bufsize 1800k -maxrate 400k    -f flv rtmp://localhost:1935/live/stream
```


