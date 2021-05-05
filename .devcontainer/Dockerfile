FROM ubuntu:20.04 

ARG USERNAME=avuser
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

RUN apt-get update \
    && apt-get install -y gnupg software-properties-common ffmpeg wget 

# apt stuff
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    # install missing packages
    && mkdir -p /usr/share/man/man1 \
    && apt-get install -y sudo git curl make procps lsb-release vim jq\
    # add sudo support
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # install azure-cli
    && curl -sL https://aka.ms/InstallAzureCLIDeb  | bash 

# install python3 and pip3
RUN apt-get update \
    && apt-get install -y python3-pip 

# install iotedge-compose 
RUN pip3 install iotedge-compose 

# install .Net 5.0 SDK
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN apt-get update \
    && apt-get install -y apt-transport-https \
    && apt-get install -y dotnet-sdk-5.0
    
# Install Docker CLI
RUN apt-get update \
    && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    dnsutils
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN  apt-get update \
      && apt-get install -y docker-ce-cli

# copy sample mkv video 
RUN wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv?raw=true -O  /camera-300s.mkv

# now everything from here uses the normal user
USER $USERNAME

# configure az cli to automatically install extension
RUN az config set extension.use_dynamic_install=yes_without_prompt

# back to default shell
SHELL ["/bin/sh", "-c"]

CMD [ "sleep", "infinity" ]