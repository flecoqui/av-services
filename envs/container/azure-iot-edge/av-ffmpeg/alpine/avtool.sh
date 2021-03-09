#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script used to install pre-requisites, deploy/undeploy service, start/stop service, test service
#- Parameters are:
#- [-a] action - value: login, install, deploy, undeploy, start, stop, status, test
#- [-c] configuration file - by default avtool.env
#
# executable
###########################################################################################################################################################################################
set -u
avdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$avdir"

# colors for formatting the ouput
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

checkAVError() {
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}An error occured:${NC}
    The script will be stopped."
        exit 1
    fi
}
#######################################################
#- function used to escape character in string 
#######################################################
function sedescape {
 printf '%s\n' "$1" | sed -e 's/[\/&]/\\&/g'
}

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
AV_SERVICE=av-ffmpeg
AV_FLAVOR=alpine
AV_IMAGE_NAME=${AV_SERVICE}-${AV_FLAVOR} 
AV_IMAGE_FOLDER=av-services
AV_CONTAINER_NAME=av-ffmpeg-alpine-container
AV_VOLUME=data1
AV_FFMPEG_COMMAND="ffmpeg -y -nostats -loglevel 0  -i ./camera-300s.mkv -codec copy /${AV_VOLUME}/camera-300s.mp4"
# Check if configuration file exists
if [[ ! -f "$avdir"/"$configuration_file" ]]; then
    cat > "$avdir"/"$configuration_file" << EOF
AV_IMAGE_NAME=${AV_IMAGE_NAME}
AV_IMAGE_FOLDER=${AV_IMAGE_FOLDER}
AV_CONTAINER_NAME=${AV_CONTAINER_NAME}
AV_VOLUME=${AV_VOLUME}
AV_FFMPEG_COMMAND="${AV_FFMPEG_COMMAND}"
AV_TEMPDIR=$(mktemp -d)
EOF
fi
# Read variables in configuration file
export $(grep AV_IMAGE_NAME "$avdir"/"$configuration_file")
export $(grep AV_IMAGE_FOLDER "$avdir"/"$configuration_file")
export $(grep AV_CONTAINER_NAME "$avdir"/"$configuration_file")
var=$(grep AV_FFMPEG_COMMAND "$avdir"/"$configuration_file")
cmd="export $var"
eval $cmd
export $(grep AV_VOLUME "$avdir"/"$configuration_file")
export $(grep AV_TEMPDIR "$avdir"/"$configuration_file" |  { read test; if [[ -z $test ]] ; then AV_TEMPDIR=$(mktemp -d) ; echo "AV_TEMPDIR=$AV_TEMPDIR" ; echo "AV_TEMPDIR=$AV_TEMPDIR" >> .avtoolconfig ; else echo $test; fi } )

if [[ -z "${AV_TEMPDIR}" ]] ; then
    AV_TEMPDIR=$(mktemp -d)
    sed -i 's/AV_TEMPDIR=.*/AV_TEMPDIR=${AV_TEMPDIR}/' "$avdir"/"$configuration_file"
fi

if [[ "${action}" == "install" ]] ; then
    echo "Installing pre-requisite"
    echo "Installing azure cli"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    checkAVError
    echo "Installing ffmpeg"
    sudo apt-get -y update
    sudo apt-get -y install ffmpeg
    checkAVError
    echo "Downloading content"
    wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv
    checkAVError
    echo "Installing docker"
    # removing old version
    sudo apt-get remove docker docker-engine docker.io containerd runc
    checkAVError
    sudo apt-get -y update
    checkAVError
    sudo apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
    checkAVError
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    checkAVError
    sudo apt-key fingerprint 0EBFCD88
    checkAVError
    sudo add-apt-repository \
        "deb [ar
        ch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"
    sudo apt-get -y update
    checkAVError
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io    
    checkAVError
    sudo groupadd docker || true
    sudo usermod -aG docker ${USER} || true
    checkAVError
    pip install -y iotedge-compose
    exit 0
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login..."
    docker login
    checkAVError
    echo "Login done"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Creating docker-compose file..."
    AV_FFMPEG_COMMAND_ESCAPE=$(printf '%s\n' "$AV_FFMPEG_COMMAND" | sed -e 's/[\/&]/\\&/g') 
    AV_IMAGE_NAME_ESCAPE=$(printf '%s\n' "$AV_IMAGE_NAME" | sed -e 's/[\/&]/\\&/g')
    AV_CONTAINER_NAME_ESCAPE=$(printf '%s\n' "$AV_CONTAINER_NAME" | sed -e 's/[\/&]/\\&/g')
    AV_TEMPDIR_ESCAPE=$(printf '%s\n' "$AV_TEMPDIR" | sed -e 's/[\/&]/\\&/g')
    AV_VOLUME_ESCAPE=$(printf '%s\n' "$AV_VOLUME"  | sed -e 's/[\/&]/\\&/g')    
#    echo "$AV_FFMPEG_COMMAND_ESCAPE"
#    echo "$AV_IMAGE_NAME_ESCAPE"
#    echo "$AV_CONTAINER_NAME_ESCAPE"
#    echo "$AV_TEMPDIR_ESCAPE"
#    echo "$AV_VOLUME_ESCAPE"
    Command0="s/\${AV_FFMPEG_COMMAND}/$AV_FFMPEG_COMMAND_ESCAPE/g"
    Command1="s/\${AV_IMAGE_NAME}/$AV_IMAGE_NAME_ESCAPE/g"
    Command2="s/\${AV_CONTAINER_NAME}/$AV_CONTAINER_NAME_ESCAPE/g"
    Command3="s/\${AV_TEMPDIR}/$AV_TEMPDIR_ESCAPE/g"
    Command4="s/\${AV_VOLUME}/$AV_VOLUME_ESCAPE/g"
    cat ../../../docker/av-ffmpeg/alpine/docker-compose.template.yml \
      | sed "$Command0" \
      | sed "$Command1" \
      | sed "$Command2" \
      | sed "$Command3" \
      | sed "$Command4" \
      > ./docker-compose.yml
    cp  ../../../docker/av-ffmpeg/alpine/Dockerfile ./Dockerfile
    echo "Deploying service locally..."
    sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    sudo docker container rm ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    sudo docker image rm ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME} > /dev/null 2> /dev/null  || true     
    sudo docker-compose up --build
    checkAVError
    echo "Creating the IoT Edge project..."
    sudo iotedge-compose -t project -i ./docker-compose.yml -o av-ffmpeg-alpine-edge
    checkAVError
    echo "Deployment done"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
    sudo docker-compose down 
    checkAVError
    echo "Undeployment done"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Checking status..."
    sudo docker container inspect ${AV_CONTAINER_NAME} --format '{{json .State.Status}}'
    checkAVError
    echo "Status done"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting service..."
    sudo docker-compose start 
    checkAVError
    echo "Start done"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping service..."
    sudo docker-compose stop 
    checkAVError
    echo "Stop done"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    rm -f "${AV_TEMPDIR}"/*.mp4
    echo "Start av-ffmpeg container..."
    echo ""
    echo "FFMPEG encoding command: ${AV_FFMPEG_COMMAND}"
    echo ""
    if [[ ! -d "${AV_TEMPDIR}" ]] ; then
        echo "ffmpeg Test failed - volume directory doesn't exist: ${AV_TEMPDIR}"
        echo "Deploy the container before running the tests"
        exit 1
    fi
    sudo docker container start -i ${AV_CONTAINER_NAME}
    checkAVError
    echo "Output directory : ${AV_TEMPDIR}"
    if [[ ! -f "${AV_TEMPDIR}/camera-300s.mp4" ]] ; then
        echo "ffmpeg Test failed - check file ${AV_TEMPDIR}/camera-300s.mp4"
        sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
        exit 1
    fi
    echo "File ${AV_TEMPDIR}/camera-300s.mp4 exists"
    echo "Testing ffmpeg successful"
    echo "TESTS SUCCESSFUL"
    sudo docker container stop ${AV_CONTAINER_NAME} > /dev/null 2> /dev/null  || true
    exit 0
fi
