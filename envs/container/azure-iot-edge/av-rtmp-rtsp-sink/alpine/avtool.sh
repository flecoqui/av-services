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
# colors for formatting the ouput
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

checkError() {
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}An error occured exiting from the current bash${NC}"
        exit 1
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
if [[ ! $action == login && ! $action == install && ! $action == start && ! $action == stop && ! $action == deploy && ! $action == undeploy && ! $action == test &&  ! $action == status ]]; then
    echo "Required action is missing, values: login, install, deploy, undeploy, start, stop, test"
    usage
    exit 1
fi
RESOURCE_GROUP=av-rtmp-rtsp-lva-rg
RESOURCE_REGION=eastus2
AV_SERVICE=av-rtmp-rtsp-sink
AV_FLAVOR=alpine
AV_IMAGE_NAME=${AV_SERVICE}-${AV_FLAVOR} 
AV_IMAGE_FOLDER=av-services
AV_CONTAINER_NAME=${AV_SERVICE}-${AV_FLAVOR}-container
AV_EDGE_DEVICE=rtmp-rtsp-lva-device
AV_RTMP_PORT=1935
AV_RTMP_PATH=live/stream
AV_PREFIXNAME=rtmprtsplva
AV_VMNAME="$AV_PREFIXNAME"vm
AV_HOSTNAME="$AV_VMNAME"."$RESOURCE_REGION".cloudapp.azure.com
AV_CONTAINERNAME=avchunks
AV_LOGIN=avvmadmin
AV_PASSWORD={YourPassword}
AV_COMPANYNAME=contoso
AV_PORT_HLS=8080
AV_PORT_HTTP=80
AV_PORT_SSL=443
AV_PORT_RTMP=1935
AV_PORT_RTSP=8554
# Check if configuration file exists
if [[ ! -f "$repoRoot"/"$configuration_file" ]]; then
    cat > "$repoRoot"/"$configuration_file" << EOF
RESOURCE_GROUP=${RESOURCE_GROUP}
RESOURCE_REGION=${RESOURCE_REGION}
AV_IMAGE_NAME=${AV_IMAGE_NAME}
AV_IMAGE_FOLDER=${AV_IMAGE_FOLDER}
AV_CONTAINER_NAME=${AV_CONTAINER_NAME}
AV_EDGE_DEVICE=${AV_EDGE_DEVICE}
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
export $(grep RESOURCE_GROUP "$repoRoot"/"$configuration_file")
export $(grep RESOURCE_REGION "$repoRoot"/"$configuration_file")
export $(grep AV_IMAGE_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_IMAGE_FOLDER "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_EDGE_DEVICE "$repoRoot"/"$configuration_file")
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
    az config set extension.use_dynamic_install=yes_without_prompt
    echo "Installing ffmpeg"
    sudo apt-get -y update
    sudo apt-get -y install ffmpeg
    sudo apt-get -y install  jq
    # install the Azure IoT extension
    echo -e "Checking ${BLUE}azure-iot${NC} extension."
    az extension show -n azure-iot -o none &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}azure-iot${NC} extension not found. Installing ${BLUE}azure-iot${NC}."
        az extension add --name azure-iot &> /dev/null
        echo -e "${BLUE}azure-iot${NC} extension is now installed."
    else
        az extension update --name azure-iot &> /dev/null
        echo -e "${BLUE}azure-iot${NC} extension is up to date."														  
    fi
    echo "Downloading content"
    wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv
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
    echo "Deploying services..."
    az ad signed-in-user show --output table --query "{login:userPrincipalName}"
    az account show --output table --query  "{subscriptionId:id,tenantId:tenantId}"
    echo "Deploying IoT Hub and Azure Container Registry..."
    az group create -n ${RESOURCE_GROUP}  -l ${RESOURCE_REGION} 
    checkError
    az deployment group create -g ${RESOURCE_GROUP} -n "${RESOURCE_GROUP}dep" --template-file azuredeploy.iothub.json --parameters namePrefix=${AV_PREFIXNAME} --verbose -o json
    checkError
    
    RESOURCES=$(az resource list --resource-group "${RESOURCE_GROUP}" --query '[].{name:name,"Resource Type":type}' -o table)
    # capture resource configuration in variables
    IOTHUB=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.Devices\/IotHubs$/ {print $1}')
    IOTHUB_CONNECTION_STRING=$(az iot hub connection-string show --hub-name ${IOTHUB} --query='connectionString')
    CONTAINER_REGISTRY=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.ContainerRegistry\/registries$/ {print $1}')
    CONTAINER_REGISTRY_USERNAME=$(az acr credential show -n $CONTAINER_REGISTRY --query 'username' | tr -d \")
    CONTAINER_REGISTRY_PASSWORD=$(az acr credential show -n $CONTAINER_REGISTRY --query 'passwords[0].value' | tr -d \")

    # configure the hub for an edge device
    echo "Registering device..."
    if test -z "$(az iot hub device-identity list -n $IOTHUB | grep "deviceId" | grep $AV_EDGE_DEVICE)"; then
        az iot hub device-identity create --hub-name $IOTHUB --device-id $AV_EDGE_DEVICE --edge-enabled -o none
        checkError
    fi
    DEVICE_CONNECTION_STRING=$(az iot hub device-identity connection-string show --device-id $AV_EDGE_DEVICE --hub-name $IOTHUB --query='connectionString')
    DEVICE_CONNECTION_STRING=${DEVICE_CONNECTION_STRING//\//\\/} 
    CUSTOM_STRING=$(sed "s/{DEVICE_CONNECTION_STRING}/${DEVICE_CONNECTION_STRING//\"/}/g" < ./cloud-init.yml | sed "s/{AV_ADMIN}/${AV_LOGIN//\"/}/g" | sed "s/{AV_PORT_HTTP}/${AV_PORT_HTTP}/g" | sed "s/{AV_PORT_SSL}/${AV_PORT_SSL}/g" | sed "s/{AV_PORT_RTMP}/${AV_PORT_RTMP}/g" | sed "s/{AV_PORT_RTSP}/${AV_PORT_RTSP}/g" | sed "s/{AV_PORT_HLS}/${AV_PORT_HLS}/g" | base64 )

    echo "Deploying Virtual Machine..."
    az deployment group create -g ${RESOURCE_GROUP} -n "${RESOURCE_GROUP}dep" --template-file azuredeploy.vm.json --parameters namePrefix=${AV_PREFIXNAME} vmAdminUsername=${AV_LOGIN} vmAdminPassword=${AV_PASSWORD} rtmpPath=${AV_RTMP_PATH} containerName=${AV_CONTAINERNAME} customData="${CUSTOM_STRING}" portHTTP=${AV_PORT_HTTP} portSSL=${AV_PORT_SSL} portHLS=${AV_PORT_HLS} portRTMP=${AV_PORT_RTMP} portRTSP=${AV_PORT_RTSP} --verbose -o json
    checkError
    outputs=$(az deployment group show --name ${RESOURCE_GROUP}dep  -g ${RESOURCE_GROUP} --query properties.outputs)
    AV_STORAGENAME=$(jq -r .storageAccount.value <<< $outputs)
    AV_SASTOKEN=$(jq -r .storageSasToken.value <<< $outputs)
    sed -i "/AV_STORAGENAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_STORAGENAME=$AV_STORAGENAME" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_SASTOKEN=/d" "$repoRoot"/"$configuration_file"  ; echo "AV_SASTOKEN=$AV_SASTOKEN" >> "$repoRoot"/"$configuration_file"

    echo -e "\nResource group now contains these resources:"
    RESOURCES=$(az resource list --resource-group "${RESOURCE_GROUP}" --query '[].{name:name,"Resource Type":type}' -o table)
    echo "${RESOURCES}"
    VNET=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.Network\/virtualNetworks$/ {print $1}')
    CONTAINER_REGISTRY_DNS_NAME=$(az acr show -n "${CONTAINER_REGISTRY}" --query loginServer --output json)
    echo "IOTHUB=${IOTHUB}"
    echo "IOTHUB_CONNECTION_STRING=${IOTHUB_CONNECTION_STRING}"
    echo "CONTAINER_REGISTRY=${CONTAINER_REGISTRY}"
    echo "CONTAINER_REGISTRY_DNS_NAME=${CONTAINER_REGISTRY_DNS_NAME}"
    echo "CONTAINER_REGISTRY_USERNAME=${CONTAINER_REGISTRY_USERNAME}"
    echo "CONTAINER_REGISTRY_PASSWORD=${CONTAINER_REGISTRY_PASSWORD}"
    echo "DEVICE_CONNECTION_STRING=${DEVICE_CONNECTION_STRING}"

    echo "Building container image..."
    imageNameId=${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}':{{.Run.ID}}'
    imageTag='latest'
    latestImageName=${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}':'$imageTag

    az acr task create  --image "$imageNameId"   -n "${AV_CONTAINER_NAME}" -r "${CONTAINER_REGISTRY}" \
    --arg PORT_RTSP=${AV_PORT_RTSP} --arg  PORT_RTMP=${AV_PORT_RTMP} --arg  PORT_SSL=${AV_PORT_SSL}  \
     --arg  PORT_HTTP=${AV_PORT_HTTP} --arg  PORT_HLS=${AV_PORT_HLS} --arg  HOSTNAME=${AV_HOSTNAME} --arg  COMPANYNAME=${AV_COMPANYNAME} \
         -c "https://github.com/flecoqui/av-services.git#main:envs/container/docker/av-rtmp-rtsp-sink/alpine" -f "Dockerfile" \
         --commit-trigger-enabled false --base-image-trigger-enabled false 
    echo
    echo "Launching the task to build service: ${AV_CONTAINER_NAME}" 
    echo
    az acr task run  -n "${AV_CONTAINER_NAME}" -r "${CONTAINER_REGISTRY}"

    az iot edge set-modules --device-id [device id] --hub-name [hub name] --content [file path]

    echo
    echo "Preparing the deployment manifest: deployment.template.json" 
    echo
    sed -i "s/{CONTAINER_REGISTRY}/$CONTAINER_REGISTRY/" < ./deployment.rtmp.template.json >  ./deployment.template.json
    sed -i "s/{CONTAINER_REGISTRY_USERNAME}/$CONTAINER_REGISTRY_USERNAME/" ./deployment.template.json
    sed -i "s/{CONTAINER_REGISTRY_PASSWORD}/${CONTAINER_REGISTRY_PASSWORD//\//\\/}/" ./deployment.template.json
    sed -i "s/{CONTAINER_REGISTRY_DNS_NAME}/${CONTAINER_REGISTRY_DNS_NAME//\//\\/}/" ./deployment.template.json
    sed -i "s/{AV_IMAGE_NAME}/${AV_IMAGE_NAME}/" ./deployment.template.json
    sed -i "s/{AV_IMAGE_FOLDER}/${AV_IMAGE_FOLDER}/" ./deployment.template.json
    sed -i "s/{AV_PORT_HTTP}/$AV_PORT_HTTP/" ./deployment.template.json
    sed -i "s/{AV_PORT_SSL}/$AV_PORT_SSL/" ./deployment.template.json
    sed -i "s/{AV_PORT_RTMP}/$AV_PORT_RTMP/" ./deployment.template.json
    sed -i "s/{AV_PORT_RTSP}/$AV_PORT_RTSP/" ./deployment.template.json
    sed -i "s/{AV_PORT_HLS}/$AV_PORT_HLS/" ./deployment.template.json
    sed -i "s/{AV_HOSTNAME}/$AV_HOSTNAME/" ./deployment.template.json
    sed -i "s/{AV_COMPANYNAME}/$AV_COMPANYNAME/" ./deployment.template.json
    sed -i "s/{VIDEO_OUTPUT_FOLDER_ON_DEVICE}/\/var\/media/" ./deployment.template.json
    sed -i "s/{APPDATA_FOLDER_ON_DEVICE}/\/var\/lib\/azuremediaservices/" ./deployment.template.json
    cat ./deployment.template.json

    echo
    echo "Deploying modules on device ${AV_EDGE_DEVICE} in IoT Edge ${IOTHUB} " 
    echo
    az iot edge set-modules --device-id ${AV_EDGE_DEVICE} --hub-name ${IOTHUB} --content [file path]
    echo "Deployment done"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
    az ad signed-in-user show --output table --query "{login:userPrincipalName}"
    az account show --output table --query  "{subscriptionId:id,tenantId:tenantId}"
    az group delete -n ${RESOURCE_GROUP} --yes
    sed -i "/AV_STORAGENAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_STORAGENAME=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_SASTOKEN=/d" "$repoRoot"/"$configuration_file"  ; echo "AV_SASTOKEN=" >> "$repoRoot"/"$configuration_file"
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
if [[ "${action}" == "status" ]] ; then
    echo "Checking status..."
    az vm get-instance-view -n ${AV_VMNAME} -g ${RESOURCE_GROUP} --query instanceView.statuses[1].displayStatus --output json
    echo "Status done"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    rm -f "${AV_TEMPDIR}"/testrtmp*.mp4
    rm -f "${AV_TEMPDIR}"/testhls*.mp4
    rm -f "${AV_TEMPDIR}"/testrtsp*.mp4
    rm -f "${AV_TEMPDIR}"/testazure.xml   
    cmd="az storage blob delete-batch -s ${AV_CONTAINERNAME} --account-name ${AV_STORAGENAME} --pattern *.mp4 --sas-token \"${AV_SASTOKEN}\""
    eval "$cmd"
    echo "Testing service..."
    echo ""
    echo "Start RTMP Streaming..."
    echo ""
    echo "RTMP Streaming command: ffmpeg -nostats -loglevel 0 -re -stream_loop -1 -i ./camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH}"
    ffmpeg -nostats -loglevel 0 -re -stream_loop -1 -i ./camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH} &
    #jobs
    echo ""
    echo " Wait 30 seconds before consuming the outputs..."
    echo ""
    sleep 30

    echo ""
    echo "Testing output RTMP..."
    echo ""
    echo "Output RTMP: rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH}"
    echo "RTMP Command: ffmpeg -nostats -loglevel 0 -i rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH} -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4  "
    ffmpeg -nostats -loglevel 0 -i rtmp://${AV_HOSTNAME}:${AV_RTMP_PORT}/${AV_RTMP_PATH} -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4  || true
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
    sleep 120
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
    echo "TESTS SUCCESSFUL"
    exit 0
fi