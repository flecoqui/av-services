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
    echo "???: $# "
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
getPublicIPAddress() {
    getPublicIPAddressResult=$(dig +short myip.opendns.com @resolver1.opendns.com)
}
checkLoginAndSubscription() {
    az account show -o none
    if [ $? -ne 0 ]; then
        echo -e "\nYou seems disconnected from Azure, running 'az login'."
        az login -o none
    fi
    CURRENT_SUBSCRIPTION_ID=$(az account show --query 'id' --output tsv)
    if [[ -z "$AV_SUBSCRIPTION_ID"  || "$AV_SUBSCRIPTION_ID" != "$CURRENT_SUBSCRIPTION_ID" ]]; then
        # query subscriptions
        echo -e "\nYou have access to the following subscriptions:"
        az account list --query '[].{name:name,"subscription Id":id}' --output table

        echo -e "\nYour current subscription is:"
        az account show --query '[name,id]'

        if [[ ${silentmode} == false ||  -z "$CURRENT_SUBSCRIPTION_ID" ]]; then
            echo -e "
            You will need to use a subscription with permissions for creating service principals (owner role provides this).
            If you want to change to a different subscription, enter the name or id.
            Or just press enter to continue with the current subscription."
            read -p ">> " SUBSCRIPTION_ID

            if ! test -z "$SUBSCRIPTION_ID"
            then 
                az account set -s "$SUBSCRIPTION_ID"
                echo -e "\nNow using:"
                az account show --query '[name,id]'
                CURRENT_SUBSCRIPTION_ID=$(az account show --query 'id' --output tsv)
            fi
        fi
        AV_SUBSCRIPTION_ID="$CURRENT_SUBSCRIPTION_ID"
        sed -i "/AV_SUBSCRIPTION_ID=/d" "$repoRoot"/"$configuration_file"; echo "AV_SUBSCRIPTION_ID=$AV_SUBSCRIPTION_ID" >> "$repoRoot"/"$configuration_file" 
    fi
}
test_output_files () {
    test_output_files_result="1"
    prefix="$1"
    for i in 0 1 2 3
    do
        echo "checking file: ${AV_TEMPDIR}/${prefix}${i}.mp4 size: $(wc -c ${AV_TEMPDIR}/${prefix}${i}.mp4 | awk '{print $1}')"
        if [[ ! -f "${AV_TEMPDIR}"/${prefix}${i}.mp4 || $(wc -c "${AV_TEMPDIR}"/${prefix}${i}.mp4 | awk '{print $1}') < 10000 ]]; then 
            test_output_files_result="0"
            return
        fi
    done 
    return
}

AV_RESOURCE_GROUP=av-rtmp-rtsp-hls-vm-rg
AV_RESOURCE_REGION=eastus2
AV_RTMP_PORT=1935
AV_RTMP_PATH=live/stream
AV_PREFIXNAME="rtmprtsphls$(shuf -i 1000-9999 -n 1)"
AV_VMNAME="$AV_PREFIXNAME"vm
AV_HOSTNAME="$AV_VMNAME"."$AV_RESOURCE_REGION".cloudapp.azure.com
AV_CONTAINERNAME=avchunks
AV_LOGIN=avvmadmin
AV_PASSWORD={YourPassword}
AV_TEMPDIR=$(mktemp -d)
ssh-keygen -t rsa -b 2048 -f ${AV_TEMPDIR}/outkey -q -P ""
AV_AUTHENTICATION_TYPE="sshPublicKey"
AV_SSH_PUBLIC_KEY="\"$(cat ${AV_TEMPDIR}/outkey.pub)\""
AV_SSH_PRIVATE_KEY="\"$(cat ${AV_TEMPDIR}/outkey)\""

# Check if configuration file exists
if [[ ! -f "$repoRoot"/"$configuration_file" ]]; then
    cat > "$repoRoot"/"$configuration_file" << EOF
AV_RESOURCE_GROUP=${AV_RESOURCE_GROUP}
AV_RESOURCE_REGION=${AV_RESOURCE_REGION}
AV_RTMP_PORT=${AV_RTMP_PORT}
AV_RTMP_PATH=${AV_RTMP_PATH}
AV_PREFIXNAME=${AV_PREFIXNAME}
AV_VMNAME=${AV_VMNAME}
AV_HOSTNAME=${AV_HOSTNAME}
AV_CONTAINERNAME=${AV_CONTAINERNAME}
AV_LOGIN=${AV_LOGIN}
AV_PASSWORD=${AV_PASSWORD}
AV_SASTOKEN=
AV_STORAGENAME=
AV_SUBSCRIPTION_ID=
AV_TEMPDIR=${AV_TEMPDIR}
AV_AUTHENTICATION_TYPE=${AV_AUTHENTICATION_TYPE}
AV_SSH_PUBLIC_KEY=${AV_SSH_PUBLIC_KEY}
AV_SSH_PRIVATE_KEY=${AV_SSH_PRIVATE_KEY}
EOF
fi
# Read variables in configuration file
export $(grep AV_RESOURCE_GROUP "$repoRoot"/"$configuration_file")
export $(grep AV_RESOURCE_REGION "$repoRoot"/"$configuration_file")
export $(grep AV_RTMP_PORT "$repoRoot"/"$configuration_file")
export $(grep AV_RTMP_PATH "$repoRoot"/"$configuration_file")
export $(grep AV_PREFIXNAME "$repoRoot"/"$configuration_file")
export $(grep AV_VMNAME "$repoRoot"/"$configuration_file")
export $(grep AV_HOSTNAME "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINERNAME "$repoRoot"/"$configuration_file")
export $(grep AV_STORAGENAME "$repoRoot"/"$configuration_file")
export $(grep AV_SASTOKEN "$repoRoot"/"$configuration_file")
export $(grep AV_LOGIN "$repoRoot"/"$configuration_file"  )
export $(grep AV_PASSWORD "$repoRoot"/"$configuration_file" )
export $(grep AV_SUBSCRIPTION_ID "$repoRoot"/"$configuration_file" )
export $(grep AV_TEMPDIR "$repoRoot"/"$configuration_file" |  { read test; if [[ -z $test ]] ; then AV_TEMPDIR=$(mktemp -d) ; echo "AV_TEMPDIR=$AV_TEMPDIR" ; echo "AV_TEMPDIR=$AV_TEMPDIR" >> .avtoolconfig ; else echo $test; fi } )
export $(grep AV_AUTHENTICATION_TYPE "$repoRoot"/"$configuration_file")
export "$(grep AV_SSH_PUBLIC_KEY $repoRoot/$configuration_file)"
export "$(grep AV_SSH_PRIVATE_KEY $repoRoot/$configuration_file)"

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
    sudo apt-get -y install  jq
    if [ ! -f "${AV_TEMPDIR}"/camera-300s.mkv ]; then
        echo "Downloading content"
        wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv -O "${AV_TEMPDIR}"/camera-300s.mkv     
    fi
    echo -e "${GREEN}Installing pre-requisites done${NC}"
    exit 0
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login..."
    az login
    checkLoginAndSubscription
    echo -e "${GREEN}Login done${NC}"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying service..."
    checkLoginAndSubscription
    az group create -n ${AV_RESOURCE_GROUP}  -l ${AV_RESOURCE_REGION} 
    getPublicIPAddress || true
    cmd="az deployment group create -g ${AV_RESOURCE_GROUP} -n \"${AV_RESOURCE_GROUP}dep\" --template-file azuredeploy.json --parameters namePrefix=${AV_PREFIXNAME} vmAdminUsername=${AV_LOGIN} authenticationType=${AV_AUTHENTICATION_TYPE} vmAdminPasswordOrKey=${AV_SSH_PUBLIC_KEY} clientIPAddress="$getPublicIPAddressResult" rtmpPath=${AV_RTMP_PATH} containerName=${AV_CONTAINERNAME} --verbose -o json"
    echo "${cmd}"
    eval "${cmd}"
    checkError
    outputs=$(az deployment group show --name ${AV_RESOURCE_GROUP}dep  -g ${AV_RESOURCE_GROUP} --query properties.outputs)
    AV_STORAGENAME=$(jq -r .storageAccount.value <<< $outputs)
    AV_SASTOKEN=$(jq -r .storageSasToken.value <<< $outputs)
    sed -i "/AV_STORAGENAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_STORAGENAME=$AV_STORAGENAME" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_SASTOKEN=/d" "$repoRoot"/"$configuration_file"  ; echo "AV_SASTOKEN=$AV_SASTOKEN" >> "$repoRoot"/"$configuration_file"
    echo -e "${GREEN}Deployment done${NC}"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
    checkLoginAndSubscription
    az group delete -n ${AV_RESOURCE_GROUP} --yes
    checkError
    sed -i "/AV_STORAGENAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_STORAGENAME=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_SASTOKEN=/d" "$repoRoot"/"$configuration_file"  ; echo "AV_SASTOKEN=" >> "$repoRoot"/"$configuration_file"
    echo -e "${GREEN}Undeployment done${NC}"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting service..."
    checkLoginAndSubscription
    az vm start -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} >  /dev/null 2> /dev/null  || true
    checkError 
    echo -e "${GREEN}Virtual Machine started${NC}"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping service..."
    checkLoginAndSubscription
    az vm stop -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} >  /dev/null 2> /dev/null  || true
    checkError
    az vm deallocate -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} >  /dev/null 2> /dev/null  || true
    checkError 
    echo -e "${GREEN}Virtual Machine stopped${NC}"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Checking status..."
    checkLoginAndSubscription
    az vm get-instance-view -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} --query instanceView.statuses[1].displayStatus --output json
    echo -e "${GREEN}Virtual Machine status done${NC}"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    checkLoginAndSubscription
    rm -f "${AV_TEMPDIR}"/testrtmp*.mp4
    rm -f "${AV_TEMPDIR}"/testhls*.mp4
    rm -f "${AV_TEMPDIR}"/testrtsp*.mp4
    rm -f "${AV_TEMPDIR}"/testazure.xml   
    if [ ! -f "${AV_TEMPDIR}"/camera-300s.mkv ]; then
        echo "Downloading content"
        wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv -O "${AV_TEMPDIR}"/camera-300s.mkv     
    fi
    echo "Testing service..."
    echo "Stop and start virtual machine ${AV_VMNAME}"
    az vm stop -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} >  /dev/null 2> /dev/null  || true
    az vm start -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} >  /dev/null 2> /dev/null  || true
    cmd="az storage blob delete-batch -s ${AV_CONTAINERNAME} --account-name ${AV_STORAGENAME} --pattern *.mp4 --sas-token \"${AV_SASTOKEN}\""
    eval "$cmd"
    echo ""
    echo " Wait 30 seconds before starting to stream..."
    echo ""
    sleep 30
    echo ""
    echo "Start RTMP Streaming..."
    echo ""
    echo "RTMP Streaming command: ffmpeg -nostats -loglevel 0 -re -stream_loop -1 -i "${AV_TEMPDIR}"/camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH}"
    ffmpeg -nostats -loglevel 0 -re -stream_loop -1 -i "${AV_TEMPDIR}"/camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH} &
    checkError 
    #jobs
    echo ""
    echo " Wait 30 seconds before consuming the outputs..."
    echo ""
    sleep 30

    echo ""
    echo "Testing output RTMP..."
    echo ""
    echo "Output RTMP: rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH}"
    echo "RTMP Command: ffmpeg -nostats -loglevel 0 -rw_timeout 20000000 -i rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH} -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4  "
    ffmpeg -nostats -loglevel 0 -rw_timeout 20000000 -i rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH} -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4  || true
    test_output_files testrtmp || true
    if [[ "$test_output_files_result" == "0" ]] ; then
        echo "RTMP Test failed - check files testrtmpx.mp4"
        kill %1
        exit 0
    fi
    echo "Testing output RTMP successful"
    
    echo ""
    echo "Testing output HLS..."
    echo ""
    echo "Output HLS:  http://${AV_HOSTNAME}:8080/live/stream.m3u8"
    echo "HLS Command: ffmpeg -nostats -loglevel 0 -i http://${AV_HOSTNAME}:8080/live/stream.m3u8 -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testhls%d.mp4 "
    ffmpeg -nostats -loglevel 0 -i http://${AV_HOSTNAME}:8080/live/stream.m3u8 -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testhls%d.mp4  || true
    test_output_files testhls || true
    if [[ "$test_output_files_result" == "0" ]] ; then
        echo "HLS Test failed - check files testhlsx.mp4"
        kill %1
        exit 0
    fi
    echo "Testing output HLS successful"

    echo ""
    echo "Testing output RTSP..."
    echo ""
    echo "Output RTSP: rtsp://${AV_HOSTNAME}:8554/rtsp/stream"
    echo "RTSP Command: ffmpeg -nostats -loglevel 0 -rtsp_transport tcp  -i rtsp://${AV_HOSTNAME}:8554/rtsp/stream -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20 -reset_timestamps 1 "${AV_TEMPDIR}"/testrtsp%d.mp4"
    ffmpeg -nostats -loglevel 0 -rtsp_transport tcp  -i rtsp://${AV_HOSTNAME}:8554/rtsp/stream -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20 -reset_timestamps 1 "${AV_TEMPDIR}"/testrtsp%d.mp4 || true
    test_output_files testrtsp || true
    if [[ "$test_output_files_result" == "0" ]] ; then
        echo "RTSP Test failed - check files testrtsp.mp4"
        kill %1
        exit 0
    fi
    echo "Testing output RTSP successful"

    echo ""
    echo "Testing output on Azure Storage..."    
    echo ""
    echo "Azure Storage URL: https://${AV_STORAGENAME}.blob.core.windows.net/${AV_CONTAINERNAME}?${AV_SASTOKEN}&comp=list&restype=container"
    # wait 120 seconds to be sure the first chunks are copied on Azure Storage
    echo ""
    echo " Wait 180 seconds  to be sure the first chunks are copied on Azure Storage..."
    echo ""    
    sleep 180
    wget --quiet -O "${AV_TEMPDIR}"/testazure.xml "https://${AV_STORAGENAME}.blob.core.windows.net/${AV_CONTAINERNAME}?${AV_SASTOKEN}&comp=list&restype=container"
    blobs=($(grep -oP '(?<=Name>)[^<]+' "${AV_TEMPDIR}/testazure.xml"))
    bloblens=($(grep -oP '(?<=Content-Length>)[^<]+' "${AV_TEMPDIR}/testazure.xml"))

    teststorage=0
    for i in ${!blobs[*]}
    do
        echo "File: ${blobs[$i]} size: ${bloblens[$i]}"
        teststorage=1
    done
    if [[ "$teststorage" == "0" ]] ; then
        echo "Azure Storage Test failed - check files https://${AV_STORAGENAME}.blob.core.windows.net/${AV_CONTAINERNAME}?${AV_SASTOKEN}&comp=list&restype=container"
        kill %1
        exit 0
    fi
    echo "Testing output on Azure Storage successful"
    #jobs
    kill %1
    echo -e "${GREEN}TESTS SUCCESSFUL${NC}"
    exit 0
fi
