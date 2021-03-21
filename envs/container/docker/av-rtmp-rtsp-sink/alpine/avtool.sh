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
AV_SERVICE=av-rtmp-rtsp-sink
AV_FLAVOR=alpine
AV_IMAGE_NAME=${AV_SERVICE}-${AV_FLAVOR} 
AV_IMAGE_FOLDER=av-services
AV_CONTAINER_NAME=av-rtmp-rtsp-sink-alpine-container
AV_COMPANYNAME=contoso
AV_HOSTNAME=localhost
AV_PORT_HLS=8080
AV_PORT_HTTP=80
AV_PORT_SSL=443
AV_PORT_RTMP=1935
AV_PORT_RTSP=8554
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
AV_PORT_RTSP=${AV_PORT_RTSP}
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
export $(grep AV_PORT_RTSP "$repoRoot"/"$configuration_file")
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
    sudo docker build --build-arg  AV_PORT_RTSP=${AV_PORT_RTSP} --build-arg  AV_PORT_RTMP=${AV_PORT_RTMP} --build-arg  AV_PORT_SSL=${AV_PORT_SSL} --build-arg  AV_PORT_HTTP=${AV_PORT_HTTP} --build-arg  AV_PORT_HLS=${AV_PORT_HLS}  --build-arg  AV_HOSTNAME=${AV_HOSTNAME} --build-arg  AV_COMPANYNAME=${AV_COMPANYNAME}  ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} . 
    sudo docker run  -d -it -p ${AV_PORT_HTTP}:${AV_PORT_HTTP}/tcp  -p ${AV_PORT_HLS}:${AV_PORT_HLS}/tcp    -p ${AV_PORT_RTMP}:${AV_PORT_RTMP}/tcp -p ${AV_PORT_RTSP}:${AV_PORT_RTSP}/tcp  -p ${AV_PORT_SSL}:${AV_PORT_SSL}/tcp -e PORT_RTSP=${AV_PORT_RTSP} -e PORT_RTMP=${AV_PORT_RTMP} -e PORT_SSL=${AV_PORT_SSL} -e PORT_HTTP=${AV_PORT_HTTP} -e PORT_HLS=${AV_PORT_HLS}  -e HOSTNAME=${AV_HOSTNAME} -e COMPANYNAME=${AV_COMPANYNAME} --name ${AV_CONTAINER_NAME} ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} 
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
    echo "Start ${AV_CONTAINER_NAME} container..."
    sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    sudo docker container start ${AV_CONTAINER_NAME} 

    # Wait 10 seconds before starting  the RTMP stream
    sleep 10   
    echo "Start ffmpeg RTMP streamer on the host machine..."
    ffmpeg -hide_banner -loglevel error  -re -stream_loop -1 -i "${AV_TEMPDIR}"/camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb   -f flv rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/live/stream &
    # Wait 20 seconds before reading the RTMP stream
    sleep 20
    echo "Capture 20s of RTMP stream on the host machine..."
    ffmpeg   -hide_banner -loglevel error -i rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/live/stream  -t 00:00:20  -c copy -flags +global_header -f segment -segment_time 10 -segment_format_options movflags=+faststart -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4 &
    sleep 40
    echo "Check mp4 captured streams in directory : ${AV_TEMPDIR}"
    if [[ ! -f "${AV_TEMPDIR}/testrtmp0.mp4" || ! -f "${AV_TEMPDIR}/testrtmp1.mp4" ]] ; then
        echo "RTMP Test failed - check file ${AV_TEMPDIR}/testrtmp0.mp4"
        kill %1
        sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true    
        exit 1
    fi
    echo "Capture 20s of HLS stream on the host machine..."
    ffmpeg   -hide_banner -loglevel error  -i http://${AV_HOSTNAME}:${AV_PORT_HLS}/live/stream.m3u8  -t 00:00:20  -c copy -flags +global_header -f segment -segment_time 10 -segment_format_options movflags=+faststart -reset_timestamps 1 "${AV_TEMPDIR}"/testhls%d.mp4 &
    sleep 40
    echo "Check mp4 captured streams in directory : ${AV_TEMPDIR}"
    if [[ ! -f "${AV_TEMPDIR}/testhls0.mp4" || ! -f "${AV_TEMPDIR}/testhls1.mp4" ]] ; then
        echo "RTMP Test failed - check file ${AV_TEMPDIR}/testhls0.mp4"
        kill %1
        sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true    
        exit 1
    fi  
    echo "Capture 20s of RTSP stream on the host machine..."
    ffmpeg   -hide_banner -loglevel error  -rtsp_transport tcp -i rtsp://${AV_HOSTNAME}:${AV_PORT_RTSP}/rtsp/stream  -t 00:00:20  -c copy -flags +global_header -f segment -segment_time 10 -segment_format_options movflags=+faststart -reset_timestamps 1 "${AV_TEMPDIR}"/testrtsp%d.mp4 &
    sleep 40
    echo "Check mp4 captured streams in directory : ${AV_TEMPDIR}"
    if [[ ! -f "${AV_TEMPDIR}/testrtsp0.mp4" || ! -f "${AV_TEMPDIR}/testrtsp1.mp4" ]] ; then
        echo "RTMP Test failed - check file ${AV_TEMPDIR}/testrtsp0.mp4"
        kill %1
        sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true    
        exit 1
    fi        
    echo "Testing ${AV_CONTAINER_NAME} successful"
    echo "TESTS SUCCESSFUL"
    kill %1
    sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true    
    exit 0
fi
