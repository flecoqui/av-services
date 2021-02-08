# av-services
This repository contains samples of software components which could be used to create Audio/Video workflows. Most of those components are based on Open Source libraries or tools. With those Audio/Video services, it's possible to support scenarios like:
- RTMP to RTSP protcol adaptor 
- RTMP Streamer from a Video file 
- RTMP Receiver into MP4 files in Azure Storage 


Below some basic components which could be used to create an  Audio/Video workflow

##  Audio/Video protocol adaptor client 
The Audio/Video Protocole Adaptor Client will support :
- An Input flow defined with a name, the content (audio only, video only, audio/video), the protocol, the target parameters (udp port, tcp port, ip address,...)
- An Output flow defined with a name, the content (audio only, video only, audio/video), the protocol different from the input protocol, the target parameters (udp port, tcp port, ip address,...)

The Audio/Video Protocole Adaptor Client runs in a specific environment:
- Operating System: Linux, Windows, MacOS
- Container 

![](./docs/img/workflow-adaptor-client.png)

##  Audio/Video protocol adaptor server 
![](./docs/img/workflow-adaptor-server.png)

##  Audio/Video source server  
![](./docs/img/workflow-source-server.png)

##  Audio/Video splitter server  
![](./docs/img/workflow-splitter-server.png)

##  Audio/Video renderer client  
![](./docs/img/workflow-renderer-client.png)


##  Audio/Video renderer server  
![](./docs/img/workflow-renderer-server.png)

##  Audio/Video receiver client  
![](./docs/img/workflow-receiver-client.png)


This repository contains samples of Audio/Video services based on Open Source libraries or tools. With those Audio/Video services, it's possible to support scenarios like:
- Audio/Video Gateway: for instance RTMP to RTSP Gateway
- Audio/Video Streamer: for instance RTMP Streamer from Video file 
- Audio/Video Receiver: for instance RTMP Receiver into MP4 files in Azure Storage 


Those Audio/Video services are running in:
- [Azure Virtual Machine](./arm/101-vm-light-hls-rtsp/README.md) 
- [Docker Containers](./docker/README.md)
- [Azure IoT Edge](./app-edge/README.md)
  
The following audio/video services are supported:
- Audio/Video Gateway: RTMP ingress/RTMP egress  
![](./docs/img/RTMP-splitter-server.png)
- Audio/Video Gateway: RTMP ingress/HLS egress  
![](./docs/img/RTMP-HLS-adaptor-server.png) 
- Audio/Video Gateway: RTMP ingress/RTSP egress   
![](./docs/img/RTMP-RTSP-adaptor-server.png) 
- Audio/Video Streamer: MP4 file RTMP Source server  
![](./docs/img/MP4-RTMP-source-server.png) 
- Audio/Video Receiver: RTMP ingress/MP4 files in Azure Storage  
![](./docs/img/RTMP-MP4-receiver-client.png) 



