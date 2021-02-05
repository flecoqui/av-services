# av-services
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
- Audio/Video Gateway: RTMP ingress/HLS egress 
- Audio/Video Gateway: RTMP ingress/RTSP egress 
- Audio/Video Streamer: MKV file/RTMP egress
- Audio/Video Receiver: RTMP ingress/MP4 files in Azure Storage

