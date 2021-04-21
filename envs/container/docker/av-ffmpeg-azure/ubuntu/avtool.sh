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
AV_SERVICE=av-ffmpeg
AV_FLAVOR=ubuntu
AV_IMAGE_NAME=${AV_SERVICE}-${AV_FLAVOR} 
AV_IMAGE_FOLDER=av-services
AV_CONTAINER_NAME=av-ffmpeg-ubuntu-container
AV_VOLUME=tempvol
AV_FFMPEG_COMMAND="ffmpeg -y -nostats -loglevel 0  -i ./camera-300s.mkv -codec copy /${AV_VOLUME}/camera-300s.mp4"
# Check if configuration file exists
if [[ ! -f "$repoRoot"/"$configuration_file" ]]; then
    cat > "$repoRoot"/"$configuration_file" << EOF
AV_IMAGE_NAME=${AV_IMAGE_NAME}
AV_IMAGE_FOLDER=${AV_IMAGE_FOLDER}
AV_CONTAINER_NAME=${AV_CONTAINER_NAME}
AV_VOLUME=${AV_VOLUME}
AV_FFMPEG_COMMAND="${AV_FFMPEG_COMMAND}"
AV_TEMPDIR=$(mktemp -d)
EOF
fi
# Read variables in configuration file
export $(grep AV_IMAGE_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_IMAGE_FOLDER "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_NAME "$repoRoot"/"$configuration_file")
var=$(grep AV_FFMPEG_COMMAND "$repoRoot"/"$configuration_file")
cmd="export $var"
eval $cmd
export $(grep AV_VOLUME "$repoRoot"/"$configuration_file")
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
    docker container rm ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    docker image rm ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} > /dev/null 2> /dev/null  || true
    docker build -t ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} .
    checkError
    checkDevContainerMode  || true
    if [[ "$checkDevContainerModeResult" == "1" ]] ; then
        TEMPVOL=${VOLNAME}
    else
        TEMPVOL=${AV_TEMPDIR}
    fi
    docker run  -d -it -v ${TEMPVOL}:/${AV_VOLUME} --name ${AV_CONTAINER_NAME} ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} ${AV_FFMPEG_COMMAND}
    checkError
    echo -e "${GREEN}Deployment done${NC}"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
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
    checkDevContainerMode  || true
    if [[ "$checkDevContainerModeResult" == "1" ]] ; then
        TEMPVOL="/tempvol"
    else
        TEMPVOL=${AV_TEMPDIR}
    fi
    sudo rm -f "${TEMPVOL}"/*.mp4
    echo "Start av-ffmpeg container..."
    echo ""
    echo "FFMPEG encoding command: ${AV_FFMPEG_COMMAND}"
    echo ""
    if [[ ! -d "${TEMPVOL}" ]] ; then
        echo "ffmpeg Test failed - volume directory doesn't exist: ${TEMPVOL}"
        echo "Deploy the container before running the tests"
        exit 1
    fi
    docker container stop  ${AV_CONTAINER_NAME}
    docker container start -i ${AV_CONTAINER_NAME}
    echo "Output directory : ${TEMPVOL}"
    if [[ ! -f "${TEMPVOL}/camera-300s.mp4" ]] ; then
        echo "ffmpeg Test failed - check file ${TEMPVOL}/camera-300s.mp4"
        docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
        exit 1
    fi
    echo "File ${TEMPVOL}/camera-300s.mp4 exists"
    echo "Testing ffmpeg successful"
    docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    echo -e "${GREEN}TESTS SUCCESSFUL${NC}"
    exit 0
fi