#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script used to install pre-requisites, deploy/undeploy service, start/stop service, test service
#- Parameters are:
#- [-a] action - value: install, deploy, undeploy, start, stop, test
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
    echo -e "\t-a\t Sets AV Tool action"
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
if [[ ! $action == install && ! $action == start && ! $action == stop && ! $action == deploy && ! $action == undeploy && ! $action == test ]]; then
    echo "Required action is missing, values: install, deploy, undeploy, start, stop, test"
    usage
    exit 1
fi
RESOURCE_GROUP=av-rtmp-rtsp-hls-vm-rg
RESOURCE_REGION=eastus2
AV_RTMP_PORT=1935
AV_RTMP_PATH=live/stream
AV_PREFIXNAME=rtmprtsphls
AV_VMNAME="$AV_PREFIXNAME"vm
AV_HOSTNAME="$AV_VMNAME"."$RESOURCE_REGION".cloudapp.azure.com
AV_CONTAINERNAME=avchunks
AV_LOGIN=vmadmn
AV_PASSWORD=P@ssw0rd!
# Check if configuration file exists
if [[ ! -f "$repoRoot"/"$configuration_file" ]]; then
    cat > "$repoRoot"/"$configuration_file" << EOF
RESOURCE_GROUP=${RESOURCE_GROUP}
RESOURCE_REGION=${RESOURCE_REGION}
AV_RTMP_PORT=${AV_RTMP_PORT}
AV_RTMP_PATH=${AV_RTMP_PATH}
AV_PREFIXNAME=${AV_PREFIXNAME}
AV_VMNAME=${AV_VMNAME}
AV_HOSTNAME=${AV_HOSTNAME}
AV_CONTAINERNAME=${AV_CONTAINERNAME}
AV_LOGIN=${AV_LOGIN}
AV_PASSWORD=${AV_PASSWORD}
EOF
fi
# Read variables in configuration file
export $(grep RESOURCE_GROUP "$repoRoot"/"$configuration_file")
export $(grep RESOURCE_REGION "$repoRoot"/"$configuration_file")
export $(grep AV_RTMP_PORT "$repoRoot"/"$configuration_file")
export $(grep AV_RTMP_PATH "$repoRoot"/"$configuration_file")
export $(grep AV_PREFIXNAME "$repoRoot"/"$configuration_file")
export $(grep AV_VMNAME "$repoRoot"/"$configuration_file")
export $(grep AV_HOSTNAME "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINERNAME "$repoRoot"/"$configuration_file")
export $(grep AV_LOGIN "$repoRoot"/"$configuration_file")
export $(grep AV_PASSWORD "$repoRoot"/"$configuration_file")


if [[ "${action}" == "install" ]] ; then
    echo "Installing pre-requisite"
    echo "Installing azure cli"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    echo "Installing ffmpeg"
    sudo apt-get -y update
    sudo apt-get -y install ffmpeg
    echo "Downloading content"
    wget https://github.com/flecoqui/av-services/blob/main/content/camera-300s.mkv
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying service..."
    az ad signed-in-user show --output table --query "{login:userPrincipalName}"
    az account show --output table --query  "{subscriptionId:id,tenantId:tenantId}"
    az group create -n ${RESOURCE_GROUP} -l ${RESOURCE_REGION}
    az group deployment create -g ${RESOURCE_GROUP} -n ${RESOURCE_GROUP}dep --template-file azuredeploy.json --parameters namePrefix=${AV_PREFIXNAME} vmAdminUsername=${} vmAdminPassword=${} rtmpPath=${AV_RTMP_PATH} containerName=${AV_CONTAINERNAME} --verbose -o json
    echo "Deployment done"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
    az ad signed-in-user show --output table --query "{login:userPrincipalName}"
    az account show --output table --query  "{subscriptionId:id,tenantId:tenantId}"
    az group delete -n ${RESOURCE_GROUP} --yes
    echo "Undeployment done"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting service..."
    az ad signed-in-user show --output table --query "{login:userPrincipalName}"
    az account show --output table --query  "{subscriptionId:id,tenantId:tenantId}"
    az vm stop -n ${AV_VMNAME} -g ${RESOURCE_GROUP} 
    echo "Start done"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping service..."
    az ad signed-in-user show --output table --query "{login:userPrincipalName}"
    az account show --output table --query  "{subscriptionId:id,tenantId:tenantId}"
    az vm stop -n ${AV_VMNAME} -g ${RESOURCE_GROUP} 
    az vm deallocate -n ${AV_VMNAME} -g ${RESOURCE_GROUP} 
    echo "Stop done"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    echo "Testing service..."
    ffmpeg -v verbose  -re -stream_loop -1 -i ./camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH}
    echo "Test done"
    exit 0
fi
