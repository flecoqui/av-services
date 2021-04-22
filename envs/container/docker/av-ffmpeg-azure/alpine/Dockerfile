FROM alpine:3.13.5


# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv

# installing azcopy
RUN wget https://aka.ms/downloadazcopy-v10-linux \ 
    && tar -xvf downloadazcopy-v10-linux  \
    && cp ./azcopy_linux_amd64_*/azcopy /usr/bin/ \
    && chmod 0755 /usr/bin/azcopy

# install ffmpeg 
RUN apk update \
    && apk update \
    && apk add ffmpeg jq

COPY batch.sh /
RUN chmod 0755 /batch.sh

CMD ["@"]
