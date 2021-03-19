FROM ubuntu:20.04 

ARG USERNAME=avuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

RUN apt-get update \
    && apt-get install -y ffmpeg wget 

# apt stuff
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    # install missing packages
    && mkdir -p /usr/share/man/man1 \
    && apt-get install -y sudo git curl \
    # add sudo support
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # install azure-cli
    && curl -sL https://aka.ms/InstallAzureCLIDeb  | bash 

# install python3 and pip3
RUN apt-get update \
    && apt-get install -y python3-pip 

# install tox, pre-commit and detect-secrets
RUN pip3 install iotedge-compose 

# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv

# now everything from here uses the normal user
USER $USERNAME


    
# back to default shell
SHELL ["/bin/sh", "-c"]

CMD [ "sleep", "infinity" ]