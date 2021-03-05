#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script used to install pre-requisites, deploy/undeploy service, start/stop service, test service
#- Parameters are:
#- [-a] action - value: login, install, deploy, undeploy, start, stop, status, test
#- [-c] configuration file - by default avtool.env
#
# executable
###########################################################################################################################################################################################
set -eu
repoRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$repoRoot"
#######################################################
#- function used to print out script usage
#######################################################
function usage() {
    echo
    echo "Arguments:"
    echo -e "\t-a\t Sets AV Tool action {install, deploy, undeploy, start, stop, status, test}"
    echo -e "\t-c \t Sets the AV Tool configuration file"
    echo
    echo "Example:"
    echo -e "\tbash avtool.sh -a install "
    echo -e "\tbash avtool.sh -a start -c avtool.env"    
}
action=
configuration_file=.avtoolconfig
while getopts "a:c:hq" opt; do
    case $opt in
    a) action=$OPTARG ;;
    c) configuration_file=$OPTARG ;;
    :)
        echo "Error: -${OPTARG} requires a value"
        exit 1
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

# Validation
if [[ $# -eq 0 || -z $action || -z $configuration_file ]]; then
    echo "Required parameters are missing"
    usage
    exit 1
fi
if [[ ! $action == login && ! $action == install && ! $action == start && ! $action == stop && ! $action == status && ! $action == deploy && ! $action == undeploy && ! $action == test ]]; then
    echo "Required action is missing, values: login, install, deploy, undeploy, start, stop, status, test"
    usage
    exit 1
fi
AV_SERVICE=av-rtmp-sink
AV_FLAVOR=alpine
AV_IMAGE_NAME=${AV_SERVICE}-${AV_FLAVOR} 
AV_IMAGE_FOLDER=av-services
AV_CONTAINER_NAME=av-rtmp-sink-alpine-container
AV_COMPANYNAME=contoso
AV_HOSTNAME=localhost
AV_PORT_HLS=8080
AV_PORT_HTTP=80
AV_PORT_SSL=443
AV_PORT_RTMP=1935
# Check if configuration file exists
if [[ ! -f "$repoRoot"/"$configuration_file" ]]; then
    cat > "$repoRoot"/"$configuration_file" << EOF
AV_IMAGE_NAME=${AV_IMAGE_NAME}
AV_IMAGE_FOLDER=${AV_IMAGE_FOLDER}
AV_CONTAINER_NAME=${AV_CONTAINER_NAME}
AV_COMPANYNAME=${AV_COMPANYNAME}
AV_HOSTNAME=${AV_HOSTNAME}
AV_PORT_HLS=${AV_PORT_HLS}
AV_PORT_HTTP=${AV_PORT_HTTP}
AV_PORT_SSL=${AV_PORT_SSL}
AV_PORT_RTMP=${AV_PORT_RTMP}
EOF
fi
# Read variables in configuration file
export $(grep AV_IMAGE_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_IMAGE_FOLDER "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_COMPANYNAME "$repoRoot"/"$configuration_file")
export $(grep AV_HOSTNAME "$repoRoot"/"$configuration_file")
export $(grep AV_PORT_HLS "$repoRoot"/"$configuration_file")
export $(grep AV_PORT_HTTP "$repoRoot"/"$configuration_file")
export $(grep AV_PORT_SSL "$repoRoot"/"$configuration_file")
export $(grep AV_PORT_RTMP "$repoRoot"/"$configuration_file")

if [[ "${action}" == "install" ]] ; then
    echo "Installing pre-requisite"
    echo "Installing azure cli"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    echo "Installing ffmpeg"
    sudo apt-get -y update
    sudo apt-get -y install ffmpeg
    echo "Downloading content"
    wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv
    echo "Installing docker"
    # removing old version
    sudo apt-get remove docker docker-engine docker.io containerd runc
    sudo apt-get -y update
    sudo apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"
    sudo apt-get -y update
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io    
    sudo groupadd docker || true
    sudo usermod -aG docker ${USER} || true
    exit 0
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login..."
    docker login
    echo "Login done"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying service..."
    sudo docker container rm ${AV_CONTAINER_NAME} || true
    sudo docker image rm ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} || true
    sudo docker build -t ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} .
    sudo docker run  -d -it -p ${AV_PORT_HTTP}:${AV_PORT_HTTP}/tcp  -p ${AV_PORT_HLS}:${AV_PORT_HLS}/tcp    -p ${AV_PORT_RTMP}:${AV_PORT_RTMP}/tcp -p ${AV_PORT_SSL}:${AV_PORT_SSL}/tcp -e PORT_RTMP=${AV_PORT_RTMP} -e PORT_SSL=${AV_PORT_SSL} -e PORT_HTTP=${AV_PORT_HTTP} -e PORT_HLS=${AV_PORT_HLS}  -e HOSTNAME=${AV_HOSTNAME} -e COMPANYNAME=${AV_COMPANYNAME} --name ${AV_CONTAINER_NAME} ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} 
    echo "Deployment done"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
    sudo docker container rm ${AV_CONTAINER_NAME} || true
    sudo docker image rm ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} || true
    echo "Undeployment done"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Checking status..."
    sudo docker container inspect ${AV_CONTAINER_NAME} --format '{{json .State.Status}}'
    echo "Status done"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting service..."
    sudo docker container start ${AV_CONTAINER_NAME}
    echo "Start done"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping service..."
    sudo docker container stop ${AV_CONTAINER_NAME}
    echo "Stop done"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    rm -f "${AV_TEMPDIR}"/*.mp4
    echo "Start av-rtmp-sink container..."

    sudo docker container start -i ${AV_CONTAINER_NAME}
    echo "Testing av-rtmp-sink successful"
    echo "TESTS SUCCESSFUL"
    exit 0
fi
