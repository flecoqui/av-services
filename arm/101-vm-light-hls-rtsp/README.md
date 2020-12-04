# Deployment of a RTMP Ingester hosted on Azure Virtual Machine using NGINX RTMP, RTSP-SIMPLE-SERVER and FFMPEG with HLS, RTMP and RTSP Playback

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2FRTMPIngest%2Fmaster%2FAzure%2F101-vm-light-hls-rtsp%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fflecoqui%2FRTMPIngest%2Fmaster%2FAzure%2F101-vm-light-hls-rtsp%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template allows you to deploy from Github a Live RTMP Ingester hosted on Azure Virtual Machine. Moreover, beyond the RTMP Ingester, the a service copy the video chunks on an Azure Storage Account. Moreover, this service allow the user to playback:
- the HLS stream generated from the incoming RTMP stream
- the RTMP stream generated from the incoming RTMP stream
- the RTSP stream generated from the incoming RTMP stream
  
As this template doesn't build FFMPEG from the source code, the deployment should take around 20 minutes to build NGINX RTMP.


![](https://raw.githubusercontent.com/flecoqui/av-services/master/arm/101-vm-light-hls-rtsp/Docs/1-architecture.png)



# DEPLOYING THE REST API ON AZURE SERVICES

## PRE-REQUISITES
First you need an Azure subscription.
You can subscribe here:  https://azure.microsoft.com/en-us/free/ . </p>
Moreover, we will use Azure CLI v2.0 to deploy the resources in Azure.
You can install Azure CLI on your machine running Linux, MacOS or Windows from here: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest 



## CREATE RESOURCE GROUP:
First you need to create the resource group which will be associated with this deployment. For this step, you can use Azure CLI v1 or v2.

* **Azure CLI 1.0:** azure group create "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:** az group create an "ResourceGroupName" -l "RegionName"

For instance:

    azure group create RTMPIngestrg eastus2

    az group create -n RTMPIngestrg -l eastus2

## DEPLOY THE SERVICES:

### DEPLOY REST API ON AZURE FUNCTION, APP SERVICE, VIRTUAL MACHINE:
You can deploy Azure Function, Azure App Service and Virtual Machine using ARM (Azure Resource Manager) Template and Azure CLI v1 or v2

* **Azure CLI 1.0:** azure group deployment create "ResourceGroupName" "DeploymentName"  -f azuredeploy.json -e azuredeploy.parameters.json*

* **Azure CLI 2.0:** az group deployment create -g "ResourceGroupName" -n "DeploymentName" --template-file "templatefile.json" --parameters @"templatefile.parameter..json"  --verbose -o json

For instance:

    azure group deployment create RTMPIngestrg RTMPIngestdep -f azuredeploy.json -e azuredeploy.parameters.json -vv

    az group deployment create -g RTMPIngestrg -n RTMPIngestdep --template-file azuredeploy.json --parameter @azuredeploy.parameters.json --verbose -o json


When you deploy the service you can define the following parameters:</p>
* **namePrefix:** The name prefix which will be used for all the services deployed with this ARM Template</p>
* **vmAdminUsername:** VM login by default "VMAdmin"</p>
* **vmAdminPassword:** VM password by default "VMP@ssw0rd"</p>
* **vmOS:** supported values "debian","ubuntu","centos","redhat" by default "debian"</p>
* **vmSize:** supported values"Small" (Standard_D2s_v3),"Medium" (Standard_D4s_v3),"Large" (Standard_D8s_v3),"XLarge" (Standard_D16s_v3) by default "Small"</p>
* **containerName:** the name of the container on the Azure Storage where the audio/video chunks will be recorded, by default "rtmpcontainer"</p>
* **expiryDate:** the expiry date of the SAS Token used to access the content stored in the container. by default "2030-01-01T00:00:01Z"</p>


# TEST THE SERVICES:

## TEST THE SERVICES WITH FFMPEG
Once the services are deployed, you can test the RTMP Ingester using ffmpeg on a PC running Windows 10. You can download ffmpeg from here https://www.ffmpeg.org/download.html  
When the resources associated with the current ARM template are deployed, the ffmpegCmd output parameter contains the ffmpeg command line to feed the new virtual machine with a live RTMP stream using the following URL: 
            
            rtmp://vmName.region.cloudapp.azure.com:1935/rtmpPath


For instance :

     ffmpeg.exe -v verbose -f dshow -i video="Integrated Webcam":audio="Microphone (Realtek(R) Audio)"  -video_size 1280x720 -strict -2 -c:a aac -b:a 192k -ar 44100 -r 30 -g 60 -keyint_min 60 -b:v 2000000 -c:v libx264 -preset veryfast  -profile main -level 3.0 -pix_fmt yuv420p -bufsize 1800k -maxrate 400k    -f flv rtmp://RTMPIngesterIPAddress:1935/live/stream

</p>


![](https://raw.githubusercontent.com/flecoqui/av-services/master/arm/101-vm-light-hls-rtsp/Docs/ffmpeg.png)

After one minute of streaming, the audio/video chunks are copied in the Azure Storage Container. You can display the content of this container if you open the output parameter containerUrl with your favorite browser.

![](https://raw.githubusercontent.com/flecoqui/av-services/master/arm/101-vm-light-hls-rtsp/Docs/container.png)

You can also playback the HLS stream, if you open with your browser the following urls:
            

            http://vmName.region.cloudapp.azure.com/player.html
            
            http://vmName.region.cloudapp.azure.com:8080/hls/stream.m3u8


![](https://raw.githubusercontent.com/flecoqui/av-services/master/arm/101-vm-light-hls-rtsp/Docs/player.png)

You can play with VLC the rtmp stream as well using the following url:

            rtmp://vmName.region.cloudapp.azure.com:1935/live/stream

You can play with VLC the rtsp stream as well using the following url:

            rtsp://vmName.region.cloudapp.azure.com:8554/test



## DELETE THE RESOURCE GROUP:

* **Azure CLI 1.0:**      azure group delete "ResourceGroupName" "RegionName"

* **Azure CLI 2.0:**  az group delete -n "ResourceGroupName" "RegionName"

For instance:

    azure group delete RTMPIngestrg eastus2

    az group delete -n RTMPIngestrg 



# Next Steps

1. Update ffmpeg source code to avoid the installation of the NGINX RTMP  
