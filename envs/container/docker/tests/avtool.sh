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
if [[ ! $action == login && ! $action == install && ! $action == start && ! $action == stop && ! $action == status && ! $action == deploy && ! $action == undeploy && ! $action == test && ! $action == inegration ]]; then
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
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Installing for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a install
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Install for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Install for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo -e "${GREEN}Installing all the av-services done${NC}"
    exit 0
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login all av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Login for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a login
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Login for $line ran successfully${NC}" 
        else 
            echo -e "${RED}ogin for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo -e "${GREEN}Login all the av-services done${NC}"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying all av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Deploying for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a deploy
        ./avtool.sh -a stop
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Deploy for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Deploy for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo -e "${GREEN}Deploying all the av-services done${NC}"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying all av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Undeploying for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a undeploy
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Undeploy for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Undeploy for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo -e "${GREEN}Undeploying all the av-services done${NC}"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Getting status for all av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Getting status for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a start
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Getting status for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Getting status for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo -e "${GREEN}Getting status for all av-services done${NC}"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting all services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Starting for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a start
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Start for $line ran successfully${NC}" 
        else 
            echo -e "${RED}Start for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo -e "${GREEN}Starting all the av-services done${NC}"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping all services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Stopping for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a stop
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo -e "${GREEN}Stop for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Stop for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo  -e "${GREEN}Stopping all the av-services done${NC}"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    echo "Testing all the av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Running tests for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a test
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Tests for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Tests for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo  -e "${GREEN}Testing all the av-services SUCCESSFUL${NC}"
    exit 0
fi
if [[ "${action}" == "integration" ]] ; then
    echo "Testing all the av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Running tests for $line"
        echo "***********************************************************"
        cd $line 
        alias exit=return
        ./avtool.sh -a deploy
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Deployment for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Deployment for $line failed${NC}" 
        fi
        ./avtool.sh -a stop
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Stop for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Stop for $line failed${NC}" 
        fi
        ./avtool.sh -a start
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Start for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Start for $line failed${NC}" 
        fi
        ./avtool.sh -a status
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Status for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Status for $line failed${NC}" 
        fi
        ./avtool.sh -a test
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Test for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Test for $line failed${NC}" 
        fi
        ./avtool.sh -a undeploy
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo  -e "${GREEN}Undeployment for $line ran successfully${NC}" 
        else 
            echo  -e "${RED}Undeployment for $line failed${NC}" 
        fi
        unalias exit
        echo "***********************************************************"
        cd ../../tests
    done
    echo  -e "${GREEN}Testing all the av-services SUCCESSFUL${NC}"
    exit 0
fi
