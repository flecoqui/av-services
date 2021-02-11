#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script used to install pre-requisites, deploy/undeploy service, start/stop service, test service
#- Parameters are:
#- [-a] action - value: login, install, deploy, undeploy, start, stop, test
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
test_output_files () {
    test_output_files_result="1"
    prefix="$1"
    for i in 0 1 2 3
    do
        echo "checking file: ${prefix}${i}.mp4 size: $(wc -c ${prefix}${i}.mp4 | awk '{print $1}')"
        if [[ ! -f ${prefix}${i}.mp4 || $(wc -c ${prefix}${i}.mp4 | awk '{print $1}') < 10000 ]]; then 
            test_output_files_result="0"
            return
        fi
    done 
    return
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
if [[ ! $action == login && ! $action == install && ! $action == start && ! $action == stop && ! $action == deploy && ! $action == undeploy && ! $action == test ]]; then
    echo "Required action is missing, values: login, install, deploy, undeploy, start, stop, test"
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
AV_LOGIN=vmadmin
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
    wget https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv
    exit 0
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login..."
    az login
    az ad signed-in-user show --output table --query "{login:userPrincipalName}"
    az account show --output table --query  "{subscriptionId:id,tenantId:tenantId}"
    echo "Login done"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying service..."
    az ad signed-in-user show --output table --query "{login:userPrincipalName}"
    az account show --output table --query  "{subscriptionId:id,tenantId:tenantId}"
    az group create -n ${RESOURCE_GROUP} -l ${RESOURCE_REGION}
    az deployment group create -g ${RESOURCE_GROUP} -n ${RESOURCE_GROUP}dep --template-file azuredeploy.json --parameters namePrefix=${AV_PREFIXNAME} vmAdminUsername=${AV_LOGIN} vmAdminPassword=${AV_PASSWORD} rtmpPath=${AV_RTMP_PATH} containerName=${AV_CONTAINERNAME} --verbose -o json
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
    az vm start -n ${AV_VMNAME} -g ${RESOURCE_GROUP} 
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
    rm -f testrtmp*.mp4
    rm -f testhls*.mp4
    rm -f testrtsp*.mp4
    rm -f testazure.xml   
    az storage blob delete-batch -s ${AV_CONTAINERNAME} --account-name rtmprtsp3ahnc4mybfacssa --pattern *.mp4 
    echo "Testing service..."
    echo "RTMP Streaming command: ffmpeg -nostats -loglevel 0 -re -stream_loop -1 -i ./camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH}"
    ffmpeg -nostats -loglevel 0 -re -stream_loop -1 -i ./camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH} &
    #jobs
    sleep 10
    echo "Testing chunks on Azure Storage..."
    
    wget -O testazure.xml "https://rtmprtsp3ahnc4mybfacssa.blob.core.windows.net/avchunks?sv=2015-04-05&ss=b&srt=sco&sp=rwdlac&st=2020-01-01T00%3A00%3A01.0000000Z&se=2030-01-01T00%3A00%3A01.0000000Z&spr=https&sig=YhxotWahYYTKVfLxP93f8WWWQrZYDtrEj063Fui0Ot8%3D&comp=list&restype=container"
    blobs=($(grep -oP '(?<=Name>)[^<]+' "./testazure.xml"))

    for i in ${!blobs[*]}
    do
    echo "$i" "${blobs[$i]}"
    # instead of echo use the values to send emails, etc
    done

    echo "Testing output RTMP..."
    echo "Output RTMP: rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH}"
    ffmpeg -nostats -loglevel 0 -i rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH} -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 testrtmp%d.mp4  || true
    test_output_files testrtmp || true
    if [[ "$test_output_files_result" == "0" ]] ; then
        echo "RTMP Test failed - check files testrtmpx.mp4"
        kill %1
        exit 0
    fi
    echo "Testing output RTMP successful"
    
    echo "Testing output HLS..."
    echo "Output HLS:  http://${AV_HOSTNAME}:8080/hls/stream.m3u8"
    ffmpeg -nostats -loglevel 0 -i http://${AV_HOSTNAME}:8080/hls/stream.m3u8 -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 testhls%d.mp4  || true
    test_output_files testhls || true
    if [[ "$test_output_files_result" == "0" ]] ; then
        echo "HLS Test failed - check files testhlsx.mp4"
        kill %1
        exit 0
    fi
    echo "Testing output HLS successful"

    echo "Testing output RTSP..."
    echo "Output RTSP: rtsp://${AV_HOSTNAME}:8554/test"
    ffmpeg -nostats -loglevel 0 -rtsp_transport tcp  -i rtsp://${AV_HOSTNAME}:8554/test -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20 -reset_timestamps 1 testrtsp%d.mp4 || true
    test_output_files testrtsp || true
    if [[ "$test_output_files_result" == "0" ]] ; then
        echo "RTSP Test failed - check files testrtsp.mp4"
        kill %1
        exit 0
    fi
    #jobs
    kill %1
    echo "TESTS SUCCESSFUL"
    exit 0
fi