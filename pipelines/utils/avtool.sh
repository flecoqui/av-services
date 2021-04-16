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
configuration_file=./avtool.env
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


if [[ "${action}" == "install" ]] ; then
    echo "Installing all av-services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Installing for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        ./avtool.sh -a install  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Install for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Install for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi
        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo -e "${GREEN}Installing all the av-services done${NC}"
    exit 0
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login all av-services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Login for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        ./avtool.sh -a login  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Login for $line ran successfully${NC}" 
        else 
            echo -e "${RED}ogin for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi

        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo -e "${GREEN}Login all the av-services done${NC}"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying all av-services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Deploying for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        ./avtool.sh -a deploy  -e ${stoperror} -s ${silentmode}
        ./avtool.sh -a stop  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Deploy for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Deploy for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi

        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo -e "${GREEN}Deploying all the av-services done${NC}"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying all av-services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Undeploying for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        ./avtool.sh -a undeploy  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Undeploy for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Undeploy for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi

        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo -e "${GREEN}Undeploying all the av-services done${NC}"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Getting status for all av-services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Getting status for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        ./avtool.sh -a start  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Getting status for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Getting status for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi

        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo -e "${GREEN}Getting status for all av-services done${NC}"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting all services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Starting for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        ./avtool.sh -a start -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Start for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Start for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi

        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo -e "${GREEN}Starting all the av-services done${NC}"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping all services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Stopping for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        ./avtool.sh -a stop  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Stop for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Stop for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi
        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo  -e "${GREEN}Stopping all the av-services done${NC}"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    echo "Testing all the av-services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Running tests for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        ./avtool.sh -a test  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Tests for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Tests for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi

        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo  -e "${GREEN}Testing all the av-services SUCCESSFUL${NC}"
    exit 0
fi
if [[ "${action}" == "integration" ]] ; then
    echo "Testing all the av-services..."
    for line in $(cat "${configuration_file}") ; do
        echo "***********************************************************"
        echo "Running integration tests for $line"
        echo "***********************************************************"
        pushd $line 
        alias exit=return
        if [[ -f ./.avtoolconfig ]]; then
            rm ./.avtoolconfig 
        fi
        echo "***********************************************************"
        echo "Deploy for $line " 
        ./avtool.sh -a deploy  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Deployment for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Deployment for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi
        fi
        
        echo "***********************************************************"
        echo "Stop for $line " 
        ./avtool.sh -a stop  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Stop for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Stop for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                echo "Undeploy for $line " 
                ./avtool.sh -a undeploy   -e ${stoperror} -s ${silentmode}          
                exit 1
            fi
        fi
        echo "***********************************************************"
        echo "Start for $line " 
        ./avtool.sh -a start  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Start for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Start for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                echo "Undeploy for $line " 
                ./avtool.sh -a undeploy  -e ${stoperror} -s ${silentmode}           
                exit 1
            fi
        fi
        echo "***********************************************************"
        echo "Status for $line " 
        ./avtool.sh -a status  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Status for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Status for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                echo "Undeploy for $line " 
                ./avtool.sh -a undeploy     -e ${stoperror} -s ${silentmode}         
                exit 1
            fi
        fi
        echo "***********************************************************"
        echo "Tests for $line " 
        ./avtool.sh -a test  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Test for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Test for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                echo "Undeploy for $line " 
                ./avtool.sh -a undeploy  -e ${stoperror} -s ${silentmode}          
                exit 1
            fi
        fi
        echo "***********************************************************"
        echo "Undeploy for $line " 
        ./avtool.sh -a undeploy  -e ${stoperror} -s ${silentmode}
        STATUS=$?  
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Undeployment for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Undeployment for $line failed${NC}" 
            if [[ ${stoperror} == true ]]; then
                exit 1
            fi
        fi
        unalias exit
        echo "***********************************************************"
        popd 
    done
    echo  -e "${GREEN}Testing all the av-services SUCCESSFUL${NC}"
    exit 0
fi
