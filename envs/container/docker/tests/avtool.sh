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
    echo -e "/t-a/t Sets AV Tool action {install, deploy, undeploy, start, stop, status, test}"
    echo -e "/t-c /t Sets the AV Tool configuration file"
    echo
    echo "Example:"
    echo -e "/tbash ./avtool.sh -a install "
    echo -e "/tbash ./avtool.sh -a start -c avtool.env"
    
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

if [[ "${action}" == "install" ]] ; then
    echo "Installing pre-requisites for all containers"
    cd ../av-ffmpeg/alpine
    (./avtool.sh -a install)
    cd ../ubuntu
    (./avtool.sh -a install)
    cd ../../av-rtmp-source/alpine
    (./avtool.sh -a install)
    cd ../ubuntu
    (./avtool.sh -a install)
    cd ../../av-rtmp-sink/alpine
    (./avtool.sh -a install)
    cd ../ubuntu
    (./avtool.sh -a install)
    cd ../../av-rtmp-rtsp-sink/alpine
    (./avtool.sh -a install)
    cd ../ubuntu
    (./avtool.sh -a install)
    cd ../../tests     

    echo "Installation done"
    exit 0
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login..."
    docker login
    echo "Login done"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying all services..."
    cd ../av-ffmpeg/alpine
    (./avtool.sh -a deploy)
    (./avtool.sh -a stop)
    cd ../ubuntu
    (./avtool.sh -a deploy)
    (./avtool.sh -a stop)
    cd ../../av-rtmp-source/alpine
    (./avtool.sh -a deploy)
    (./avtool.sh -a stop)
    cd ../ubuntu
    (./avtool.sh -a deploy)
    (./avtool.sh -a stop)
    cd ../../av-rtmp-sink/alpine
    (./avtool.sh -a deploy)
    (./avtool.sh -a stop)
    cd ../ubuntu
    (./avtool.sh -a deploy)
    (./avtool.sh -a stop)
    cd ../../av-rtmp-rtsp-sink/alpine
    (./avtool.sh -a deploy)
    (./avtool.sh -a stop)
    cd ../ubuntu
    (./avtool.sh -a deploy)
    (./avtool.sh -a stop)
    cd ../../tests     
    echo "Deployment done"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying all services..."
    cd ../av-ffmpeg/alpine
    (./avtool.sh -a undeploy)
    cd ../ubuntu
    (./avtool.sh -a undeploy)
    cd ../../av-rtmp-source/alpine
    (./avtool.sh -a undeploy)
    cd ../ubuntu
    (./avtool.sh -a undeploy)
    cd ../../av-rtmp-sink/alpine
    (./avtool.sh -a undeploy)
    cd ../ubuntu
    (./avtool.sh -a undeploy)
    cd ../../av-rtmp-rtsp-sink/alpine
    (./avtool.sh -a undeploy)
    cd ../ubuntu
    (./avtool.sh -a undeploy)
    cd ../../tests     
    echo "Undeployment done"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Checking all status..."
    cd ../av-ffmpeg/alpine
    (./avtool.sh -a status)
    cd ../ubuntu
    (./avtool.sh -a status)
    cd ../../av-rtmp-source/alpine
    (./avtool.sh -a status)
    cd ../ubuntu
    (./avtool.sh -a status)
    cd ../../av-rtmp-sink/alpine
    (./avtool.sh -a status)
    cd ../ubuntu
    (./avtool.sh -a status)
    cd ../../av-rtmp-rtsp-sink/alpine
    (./avtool.sh -a status)
    cd ../ubuntu
    (./avtool.sh -a status)
    cd ../../tests     
    echo "Status done"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting all services..."
    cd ../av-ffmpeg/alpine
    (./avtool.sh -a start)
    cd ../ubuntu
    (./avtool.sh -a start)
    cd ../../av-rtmp-source/alpine
    (./avtool.sh -a start)
    cd ../ubuntu
    (./avtool.sh -a start)
    cd ../../av-rtmp-sink/alpine
    (./avtool.sh -a start)
    cd ../ubuntu
    (./avtool.sh -a start)
    cd ../../av-rtmp-rtsp-sink/alpine
    (./avtool.sh -a start)
    cd ../ubuntu
    (./avtool.sh -a start)
    cd ../../tests    
    echo "Start done"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping all services..."
    cd ../av-ffmpeg/alpine
    (./avtool.sh -a stop)
    cd ../ubuntu
    (./avtool.sh -a stop)
    cd ../../av-rtmp-source/alpine
    (./avtool.sh -a stop)
    cd ../ubuntu
    (./avtool.sh -a stop)
    cd ../../av-rtmp-sink/alpine
    (./avtool.sh -a stop)
    cd ../ubuntu
    (./avtool.sh -a stop)
    cd ../../av-rtmp-rtsp-sink/alpine
    (./avtool.sh -a stop)
    cd ../ubuntu
    (./avtool.sh -a stop)
    cd ../../tests    
    echo "Stop done"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    echo "Testing all the av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Running tests for $line"
        echo "***********************************************************"
        cd $line 
        bash ./avtool.sh -a test
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo "Tests for $line ran successfully" 
        else 
            echo "Tests for $line failed" 
        fi
        echo "***********************************************************"
        cd ../../tests
    done
    echo "Testing all the av-services SUCCESSFUL"
    exit 0
fi
