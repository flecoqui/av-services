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
        if [[ ${silentmode} == false || -z "$CURRENT_SUBSCRIPTION_ID" ]]; then        
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
        AV_SUBSCRIPTION_ID=$CURRENT_SUBSCRIPTION_ID
        sed -i "/AV_SUBSCRIPTION_ID=/d" "$repoRoot"/"$configuration_file"; echo "AV_SUBSCRIPTION_ID=$AV_SUBSCRIPTION_ID" >> "$repoRoot"/"$configuration_file" 
    fi
}
checkOutputFiles () {
    checkOutputFilesResult="1"
    prefix="$1"
    for i in 0 1 
    do
        echo "checking file: ${AV_TEMPDIR}/${prefix}${i}.mp4 size: $(wc -c ${AV_TEMPDIR}/${prefix}${i}.mp4 | awk '{print $1}')"
        if [[ ! -f "${AV_TEMPDIR}"/${prefix}${i}.mp4 || $(wc -c "${AV_TEMPDIR}"/${prefix}${i}.mp4 | awk '{print $1}') < 10000 ]]; then 
            checkOutputFilesResult="0"
            return
        fi
    done 
    return
}
setContainerState () {
    state="$1"
    #az vm stop -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} 
    #az vm deallocate -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP}
    #az vm start -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} 
    #az iot hub invoke-module-method --method-name 'RestartModule' -n ${AV_IOTHUB}  -d ${AV_EDGE_DEVICE} -m '$edgeAgent' --method-payload '{"schemaVersion": "1.0","id": "rtmpsource"}'
    sed "s/{AV_STATE}/$state/g" < ./deployment.rtmp.amd64.json >  ./deployment.template.json
    sed -i "s/{AV_CONTAINER_REGISTRY}/$AV_CONTAINER_REGISTRY/" ./deployment.template.json
    sed -i "s/{AV_CONTAINER_REGISTRY_USERNAME}/$AV_CONTAINER_REGISTRY_USERNAME/" ./deployment.template.json
    sed -i "s/{AV_CONTAINER_REGISTRY_PASSWORD}/${AV_CONTAINER_REGISTRY_PASSWORD//\//\\/}/" ./deployment.template.json
    sed -i "s/{AV_CONTAINER_REGISTRY_DNS_NAME}/${AV_CONTAINER_REGISTRY_DNS_NAME//\//\\/}/g" ./deployment.template.json
    sed -i "s/{AV_IMAGE_NAME}/${AV_IMAGE_NAME}/g" ./deployment.template.json
    sed -i "s/{AV_IMAGE_FOLDER}/${AV_IMAGE_FOLDER}/g" ./deployment.template.json
    sed -i "s/{AV_PORT_HTTP}/$AV_PORT_HTTP/g" ./deployment.template.json
    sed -i "s/{AV_PORT_SSL}/$AV_PORT_SSL/g" ./deployment.template.json
    sed -i "s/{AV_PORT_RTMP}/$AV_PORT_RTMP/g" ./deployment.template.json
    sed -i "s/{AV_PORT_RTSP}/$AV_PORT_RTSP/g" ./deployment.template.json
    sed -i "s/{AV_PORT_HLS}/$AV_PORT_HLS/g" ./deployment.template.json
    sed -i "s/{AV_HOSTNAME}/$AV_HOSTNAME/g" ./deployment.template.json
    sed -i "s/{AV_COMPANYNAME}/$AV_COMPANYNAME/g" ./deployment.template.json
    sed -i "s/{AV_VIDEO_OUTPUT_FOLDER_ON_DEVICE}/\/var\/media/" ./deployment.template.json
    sed -i "s/{AV_APPDATA_FOLDER_ON_DEVICE}/\/var\/lib\/azuremediaservices/" ./deployment.template.json
    sed -i "s/{AV_SUBSCRIPTION_ID}/${AV_SUBSCRIPTION_ID//\//\\/}/g" ./deployment.template.json
    sed -i "s/{AV_RESOURCE_GROUP}/$AV_RESOURCE_GROUP/g" ./deployment.template.json
    sed -i "s/{AV_AMS_ACCOUNT}/${AV_AMS_ACCOUNT//\//\\/}/g" ./deployment.template.json
    sed -i "s/{AV_AAD_TENANT_ID}/${AV_AAD_TENANT_ID//\//\\/}/g" ./deployment.template.json
    sed -i "s/{AV_AAD_SERVICE_PRINCIPAL_ID}/${AV_AAD_SERVICE_PRINCIPAL_ID//\//\\/}/g" ./deployment.template.json
    sed -i "s/{AV_AAD_SERVICE_PRINCIPAL_SECRET}/${AV_AAD_SERVICE_PRINCIPAL_SECRET//\//\\/}/g" ./deployment.template.json
    az iot edge set-modules --device-id ${AV_EDGE_DEVICE} --hub-name ${AV_IOTHUB} --content ./deployment.template.json > /dev/null
    checkError
}
getContainerState () {
    getContainerStateResult="unknown"
    # az vm get-instance-view -n ${AV_VMNAME} -g ${AV_RESOURCE_GROUP} --query instanceView.statuses[1].displayStatus --output json
    getContainerStateResult=$(az iot hub query -n ${AV_IOTHUB} -q "select * from devices.modules where devices.deviceId = '${AV_EDGE_DEVICE}' and devices.moduleId = '\$edgeAgent' " --query '[].properties.reported.modules.rtmpsource.status'  --output tsv)
    checkError
    return
}
stopContainer() {
    setContainerState "stopped"
    echo "Stop command sent"
    x=1
    while : ; do 
        if [ $x -gt 10 ] ; then
            echo -e "${RED}\nAn error occured exiting from the current bash: Timeout while stopping the container${NC}"
            exit 1
        fi 
        getContainerState 
        if [[ $getContainerStateResult == "stopped" ]]; then echo "Container is stopped"; break; fi; 
        echo "Waiting for container in stopped state, currently it is $getContainerStateResult"; 
        sleep 10; 
        x=$(( $x + 1 ))
    done; 
}
startContainer() {
    setContainerState "running"
    echo "Start command sent"
    x=1
    while : ; do
        if [ $x -gt 10 ] ; then
            echo -e "${RED}\nAn error occured exiting from the current bash: Timeout while starting the container${NC}"
            exit 1
        fi 
        getContainerState 
        if [[ $getContainerStateResult == "running" ]]; then echo "Container is running"; break; fi; 
        echo "Waiting for container in running state, currently it is $getContainerStateResult"; 
        sleep 10; 
        x=$(( $x + 1 ))
    done; 
}
fillConfigurationFile() {
    sed -i "/AV_IOTHUB=/d" "$repoRoot"/"$configuration_file"; echo "AV_IOTHUB=$AV_IOTHUB" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_IOTHUB_CONNECTION_STRING=/d" "$repoRoot"/"$configuration_file"; echo "AV_IOTHUB_CONNECTION_STRING=$AV_IOTHUB_CONNECTION_STRING" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_DEVICE_CONNECTION_STRING=/d" "$repoRoot"/"$configuration_file"; echo "AV_DEVICE_CONNECTION_STRING=$AV_DEVICE_CONNECTION_STRING" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_CONTAINER_REGISTRY=/d" "$repoRoot"/"$configuration_file"; echo "AV_CONTAINER_REGISTRY=$AV_CONTAINER_REGISTRY" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_CONTAINER_REGISTRY_DNS_NAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_CONTAINER_REGISTRY_DNS_NAME=$AV_CONTAINER_REGISTRY_DNS_NAME" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_CONTAINER_REGISTRY_USERNAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_CONTAINER_REGISTRY_USERNAME=$AV_CONTAINER_REGISTRY_USERNAME" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_CONTAINER_REGISTRY_PASSWORD=/d" "$repoRoot"/"$configuration_file"; echo "AV_CONTAINER_REGISTRY_PASSWORD=$AV_CONTAINER_REGISTRY_PASSWORD" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_SUBSCRIPTION_ID=/d" "$repoRoot"/"$configuration_file"; echo "AV_SUBSCRIPTION_ID=$AV_SUBSCRIPTION_ID" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_AMS_ACCOUNT=/d" "$repoRoot"/"$configuration_file"; echo "AV_AMS_ACCOUNT=$AV_AMS_ACCOUNT" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_AAD_TENANT_ID=/d" "$repoRoot"/"$configuration_file"; echo "AV_AAD_TENANT_ID=$AV_AAD_TENANT_ID" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_AAD_SERVICE_PRINCIPAL_ID=/d" "$repoRoot"/"$configuration_file"; echo "AV_AAD_SERVICE_PRINCIPAL_ID=$AV_AAD_SERVICE_PRINCIPAL_ID" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_AAD_SERVICE_PRINCIPAL_SECRET=/d" "$repoRoot"/"$configuration_file"; echo "AV_AAD_SERVICE_PRINCIPAL_SECRET=$AV_AAD_SERVICE_PRINCIPAL_SECRET" >> "$repoRoot"/"$configuration_file" 
}
initializeConfigurationFile() {
    sed -i "/AV_STORAGENAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_STORAGENAME=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_SASTOKEN=/d" "$repoRoot"/"$configuration_file"  ; echo "AV_SASTOKEN=" >> "$repoRoot"/"$configuration_file"
    sed -i "/AV_IOTHUB=/d" "$repoRoot"/"$configuration_file"; echo "AV_IOTHUB=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_IOTHUB_CONNECTION_STRING=/d" "$repoRoot"/"$configuration_file"; echo "AV_IOTHUB_CONNECTION_STRING=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_DEVICE_CONNECTION_STRING=/d" "$repoRoot"/"$configuration_file"; echo "AV_DEVICE_CONNECTION_STRING=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_CONTAINER_REGISTRY=/d" "$repoRoot"/"$configuration_file"; echo "AV_CONTAINER_REGISTRY=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_CONTAINER_REGISTRY_DNS_NAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_CONTAINER_REGISTRY_DNS_NAME=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_CONTAINER_REGISTRY_USERNAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_CONTAINER_REGISTRY_USERNAME=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_CONTAINER_REGISTRY_PASSWORD=/d" "$repoRoot"/"$configuration_file"; echo "AV_CONTAINER_REGISTRY_PASSWORD=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_SUBSCRIPTION_ID=/d" "$repoRoot"/"$configuration_file"; echo "AV_SUBSCRIPTION_ID=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_AMS_ACCOUNT=/d" "$repoRoot"/"$configuration_file"; echo "AV_AMS_ACCOUNT=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_AAD_TENANT_ID=/d" "$repoRoot"/"$configuration_file"; echo "AV_AAD_TENANT_ID=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_AAD_SERVICE_PRINCIPAL_ID=/d" "$repoRoot"/"$configuration_file"; echo "AV_AAD_SERVICE_PRINCIPAL_ID=" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_AAD_SERVICE_PRINCIPAL_SECRET=/d" "$repoRoot"/"$configuration_file"; echo "AV_AAD_SERVICE_PRINCIPAL_SECRET=" >> "$repoRoot"/"$configuration_file" 
}



AV_RESOURCE_GROUP=av-rtmp-rtsp-lva-rg
AV_RESOURCE_REGION=eastus2
AV_SERVICE=av-rtmp-rtsp-sink
AV_FLAVOR=ubuntu
AV_IMAGE_NAME=${AV_SERVICE}-${AV_FLAVOR} 
AV_IMAGE_FOLDER=av-services
AV_CONTAINER_NAME=${AV_SERVICE}-${AV_FLAVOR}-container
AV_EDGE_DEVICE=rtmp-rtsp-lva-device
AV_PATH_RTMP=live/stream
AV_PREFIXNAME="rtmprtsplva$(shuf -i 1000-9999 -n 1)"
AV_VMNAME="$AV_PREFIXNAME"vm
AV_HOSTNAME="$AV_VMNAME"."$AV_RESOURCE_REGION".cloudapp.azure.com
AV_CONTAINERNAME=avchunks
AV_LOGIN=avvmadmin
AV_PASSWORD={YourPassword}
AV_COMPANYNAME=contoso
AV_PORT_HLS=8080
AV_PORT_HTTP=80
# use 8443 for SSL port to avoid conflict on IoT Edge with EdgeHub port
AV_PORT_SSL=8443
AV_PORT_RTMP=1935
AV_PORT_RTSP=8554
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
AV_SERVICE=${AV_SERVICE}
AV_IMAGE_NAME=${AV_IMAGE_NAME}
AV_IMAGE_FOLDER=${AV_IMAGE_FOLDER}
AV_CONTAINER_NAME=${AV_CONTAINER_NAME}
AV_EDGE_DEVICE=${AV_EDGE_DEVICE}
AV_PORT_RTMP=${AV_PORT_RTMP}
AV_PREFIXNAME=${AV_PREFIXNAME}
AV_VMNAME=${AV_VMNAME}
AV_HOSTNAME=${AV_HOSTNAME}
AV_CONTAINERNAME=${AV_CONTAINERNAME}
AV_STORAGENAME=
AV_SASTOKEN=
AV_LOGIN=${AV_LOGIN}
AV_PASSWORD=${AV_PASSWORD}
AV_COMPANYNAME=${AV_COMPANYNAME}
AV_PORT_HLS=${AV_PORT_HLS}
AV_PORT_HTTP=${AV_PORT_HTTP}
AV_PORT_SSL=${AV_PORT_SSL}
AV_PORT_RTMP=${AV_PORT_RTMP}
AV_PORT_RTSP=${AV_PORT_RTSP}
AV_IOTHUB=
AV_IOTHUB_CONNECTION_STRING=
AV_DEVICE_CONNECTION_STRING=
AV_CONTAINER_REGISTRY=
AV_CONTAINER_REGISTRY_DNS_NAME=
AV_CONTAINER_REGISTRY_USERNAME=
AV_CONTAINER_REGISTRY_PASSWORD=
AV_AMS_ACCOUNT=
AV_AAD_TENANT_ID=
AV_AAD_SERVICE_PRINCIPAL_ID=
AV_AAD_SERVICE_PRINCIPAL_SECRET=
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
export $(grep AV_IMAGE_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_IMAGE_FOLDER "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_EDGE_DEVICE "$repoRoot"/"$configuration_file")
export $(grep AV_PORT_RTMP "$repoRoot"/"$configuration_file")
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
export $(grep AV_IOTHUB "$repoRoot"/"$configuration_file")
export $(grep AV_IOTHUB_CONNECTION_STRING "$repoRoot"/"$configuration_file")
export $(grep AV_DEVICE_CONNECTION_STRING "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_REGISTRY "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_REGISTRY_DNS_NAME "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_REGISTRY_USERNAME "$repoRoot"/"$configuration_file")
export $(grep AV_CONTAINER_REGISTRY_PASSWORD "$repoRoot"/"$configuration_file")
export $(grep AV_AMS_ACCOUNT "$repoRoot"/"$configuration_file")
export $(grep AV_AAD_TENANT_ID "$repoRoot"/"$configuration_file")
export $(grep AV_AAD_SERVICE_PRINCIPAL_ID "$repoRoot"/"$configuration_file")
export $(grep AV_AAD_SERVICE_PRINCIPAL_SECRET "$repoRoot"/"$configuration_file")
export $(grep AV_SUBSCRIPTION_ID "$repoRoot"/"$configuration_file")
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
    az config set extension.use_dynamic_install=yes_without_prompt
    echo "Installing ffmpeg"
    sudo apt-get -y update
    sudo apt-get -y install ffmpeg
    sudo apt-get -y install  jq
    # install the Azure IoT extension
    echo -e "Checking azure-iot extension."
    az extension show -n azure-iot -o none &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "azure-iot extension not found. Installing azure-iot."
        az extension add --name azure-iot &> /dev/null
        echo -e "azure-iot extension is now installed."
    else
        az extension update --name azure-iot &> /dev/null
        echo -e "azure-iot extension is up to date."														  
    fi
    if [ ! -f "${AV_TEMPDIR}"/camera-300s.mkv ]; then
        echo "Downloading content"
        wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv -O "${AV_TEMPDIR}"/camera-300s.mkv     
    fi
    echo "Installing .Net 5.0 SDK "
    wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O "${AV_TEMPDIR}"/packages-microsoft-prod.deb
    sudo dpkg -i "${AV_TEMPDIR}"/packages-microsoft-prod.deb
    sudo apt-get update 
    sudo apt-get install -y apt-transport-https 
    sudo apt-get install -y dotnet-sdk-5.0
    sudo dotnet restore ../../../../../src/lvatool
    sudo dotnet build ../../../../../src/lvatool
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
    echo "Deploying services..."
    checkLoginAndSubscription
    echo "Deploying IoT Hub and Azure Container Registry..."
    az group create -n ${AV_RESOURCE_GROUP}  -l ${AV_RESOURCE_REGION} 
    checkError
    az deployment group create -g ${AV_RESOURCE_GROUP} -n "${AV_RESOURCE_GROUP}dep" --template-file azuredeploy.iothub.json --parameters namePrefix=${AV_PREFIXNAME} containerName=${AV_CONTAINERNAME}  iotHubSku="F1" -o json
    checkError
    outputs=$(az deployment group show --name ${AV_RESOURCE_GROUP}dep  -g ${AV_RESOURCE_GROUP} --query properties.outputs)
    AV_STORAGENAME=$(jq -r .storageAccount.value <<< $outputs)
    AV_SASTOKEN=$(jq -r .storageSasToken.value <<< $outputs)
    sed -i "/AV_STORAGENAME=/d" "$repoRoot"/"$configuration_file"; echo "AV_STORAGENAME=$AV_STORAGENAME" >> "$repoRoot"/"$configuration_file" 
    sed -i "/AV_SASTOKEN=/d" "$repoRoot"/"$configuration_file"  ; echo "AV_SASTOKEN=$AV_SASTOKEN" >> "$repoRoot"/"$configuration_file"

    # tempo waiting 
    sleep 60
    RESOURCES=$(az resource list --resource-group "${AV_RESOURCE_GROUP}" --query '[].{name:name,"Resource Type":type}' -o table)
    # capture resource configuration in variables
    AV_IOTHUB=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.Devices\/IotHubs$/ {print $1}')
    AV_IOTHUB_CONNECTION_STRING=$(az iot hub connection-string show --hub-name ${AV_IOTHUB} --query='connectionString')

    # SUB1="/"
    # SUB2="+"
    # while  [[ "$AV_IOTHUB_CONNECTION_STRING" == *"$SUB1"* ]] || [[ "$AV_IOTHUB_CONNECTION_STRING" == *"$SUB2"* ]]; do
    #     echo "Renewing IoT Hub connection string."
    #     az iot hub policy renew-key --hub-name ${AV_IOTHUB}  --name iothubowner --rk Primary > /dev/null
    #     checkError
    #     AV_IOTHUB_CONNECTION_STRING=$(az iot hub connection-string show --hub-name ${AV_IOTHUB} --query "connectionString" )
    #     checkError
    # done

    AV_AMS_ACCOUNT=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.Media\/mediaservices$/ {print $1}')
    AV_CONTAINER_REGISTRY=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.ContainerRegistry\/registries$/ {print $1}')
    AV_CONTAINER_REGISTRY_USERNAME=$(az acr credential show -n $AV_CONTAINER_REGISTRY --query 'username' | tr -d \")
    AV_CONTAINER_REGISTRY_PASSWORD=$(az acr credential show -n $AV_CONTAINER_REGISTRY --query 'passwords[0].value' | tr -d \")

    # configure the hub for an edge device
    echo "Registering device..."
    if test -z "$(az iot hub device-identity list -n $AV_IOTHUB | grep "deviceId" | grep $AV_EDGE_DEVICE)"; then
        az iot hub device-identity create --hub-name $AV_IOTHUB --device-id $AV_EDGE_DEVICE --edge-enabled -o none
        checkError
    fi
    AV_DEVICE_CONNECTION_STRING=$(az iot hub device-identity connection-string show --device-id $AV_EDGE_DEVICE --hub-name $AV_IOTHUB --query='connectionString')
    AV_DEVICE_CONNECTION_STRING=${AV_DEVICE_CONNECTION_STRING//\//\\/} 

    # creating the AMS account creates a service principal, so we'll just reset it to get the credentials
    echo "setting up service principal..."
    SPN="$AV_AMS_ACCOUNT-access-sp" # this is the default naming convention used by `az ams account sp`

    if test -z "$(az ad sp list --display-name $SPN --query="[].displayName" -o tsv)"; then
        AMS_CONNECTION=$(az ams account sp create -o yaml --resource-group $AV_RESOURCE_GROUP --account-name $AV_AMS_ACCOUNT)
    else
        AMS_CONNECTION=$(az ams account sp reset-credentials -o yaml --resource-group $AV_RESOURCE_GROUP --account-name $AV_AMS_ACCOUNT)
    fi

    # capture config information
    re="AadTenantId:\s([0-9a-z\-]*)"
    AV_AAD_TENANT_ID=$([[ "$AMS_CONNECTION" =~ $re ]] && echo ${BASH_REMATCH[1]})

    re="AadClientId:\s([0-9a-z\-]*)"
    AV_AAD_SERVICE_PRINCIPAL_ID=$([[ "$AMS_CONNECTION" =~ $re ]] && echo ${BASH_REMATCH[1]})

    re="AadSecret:\s([0-9a-z\-]*)"
    AV_AAD_SERVICE_PRINCIPAL_SECRET=$([[ "$AMS_CONNECTION" =~ $re ]] && echo ${BASH_REMATCH[1]})

    re="SubscriptionId:\s([0-9a-z\-]*)"
    SUBSCRIPTION_ID=$([[ "$AMS_CONNECTION" =~ $re ]] && echo ${BASH_REMATCH[1]})

    # capture object_id
    OBJECT_ID=$(az ad sp show --id ${AV_AAD_SERVICE_PRINCIPAL_ID} --query 'objectId' | tr -d \")

    sleep 60

    echo -e "
    Updating the Media Services account to use one Premium streaming endpoint."
    az ams streaming-endpoint scale --resource-group $AV_RESOURCE_GROUP --account-name $AV_AMS_ACCOUNT -n default --scale-units 1

    echo "Kicking off the async start of the Premium streaming endpoint."
    echo "  This is needed to run samples or tutorials involving video playback."
    az ams streaming-endpoint start --resource-group $AV_RESOURCE_GROUP --account-name $AV_AMS_ACCOUNT -n default --no-wait

    echo "Generating cloud-init.yml:"
    CUSTOM_STRING=$(sed "s/{DEVICE_CONNECTION_STRING}/${AV_DEVICE_CONNECTION_STRING//\"/}/g" < ./cloud-init.yml | sed "s/{AV_ADMIN}/${AV_LOGIN//\"/}/g" | sed "s/{AV_PORT_HTTP}/${AV_PORT_HTTP}/g" | sed "s/{AV_PORT_SSL}/${AV_PORT_SSL}/g" | sed "s/{AV_PORT_RTMP}/${AV_PORT_RTMP}/g" | sed "s/{AV_PORT_RTSP}/${AV_PORT_RTSP}/g" | sed "s/{AV_PORT_HLS}/${AV_PORT_HLS}/g" )
    echo "$CUSTOM_STRING"
    echo "Generating cloud-init.yml base64:"
    CUSTOM_STRING_BASE64=$(sed "s/{DEVICE_CONNECTION_STRING}/${AV_DEVICE_CONNECTION_STRING//\"/}/g" < ./cloud-init.yml | sed "s/{AV_ADMIN}/${AV_LOGIN//\"/}/g" | sed "s/{AV_PORT_HTTP}/${AV_PORT_HTTP}/g" | sed "s/{AV_PORT_SSL}/${AV_PORT_SSL}/g" | sed "s/{AV_PORT_RTMP}/${AV_PORT_RTMP}/g" | sed "s/{AV_PORT_RTSP}/${AV_PORT_RTSP}/g" | sed "s/{AV_PORT_HLS}/${AV_PORT_HLS}/g" | base64)
    echo "$CUSTOM_STRING_BASE64"

    echo "Deploying Virtual Machine..."
    cmd="az deployment group create -g ${AV_RESOURCE_GROUP} -n \"${AV_RESOURCE_GROUP}dep\" --template-file azuredeploy.vm.json --parameters namePrefix=${AV_PREFIXNAME} vmAdminUsername=${AV_LOGIN} authenticationType=${AV_AUTHENTICATION_TYPE} vmAdminPasswordOrKey=${AV_SSH_PUBLIC_KEY}  storageAccountName=${AV_STORAGENAME} customData=\"${CUSTOM_STRING_BASE64}\" portHTTP=${AV_PORT_HTTP} portSSL=${AV_PORT_SSL} portHLS=${AV_PORT_HLS} portRTMP=${AV_PORT_RTMP} portRTSP=${AV_PORT_RTSP}  -o json"
    echo "${cmd}"
    eval "${cmd}"
    #az deployment group create -g ${AV_RESOURCE_GROUP} -n "${AV_RESOURCE_GROUP}dep" --template-file azuredeploy.vm.json --parameters namePrefix=${AV_PREFIXNAME} vmAdminUsername=${AV_LOGIN} authenticationType=${AV_AUTHENTICATION_TYPE} vmAdminPasswordOrKey=${AV_SSH_PUBLIC_KEY}  storageAccountName=${AV_STORAGENAME} customData="${CUSTOM_STRING_BASE64}" portHTTP=${AV_PORT_HTTP} portSSL=${AV_PORT_SSL} portHLS=${AV_PORT_HLS} portRTMP=${AV_PORT_RTMP} portRTSP=${AV_PORT_RTSP}  -o json
    checkError
    
    echo -e "\nResource group now contains these resources:"
    RESOURCES=$(az resource list --resource-group "${AV_RESOURCE_GROUP}" --query '[].{name:name,"Resource Type":type}' -o table)
    echo "${RESOURCES}"
    VNET=$(echo "${RESOURCES}" | awk '$2 ~ /Microsoft.Network\/virtualNetworks$/ {print $1}')
    AV_CONTAINER_REGISTRY_DNS_NAME=$(az acr show -n "${AV_CONTAINER_REGISTRY}" --query loginServer --output tsv)

    echo "Building container image..."
    imageNameId=${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}':{{.Run.ID}}'
    imageTag='latest'
    latestImageName=${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}':'$imageTag

    az acr task create  --image "$imageNameId"   -n "${AV_CONTAINER_NAME}" -r "${AV_CONTAINER_REGISTRY}" \
    --arg AV_PORT_RTSP=${AV_PORT_RTSP} --arg  AV_PORT_RTMP=${AV_PORT_RTMP} --arg  AV_PORT_SSL=${AV_PORT_SSL}  \
     --arg  AV_PORT_HTTP=${AV_PORT_HTTP} --arg  AV_PORT_HLS=${AV_PORT_HLS} --arg  AV_HOSTNAME=${AV_HOSTNAME} --arg  AV_COMPANYNAME=${AV_COMPANYNAME} \
         -c "https://github.com/flecoqui/av-services.git#main:envs/container/docker/av-rtmp-rtsp-sink/ubuntu" -f "Dockerfile" \
         --commit-trigger-enabled false --base-image-trigger-enabled false 
    echo
    echo "Launching the task to build service: ${AV_CONTAINER_NAME}" 
    echo
    az acr task run  -n "${AV_CONTAINER_NAME}" -r "${AV_CONTAINER_REGISTRY}"
    tagIDwithQuotes=$(az acr task list-runs  --registry "${AV_CONTAINER_REGISTRY}" -n "${AV_CONTAINER_NAME}" --query [0].runId) 
    tagID=$(echo "$tagIDwithQuotes" | tr -d '"')
    echo "Build Image Run ID: $tagID"
    count=$(az acr task logs  -n "${AV_CONTAINER_NAME}" -r "${AV_CONTAINER_REGISTRY}"  | grep -c "Run ID: $tagID was successful after") || true
    if [[ $count = '1' ]]
    then
        echo "Image successfully built"
    else
        echo "Error while building the image"
        exit 1
    fi    
    az acr repository  show-tags --repository "${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}" --name "${AV_CONTAINER_REGISTRY}" | grep "latest"
    status=$?
    if [ $status -eq 0 ]; then
        az acr repository  untag  -n "${AV_CONTAINER_REGISTRY}" --image ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}:latest || true
    fi
    az acr  import  -n "${AV_CONTAINER_REGISTRY}" --source ${AV_CONTAINER_REGISTRY_DNS_NAME}/${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}:${tagID} --image ${AV_IMAGE_FOLDER}/${AV_IMAGE_NAME}:latest
    
    echo
    echo "Deploying modules on device ${AV_EDGE_DEVICE} in IoT Edge ${AV_IOTHUB} " 
    echo
    # Wait 1 minute before deploying containers 
    sleep 60    
    setContainerState "running"
    # Wait 1 minute to complete the deployment 
    sleep 60
    getContainerState 
    if [[ $getContainerStateResult != "running" ]]; then
        setContainerState "running"
        sleep 30
        getContainerState 
    fi    
    echo "Container state: $getContainerStateResult"        
    fillConfigurationFile

    echo -e "
Content of the .env file which can be used with the Azure IoT Tools in Visual Studio Code:    
    "
    # write .env file for edge deployment
    echo "SUBSCRIPTION_ID=\"$AV_SUBSCRIPTION_ID\"" > ./.env
    echo "RESOURCE_GROUP=\"$AV_RESOURCE_GROUP\"" >> ./.env
    echo "AMS_ACCOUNT=\"$AV_AMS_ACCOUNT\""  >> ./.env
    echo "IOTHUB_CONNECTION_STRING=$AV_IOTHUB_CONNECTION_STRING" >> ./.env
    echo "AAD_TENANT_ID=$AV_AAD_TENANT_ID"  >> ./.env
    echo "AAD_SERVICE_PRINCIPAL_ID=$AV_AAD_SERVICE_PRINCIPAL_ID"  >> ./.env
    echo "AAD_SERVICE_PRINCIPAL_SECRET=$AV_AAD_SERVICE_PRINCIPAL_SECRET"  >> ./.env
    echo "VIDEO_INPUT_FOLDER_ON_DEVICE=\"/home/lvaedgeuser/samples/input\""  >> ./.env
    echo "VIDEO_OUTPUT_FOLDER_ON_DEVICE=\"/var/media\""  >> ./.env
    echo "APPDATA_FOLDER_ON_DEVICE=\"/var/lib/azuremediaservices\""  >> ./.env
    echo "CONTAINER_REGISTRY_USERNAME_myacr=$AV_CONTAINER_REGISTRY_USERNAME" >> ./.env
    echo "CONTAINER_REGISTRY_PASSWORD_myacr=$AV_CONTAINER_REGISTRY_PASSWORD" >> ./.env
    cat ./.env

    echo -e "
Content of the appsettings.json file which can be used with the Azure IoT Tools in Visual Studio Code:    
    "
    # write appsettings for sample code
    echo "{" > ./appsettings.json
    echo "    \"IoThubConnectionString\" : $AV_IOTHUB_CONNECTION_STRING," >>  ./appsettings.json
    echo "    \"deviceId\" : \"$AV_EDGE_DEVICE\"," >>  ./appsettings.json
    echo "    \"moduleId\" : \"lvaEdge\"" >>  ./appsettings.json
    echo -n "}" >>  ./appsettings.json
    cat ./appsettings.json

    echo -e "

Content of operations.json file which can be used with the Azure Cloud To Device Console App:
    "
    # write operations.json for sample code
    sed "s/{PORT_RTSP}/${AV_PORT_RTSP}/g" < ./operations.template.json 
    echo -e "
Deployment parameters:    
    "
    echo "IOTHUB=${AV_IOTHUB}"
    echo "IOTHUB_CONNECTION_STRING=${AV_IOTHUB_CONNECTION_STRING}"
    echo "DEVICE_CONNECTION_STRING=${AV_DEVICE_CONNECTION_STRING}"
    echo "CONTAINER_REGISTRY=${AV_CONTAINER_REGISTRY}"
    echo "CONTAINER_REGISTRY_DNS_NAME=${AV_CONTAINER_REGISTRY_DNS_NAME}"
    echo "CONTAINER_REGISTRY_USERNAME=${AV_CONTAINER_REGISTRY_USERNAME}"
    echo "CONTAINER_REGISTRY_PASSWORD=${AV_CONTAINER_REGISTRY_PASSWORD}"
    echo "AV_HOSTNAME=${AV_HOSTNAME}"
    echo "SSH command: ssh ${AV_LOGIN}@${AV_HOSTNAME}"
    echo "RTMP URL: rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/live/stream"
    echo "RTSP URL: rtsp://${AV_HOSTNAME}:${AV_PORT_RTSP}/rtsp/stream"
    echo "HLS  URL: http://${AV_HOSTNAME}:${AV_PORT_HLS}/live/stream.m3u8"
    echo "HTTP URL: http://${AV_HOSTNAME}:${AV_PORT_HTTP}/player.html"
    echo "SSL  URL: https://${AV_HOSTNAME}:${AV_PORT_SSL}/player.html"
    echo -e "${GREEN}Deployment done${NC}"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service..."
    checkLoginAndSubscription
    az group delete -n ${AV_RESOURCE_GROUP} --yes
    initializeConfigurationFile
    echo -e "${GREEN}Undeployment done${NC}"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting service..."
    checkLoginAndSubscription
    startContainer
    echo -e "${GREEN}Container started${NC}"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping service..."
    checkLoginAndSubscription
    stopContainer
    echo -e "${GREEN}Container stopped${NC}"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Checking status..."
    checkLoginAndSubscription
    getContainerState 
    echo "$getContainerStateResult"
    echo -e "${GREEN}Container status done${NC}"
    exit 0
fi

if [[ "${action}" == "test" ]] ; then
    rm -f "${AV_TEMPDIR}"/testrtmp*.mp4
    rm -f "${AV_TEMPDIR}"/testhls*.mp4
    rm -f "${AV_TEMPDIR}"/testrtsp*.mp4
    if [ ! -f "${AV_TEMPDIR}"/camera-300s.mkv ]; then
        echo "Downloading content"
        wget --quiet https://github.com/flecoqui/av-services/raw/main/content/camera-300s.mkv -O "${AV_TEMPDIR}"/camera-300s.mkv     
    fi
    echo "Testing service..."
    stopContainer
    startContainer
    checkLoginAndSubscription
    echo ""
    echo "Start RTMP Streaming..."
    echo ""
    echo "RTMP Streaming command: ffmpeg -nostats -loglevel 0 -re -stream_loop -1 -i "${AV_TEMPDIR}"/camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/${AV_PATH_RTMP}"
    ffmpeg -nostats -loglevel 0 -re -stream_loop -1 -i "${AV_TEMPDIR}"/camera-300s.mkv -codec copy -bsf:v h264_mp4toannexb -f flv rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/${AV_PATH_RTMP} &
    #jobs
    echo ""
    echo " Wait 30 seconds before consuming the outputs..."
    echo ""
    sleep 30

    echo ""
    echo "Testing output RTMP..."
    echo ""
    echo "Output RTMP: rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/${AV_PATH_RTMP}"
    echo "RTMP Command: ffmpeg -nostats -loglevel 0 -re -rw_timeout 20000000 -i rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/${AV_PATH_RTMP} -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4  "
    ffmpeg -nostats -loglevel 0 -re -rw_timeout 20000000 -i rtmp://${AV_HOSTNAME}:${AV_PORT_RTMP}/${AV_PATH_RTMP} -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testrtmp%d.mp4  || true
    checkOutputFiles testrtmp || true
    if [[ "$checkOutputFilesResult" == "0" ]] ; then
        echo "RTMP Test failed - check files testrtmpx.mp4"
        kill %1
        exit 0
    fi
    echo "Testing output RTMP successful"
    
    echo ""
    echo "Testing output HLS..."
    echo ""
    echo "Output HLS:  http://${AV_HOSTNAME}:${AV_PORT_HLS}/live/stream.m3u8"
    echo "HLS Command: ffmpeg -nostats -loglevel 0  -i http://${AV_HOSTNAME}:${AV_PORT_HLS}/live/stream.m3u8 -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testhls%d.mp4 "
    ffmpeg -nostats -loglevel 0  -i http://${AV_HOSTNAME}:${AV_PORT_HLS}/live/stream.m3u8 -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20  -reset_timestamps 1 "${AV_TEMPDIR}"/testhls%d.mp4  || true
    checkOutputFiles testhls || true
    if [[ "$checkOutputFilesResult" == "0" ]] ; then
        echo "HLS Test failed - check files testhlsx.mp4"
        kill %1
        exit 0
    fi
    echo "Testing output HLS successful"

    echo ""
    echo "Testing output RTSP..."
    echo ""
    echo "Output RTSP: rtsp://${AV_HOSTNAME}:${AV_PORT_RTSP}/rtsp/stream"
    echo "RTSP Command: ffmpeg -nostats -loglevel 0 -rtsp_transport tcp  -i rtsp://${AV_HOSTNAME}:${AV_PORT_RTSP}/rtsp/stream -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20 -reset_timestamps 1 "${AV_TEMPDIR}"/testrtsp%d.mp4"
    ffmpeg -nostats -loglevel 0  -rtsp_transport tcp  -i rtsp://${AV_HOSTNAME}:${AV_PORT_RTSP}/rtsp/stream -c copy -flags +global_header -f segment -segment_time 5 -segment_format_options movflags=+faststart -t 00:00:20 -reset_timestamps 1 "${AV_TEMPDIR}"/testrtsp%d.mp4 || true
    checkOutputFiles testrtsp || true
    if [[ "$checkOutputFilesResult" == "0" ]] ; then
        echo "RTSP Test failed - check files testrtsp.mp4"
        kill %1
        exit 0
    fi
    echo "Testing output RTSP successful"

    echo ""
    echo "Testing LVA..."
    echo ""
    # write operations.json for sample code
    sed "s/{PORT_RTSP}/${AV_PORT_RTSP}/g" < ./operations.template.json > ./operations.json 
    cat ./operations.json 
    echo "Activating the LVA Graph"
    cmd="sudo dotnet run -p ../../../../../src/lvatool --runoperations --operationspath \"./operations.json\" --connectionstring $AV_IOTHUB_CONNECTION_STRING --device \"$AV_EDGE_DEVICE\"  --module lvaEdge --lastoperation GraphInstanceActivate"
    echo "$cmd"
    eval "$cmd"
    checkError

    echo "Receiving the LVA events during 60 seconds"
    cmd="sudo dotnet run -p ../../../../../src/lvatool --readevents --connectionstring $AV_IOTHUB_CONNECTION_STRING --timeout 60000"
    echo "$cmd"
    eval "$cmd" 2>&1 | tee events.txt
    checkError

    echo "Deactivating the LVA Graph"
    cmd="sudo dotnet run -p ../../../../../src/lvatool --runoperations --operationspath \"./operations.json\" --connectionstring $AV_IOTHUB_CONNECTION_STRING --device \"$AV_EDGE_DEVICE\"  --module lvaEdge --firstoperation GraphInstanceDeactivate"
    echo "$cmd"
    eval "$cmd"
    checkError

    grep -i '"type": "motion"' events.txt &> /dev/null
    status=$?
    if [ $status -ne 0 ]; then
        echo "LVA Test Failed to detect motion events in the results file"
        kill %1
        exit $status
    fi

    #jobs
    kill %1
    echo -e "${GREEN}TESTS SUCCESSFUL${NC}"
    exit 0
fi
