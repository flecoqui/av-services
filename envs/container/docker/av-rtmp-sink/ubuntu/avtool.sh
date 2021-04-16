#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script used to install pre-requisites, deploy/undeploy service, start/stop service, test service
#- Parameters are:
#- [-a] action - value: login, install, deploy, undeploy, start, stop, status, test
#- [-e] Stop on Error - by default false
#- [-s] Silent mode - by default false
#- [-c] configuration file - which contains the list of path of each avtool.sh to call (avtool.env by default)
#
# executable
###########################################################################################################################################################################################
set -u
repoRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$repoRoot"
#######################################################
#- function used to print out script usage
#######################################################
function usage() {
    echo
    echo "Arguments:"
    echo -e " -a  Sets AV Tool action {install, deploy, undeploy, start, stop, status, test}"
    echo -e " -c  Sets the AV Tool configuration file"
    echo -e " -e  Sets the stop on error (false by defaut)"
    echo -e " -e  Sets Silent mode installation or deployment (false by defaut)"
    echo
    echo "Example:"
    echo -e " bash ./avtool.sh -a install "
    echo -e " bash ./avtool.sh -a start -c avtool.env -e true -s true"
    
}
action=
configuration_file=.avtoolconfig
stoperror=false
silentmode=false
while getopts "a:c:e:s:hq" opt; do
    case $opt in
    a) action=$OPTARG ;;
    c) configuration_file=$OPTARG ;;
    e) stoperror=$OPTARG ;;
    s) silentmode=$OPTARG ;;
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
if [[ ! $action == login && ! $action == install && ! $action == start && ! $action == stop && ! $action == status && ! $action == deploy && ! $action == undeploy && ! $action == test && ! $action == integration ]]; then
    echo "Required action is missing, values: login, install, deploy, undeploy, start, stop, status, test, integration"
    usage
    exit 1
fi
# colors for formatting the ouput
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

checkError() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}\nAn error occured exiting from the current bash${NC}"
        exit 1
    fi
}
checkDevContainerMode () {
    checkDevContainerModeResult="0"
    VOLNAME=$(docker volume inspect av-services_devcontainer_tempvol --format {{.Name}} 2> /dev/null) || true    
    # if running in devcontainer connect container to dev container network av-services_devcontainer_default
    if [[ $VOLNAME == 'av-services_devcontainer_tempvol' ]] ; then
        checkDevContainerModeResult="1"
    fi
    return
}
AV_SERVICE=av-rtmp-sink
AV_FLAVOR=ubuntu
AV_IMAGE_NAME=${AV_SERVICE}-${AV_FLAVOR} 
AV_IMAGE_FOLDER=av-services
AV_CONTAINER_NAME=av-rtmp-sink-ubuntu-container
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
AV_TEMPDIR=$(mktemp -d)
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
export $(grep AV_TEMPDIR "$repoRoot"/"$configuration_file" |  { read test; if [[ -z $test ]] ; then AV_TEMPDIR=$(mktemp -d) ; echo "AV_TEMPDIR=$AV_TEMPDIR" ; echo "AV_TEMPDIR=$AV_TEMPDIR" >> .avtoolconfig ; else echo $test; fi } )

if [[ -z "${AV_TEMPDIR}" ]] ; then
    AV_TEMPDIR=$(mktemp -d)
    sed -i 's/AV_TEMPDIR=.*/AV_TEMPDIR=${AV_TEMPDIR}/' "$repoRoot"/"$configuration_file"
fi

if [[ "${action}" == "install" ]] ; then
    echo "Installing pre-requisite"
    checkDevContainerMode  || true
    if [[ "$checkDevContainerModeResult" == "1" ]] ; then
        echo "As running in devcontainer av-services_devcontainer installation not required"
        echo -e "${GREEN}Installing pre-requisites done${NC}"
        exit 0
    else    
        echo "Installing azure cli"
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        echo "Installing ffmpeg"
        sudo apt-get -y update
        sudo apt-get -y install ffmpeg
        if [ ! -f "${AV_TEMPDIR}"/camera-300s.mkv ]; then
            echo "Downloading content"
            wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv -O "${AV_TEMPDIR}"/camera-300s.mkv     
        fi
        echo "Installing docker"
        # removing old version
        sudo apt-get -y remove docker docker-engine docker.io containerd runc
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
        sudo apt-get -y install  jq
        sudo apt-get -y install docker.io    
        sudo groupadd docker || true
        sudo usermod -aG docker ${USER} || true
        echo -e "${GREEN}Installing pre-requisites done${NC}"
        exit 0
    fi 
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login..."
    docker login
    echo -e "${GREEN}Login done${NC}"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying service..."
    docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    docker container rm ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    docker image rm ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} > /dev/null 2> /dev/null  || true
    docker build  --build-arg  AV_PORT_RTMP=${AV_PORT_RTMP} --build-arg  AV_PORT_SSL=${AV_PORT_SSL} --build-arg  AV_PORT_HTTP=${AV_PORT_HTTP} --build-arg  AV_PORT_HLS=${AV_PORT_HLS}  --build-arg  AV_HOSTNAME=${AV_HOSTNAME} --build-arg  AV_COMPANYNAME=${AV_COMPANYNAME} -t ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} . 
    checkError
    docker run  -d -it -p ${AV_PORT_HTTP}:${AV_PORT_HTTP}/tcp  -p ${AV_PORT_HLS}:${AV_PORT_HLS}/tcp    -p ${AV_PORT_RTMP}:${AV_PORT_RTMP}/tcp   -p ${AV_PORT_SSL}:${AV_PORT_SSL}/tcp  -e PORT_RTMP=${AV_PORT_RTMP} -e PORT_SSL=${AV_PORT_SSL} -e PORT_HTTP=${AV_PORT_HTTP} -e PORT_HLS=${AV_PORT_HLS}  -e HOSTNAME=${AV_HOSTNAME} -e COMPANYNAME=${AV_COMPANYNAME} --name ${AV_CONTAINER_NAME} ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} 
    checkError
    echo -e "${GREEN}Deployment done${NC}"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
    docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    docker container rm ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    docker image rm ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} > /dev/null 2> /dev/null  || true
    echo -e "${GREEN}Undeployment done${NC}"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Checking status..."
    docker container inspect ${AV_CONTAINER_NAME} --format '{{json .State.Status}}'
    echo -e "${GREEN}Container status done${NC}"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting service..."
    docker container start ${AV_CONTAINER_NAME}
    echo -e "${GREEN}Container started${NC}"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping service..."
    docker container stop ${AV_CONTAINER_NAME}
    echo -e "${GREEN}Container stopped${NC}"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    rm -f "${AV_TEMPDIR}"/*.mp4
    if [ ! -f "${AV_TEMPDIR}"/camera-300s.mkv ]; then
        echo "Downloading content"
        wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv -O "${AV_TEMPDIR}"/camera-300s.mkv     
    fi
    echo "Start ${AV_CONTAINER_NAME} container..."
    docker container start ${AV_CONTAINER_NAME}

    # Wait 10 seconds before starting  the RTMP stream
    sleep 10    
    checkDevContainerMode  || true
    if [[ "$checkDevContainerModeResult" == "1" ]] ; then
        docker network connect av-services_devcontainer_default ${AV_CONTAINER_NAME} 
        CONTAINER_IP=$(docker container inspect "${AV_CONTAINER_NAME}" | jq -r '.[].NetworkSettings.Networks."av-services_devcontainer_default".IPAddress')
    else
        CONTAINER_IP=${AV_HOSTNAME}
    fi    
    echo "Start ffmpeg RTMP streamer on the host machine..."
    ffmpeg -hide_banner -loglevel error  -re -stream_loop -1 -i "${AV_TEMPDIR}"/camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb   -f flv rtmp://${CONTAINER_IP}:${AV_PORT_RTMP}/live/stream &
    # Wait 20 seconds before reading the RTMP stream
    sleep 20    
    echo "Capture 20s of RTMP stream on the host machine..."
    ffmpeg   -hide_banner -loglevel error -re -rw_timeout 20000000 -i rtmp://${CONTAINER_IP}:${AV_PORT_RTMP}/live/stream  -t 00:00:20  -c copy -flags +global_header -f segment -segment_time 10 -segment_format_options movflags=+faststart -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4 &
    sleep 40
    echo "Check mp4 captured streams in directory : ${AV_TEMPDIR}"
    if [[ ! -f "${AV_TEMPDIR}/testrtmp0.mp4" || ! -f "${AV_TEMPDIR}/testrtmp1.mp4" ]] ; then
        echo "RTMP Test failed - check file ${AV_TEMPDIR}/testrtmp0.mp4"
        kill %1
        # if running in devcontainer disconnect container from dev container network av-services_devcontainer_default
        checkDevContainerMode  || true
        if [[ "$checkDevContainerModeResult" == "1" ]] ; then
            docker network disconnect av-services_devcontainer_default ${AV_CONTAINER_NAME} 
        fi        
        docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
        exit 1
    fi
    echo "Capture 20s of HLS stream on the host machine..."
    ffmpeg   -hide_banner -loglevel error -re  -i http://${CONTAINER_IP}:${AV_PORT_HLS}/live/stream.m3u8  -t 00:00:20  -c copy -flags +global_header -f segment -segment_time 10 -segment_format_options movflags=+faststart -reset_timestamps 1 "${AV_TEMPDIR}"/testhls%d.mp4 &
    sleep 40
    echo "Check mp4 captured streams in directory : ${AV_TEMPDIR}"
    if [[ ! -f "${AV_TEMPDIR}/testhls0.mp4" || ! -f "${AV_TEMPDIR}/testhls1.mp4" ]] ; then
        echo "RTMP Test failed - check file ${AV_TEMPDIR}/testhls0.mp4"
        kill %1
        # if running in devcontainer disconnect container from dev container network av-services_devcontainer_default
        checkDevContainerMode  || true
        if [[ "$checkDevContainerModeResult" == "1" ]] ; then
            docker network disconnect av-services_devcontainer_default ${AV_CONTAINER_NAME} 
        fi
        docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
        exit 1
    fi    
    echo "Testing ${AV_CONTAINER_NAME} successful"
    kill %1
    # if running in devcontainer disconnect container from dev container network av-services_devcontainer_default
    checkDevContainerMode  || true
    if [[ "$checkDevContainerModeResult" == "1" ]] ; then
        docker network disconnect av-services_devcontainer_default ${AV_CONTAINER_NAME} 
    fi
    docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    echo -e "${GREEN}TESTS SUCCESSFUL${NC}"
    exit 0
fi
