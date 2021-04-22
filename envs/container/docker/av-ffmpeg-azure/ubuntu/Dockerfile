FROM ubuntu:20.04 

RUN apt-get -y update \
 && apt-get -y install ffmpeg wget jq

# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv

# installing azcopy
RUN wget https://aka.ms/downloadazcopy-v10-linux \ 
    && tar -xvf downloadazcopy-v10-linux  \
    && cp ./azcopy_linux_amd64_*/azcopy /usr/bin/ \
    && chmod 0755 /usr/bin/azcopy

COPY batch.sh /
RUN chmod 0755 /batch.sh

CMD ["@"]
