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
AV_SERVICE=av-rtmp-source
AV_FLAVOR=alpine
AV_IMAGE_NAME=${AV_SERVICE}-${AV_FLAVOR} 
AV_IMAGE_FOLDER=av-services
AV_CONTAINER_NAME=av-rtmp-source-alpine-container
AV_RTMP_URL=rtmp://localhost:1935/live/stream
# Check if configuration file exists
if [[ ! -f "$repoRoot"/"$configuration_file" ]]; then
    cat > "$repoRoot"/"$configuration_file" << EOF
AV_IMAGE_NAME=${AV_IMAGE_NAME}
AV_IMAGE_FOLDER=${AV_IMAGE_FOLDER}
AV_CONTAINER_NAME=${AV_CONTAINER_NAME}
AV_RTMP_URL=${AV_RTMP_URL}
AV_TEMPDIR=$(mktemp -d)
EOF
fi
# Read variables in configuration file
export $(grep AV_IMAGE_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_IMAGE_FOLDER "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_RTMP_URL "$repoRoot"/"$configuration_file")
export $(grep AV_TEMPDIR "$repoRoot"/"$configuration_file" |  { read test; if [[ -z $test ]] ; then AV_TEMPDIR=$(mktemp -d) ; echo "AV_TEMPDIR=$AV_TEMPDIR" ; echo "AV_TEMPDIR=$AV_TEMPDIR" >> .avtoolconfig ; else echo $test; fi } )

if [[ -z "${AV_TEMPDIR}" ]] ; then
    AV_TEMPDIR=$(mktemp -d)
    sed -i 's/AV_TEMPDIR=.*/AV_TEMPDIR=${AV_TEMPDIR}/' "$repoRoot"/"$configuration_file"
fi

if [[ "${action}" == "install" ]] ; then
    echo "Installing pre-requisite"
    echo "Installing azure cli"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    echo "Installing ffmpeg"
    sudo apt-get -y update
    sudo apt-get -y install ffmpeg
    echo "Downloading content"
    wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv -O "${AV_TEMPDIR}"/camera-300s.mkv     
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
    sudo apt-get -y install  jq
    sudo apt-get -y install docker.io    
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
    sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    sudo docker container rm ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    sudo docker image rm ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} > /dev/null 2> /dev/null  || true
    sudo docker build -t ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} .
    sudo docker run  -d -it -e RTMP_URL=${AV_RTMP_URL} --name ${AV_CONTAINER_NAME} ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} 
    echo "Deployment done"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
    sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    sudo docker container rm ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    sudo docker image rm ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} > /dev/null 2> /dev/null  || true
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
    rm -f "${AV_TEMPDIR}"/*.mkv
    echo "Downloading content"
    wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv -O "${AV_TEMPDIR}"/camera-300s.mkv 
    echo "Starting RTMP sink ${AV_FLAVOR} container"
    sudo docker container start "av-rtmp-sink-${AV_FLAVOR}-container"  
    containerId=$(sudo docker ps -a --format "{{.ID}}" -f "name=av-rtmp-sink-${AV_FLAVOR}-container")
    privateIpAddress=$(sudo docker container inspect $containerId  --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
    echo "RTMP sink private IP address: ${privateIpAddress}"
    echo "Starting test-${AV_CONTAINER_NAME} container..."
    sudo  docker container stop "test-${AV_CONTAINER_NAME}" || true
    sudo  docker container rm "test-${AV_CONTAINER_NAME}" || true
    sudo docker run  -d -it -e RTMP_URL=rtmp://${privateIpAddress}:1935/live/stream  --name "test-${AV_CONTAINER_NAME}" ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} 

    echo "Capture 20s of RTMP stream on the host machine..."
    ffmpeg   -hide_banner -loglevel error -re -rw_timeout 20000000 -i ${AV_RTMP_URL}  -t 00:00:20  -c copy -flags +global_header -f segment -segment_time 10 -segment_format_options movflags=+faststart -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4 &
    sleep 40
    echo "Check mp4 captured streams in directory : ${AV_TEMPDIR}"
    if [[ ! -f "${AV_TEMPDIR}/testrtmp0.mp4" || ! -f "${AV_TEMPDIR}/testrtmp1.mp4" ]] ; then
        echo "Stopping RTMP sink ${AV_FLAVOR} container"
        sudo docker container "stop av-rtmp-sink-${AV_FLAVOR}-container"
        echo "Stopping test-${AV_CONTAINER_NAME} container..."
        sudo docker container stop "test-${AV_CONTAINER_NAME}"  
        echo "RTMP Test failed - check file ${AV_TEMPDIR}/testrtmp0.mp4"
        kill %1
        exit 1
    fi
    echo "Stopping RTMP sink ${AV_FLAVOR} container"
    sudo docker container stop "av-rtmp-sink-${AV_FLAVOR}-container"  
    echo "Stopping test-${AV_CONTAINER_NAME} container..."
    sudo docker container stop "test-${AV_CONTAINER_NAME}"  
    echo "Testing ${AV_CONTAINER_NAME} successful"
    echo "TESTS SUCCESSFUL"
    kill %1
    exit 0
fi
