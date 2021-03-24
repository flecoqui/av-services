# Deployment of a RTMP Ingester hosted on Azure Virtual Machine using NGINX RTMP, RTSP-SIMPLE-SERVER and FFMPEG with HLS, RTMP and RTSP Playback

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2Fav-services%2Fmaster%2Farm%2F101-vm-light-hls-rtsp%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2Fav-services%2Fmaster%2Farm%2F101-vm-light-hls-rtsp%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template allows you to deploy from Github a Live RTMP Ingester hosted on Azure Virtual Machine. Moreover, beyond the RTMP Ingester, the a service copy the video chunks on an Azure Storage Account. Moreover, this service allow the user to playback:
- the HLS stream generated from the incoming RTMP stream
- the RTMP stream generated from the incoming RTMP stream
- the RTSP stream generated from the incoming RTMP stream
  
As this template doesn't build FFMPEG from the source code, the deployment should take around 20 minutes to build NGINX RTMP.


![](./Docs/1-architecture.png)



# DEPLOYING THE REST API ON AZURE SERVICES

## PRE-REQUISITES
First you need an Azure subscription.
You can subscribe here:  https://azure.microsoft.com/en-us/free/ . </p>
Moreover, we will use Azure CLI v2.0 to deploy the resources in Azure.
You can install Azure CLI on your machine running Linux, MacOS or Windows from here: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest 



## CREATE RESOURCE GROUP:
First you need to create the resource group which will be associated with this deployment. For this step, you can use Azure CLI v1 or v2.

* **Azure CLI 2.0:** az group create an "ResourceGroupName" -l "RegionName"

For instance:

    az group create -n RTMPIngestrg -l eastus2

## DEPLOY THE SERVICES:

### DEPLOY AV-SERVICE ON AZURE VIRTUAL MACHINE:
You can deploy av-service in Azure Virtual Machine using ARM (Azure Resource Manager) Template and Azure CLI.

* **Azure CLI 2.0:** az group deployment create -g "ResourceGroupName" -n "DeploymentName" --template-file "templatefile.json" --parameters @"templatefile.parameter..json"  --verbose -o json

For instance:

    az group deployment create -g RTMPIngestrg -n RTMPIngestdep --template-file azuredeploy.json --parameter @azuredeploy.parameters.json --verbose -o json


When you deploy the service you can define the following parameters:</p>
* **namePrefix:** The name prefix which will be used for all the services deployed with this ARM Template</p>
* **vmAdminUsername:** VM login by default "VMAdmin"</p>
* **vmAdminPassword:** VM password by default "{YourPassword}"</p>
* **vmOS:** supported values "debian","ubuntu","centos","redhat" by default "debian"</p>
* **vmSize:** supported values"Small" (Standard_D2s_v3),"Medium" (Standard_D4s_v3),"Large" (Standard_D8s_v3),"XLarge" (Standard_D16s_v3) by default "Small"</p>
* **containerName:** the name of the container on the Azure Storage where the audio/video chunks will be recorded, by default "rtmpcontainer"</p>
* **expiryDate:** the expiry date of the SAS Token used to access the content stored in the container. by default "2030-01-01T00:00:01Z"</p>


# TEST THE SERVICES:

## TEST THE SERVICES WITH FFMPEG
Once the services are deployed, you can test the RTMP Ingester using ffmpeg on a PC running Windows 10. You can download ffmpeg from here https://www.ffmpeg.org/download.html  
When the resources associated with the current ARM template are deployed, the ffmpegCmd output parameter contains the ffmpeg command line to feed the new virtual machine with a live RTMP stream using the following URL: 
            
            rtmp://vmName.region.cloudapp.azure.com:1935/rtmpPath


For instance using a webcam:

     ffmpeg.exe -v verbose -f dshow -i video="Integrated Webcam":audio="Microphone (Realtek(R) Audio)"  -video_size 1280x720 -strict -2 -c:a aac -b:a 192k -ar 44100 -r 30 -g 60 -keyint_min 60 -b:v 2000000 -c:v libx264 -preset veryfast  -profile main -level 3.0 -pix_fmt yuv420p -bufsize 1800k -maxrate 400k    -f flv rtmp://RTMPIngesterIPAddress:1935/live/stream

For instance using a MKV file:

     ffmpeg.exe -v verbose  -re -stream_loop -1 -i camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://RTMPIngesterIPAddress:1935/live/stream


</p>


![](./Docs/ffmpeg.png)

After one minute of streaming, the audio/video chunks are copied in the Azure Storage Container. You can display the content of this container if you open the output parameter containerUrl with your favorite browser.

![](./Docs/container.png)

You can also playback the HLS stream, if you open with your browser the following urls:
            

            http://vmName.region.cloudapp.azure.com/player.html
            
            http://vmName.region.cloudapp.azure.com:8080/hls/stream.m3u8


![](./Docs/player.png)

You can play with VLC the rtmp stream as well using the following url:

            rtmp://vmName.region.cloudapp.azure.com:1935/live/stream

You can play with VLC the rtsp stream as well using the following url:

            rtsp://vmName.region.cloudapp.azure.com:8554/test



## DELETE THE RESOURCE GROUP:

* **Azure CLI 2.0:**  az group delete -n "ResourceGroupName" "RegionName"

For instance:

    az group delete -n RTMPIngestrg 


# Using avtool.sh to deploy the virtual machine 

## Overview
This av-service is running in an Azure virtual machine.
This template allows you to deploy from Github a Live RTMP Ingester hosted on Azure Virtual Machine. Moreover, beyond the RTMP Ingester, the a service copy the video chunks on an Azure Storage Account. Moreover, this service allow the user to playback:
- the HLS stream generated from the incoming RTMP stream
- the RTMP stream generated from the incoming RTMP stream
- the RTSP stream generated from the incoming RTMP stream

## Using this av-service running in a virtual machine
It's recommended to use and manage this av-service service with the avtool.sh command line tool.

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
    cd av-services/envs/vm/azure-vm/101-vm-light-hls-rtsp
```
3. Run avtool.sh -a install to install Azure CLI and ffmpeg

```bash
    ./avtool.sh -a install
```
### Azure Login 
Before deploying the service, the Azure Login is required. You can run the following command:


1. Run the following command to launch the Azure login

```bash
    ./avtool.sh -a login
```

### Deploying/Undeploying the virtual machine running RTMP to RTSP Adaptor service
Once the pre-requisites are installed and the Azure CLI connected to Azure, you can deploy build the virtual machine running RTMP to RTSP Adaptor service.

When you run avtool.sh for the first time, it creates a file called .avtoolconfig to store the virtual machine configuration. By default, the file contains these parameters:

```bash
    AV_RESOURCE_GROUP=av-rtmp-rtsp-hls-vm-rg
    AV_RESOURCE_REGION=eastus2
    AV_RTMP_PORT=1935
    AV_RTMP_PATH=live/stream
    AV_PREFIXNAME=rtmprtsphls
    AV_VMNAME="$AV_PREFIXNAME"vm
    AV_HOSTNAME="$AV_VMNAME"."$AV_AV_RESOURCE_REGION".cloudapp.azure.com
    AV_CONTAINERNAME=avchunks
    AV_LOGIN=avvmadmin
    AV_PASSWORD={YourPassword}
```

Below further information about the parameters in the file .avtoolconfig:

| Variables | Description |
| ---------------------|:-------------|
| AV_RESOURCE_GROUP | The name of the Azure resource group where the virtual machine is deployed |
| AV_RESOURCE_REGION | The Azure region where the virtual machine is deployed  |
| AV_RTMP_PORT | The rtmp port used for the ingestion   |
| AV_RTMP_PATH | The rtmp path the ingestion  |
| AV_PREFIXNAME | The prefix of the virtual machine name   |
| AV_VMNAME | The virtual machine name   |
| AV_HOSTNAME | The virtual machine dns name   |
| AV_CONTAINERNAME | The container name in the storage account where the video chunks will be stored   |
| AV_LOGIN | The virtual machine administrator login    |
| AV_PASSWORD | The virtual machine administrator password |

1. Edit the file .avtoolconfig to update the virtual machine password.

2. Run the following command to create, deploy and run the virtual machine

```bash
    ./avtool.sh -a deploy
```





### Starting/Stopping the virtual machine
Once the image is built you can start and stop the virtual machine.


1. Run the following command to start the virtual machine

```bash
    ./avtool.sh -a start
```


2. If the virtual machine is still running, you can run the following command to stop the virtual machine 

```bash
    ./avtool.sh -a stop
```

3. If the virtual machine  is still running, you can run the following command to get the status of the virtual machine 

```bash
    ./avtool.sh -a status
```

### Testing the virtual machine 
Once the image is built you can test if the virtual machine is fully functionning.

1. Run the following command to test the container

```bash
    ./avtool.sh -a test
```

For this virtual machine, the test feature will check if the following outputs are fully functionning:
- RTMP stream
- HLS stream
- RTSP stream
- Audio/Video Chunks stored in the Azure Storage container








# Next Steps

1. Update ffmpeg source code to avoid the installation of the NGINX RTMP  
