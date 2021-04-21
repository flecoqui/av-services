ARG AV_INPUT_FILE=input.json
ARG AV_OUTPUT_FILE=output.json
ARG AV_COMMAND_FILE=command.json
FROM alpine:3.12

ENV INPUT_FILE $AV_INPUT_FILE
ENV OUTPUT_FILE $AV_OUTPUT_FILE
ENV COMMAND_FILE $AV_COMMAND_FILE

# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv
RUN wget https://aka.ms/downloadazcopy-v10-linux &&
    tar -xvf downloadazcopy-v10-linux &&
    rm /usr/bin/azcopy &&
    cp ./azcopy_linux_amd64_*/azcopy /usr/bin/
# install ffmpeg 
RUN apk add ffmpeg

COPY docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh

CMD ./docker-entrypoint.sh -i $INPUT_FILE -c $COMMAND_FILE -o $OUTPUT_FILE
