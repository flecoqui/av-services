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
    echo "Installing all av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Installing for $line"
        echo "***********************************************************"
        cd $line 
        bash ./avtool.sh -a install
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo "Install for $line ran successfully" 
        else 
            echo "Install for $line failed" 
        fi
        echo "***********************************************************"
        cd ../../tests
    done
    echo "Installing all the av-services done"
    exit 0
fi
if [[ "${action}" == "login" ]] ; then
    echo "Login..."
    docker login
    echo "Login done"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying all av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Deploying for $line"
        echo "***********************************************************"
        cd $line 
        bash ./avtool.sh -a deploy
        bash ./avtool.sh -a stop
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo "Deploy for $line ran successfully" 
        else 
            echo "Deploy for $line failed" 
        fi
        echo "***********************************************************"
        cd ../../tests
    done
    echo "Deploying all the av-services done"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying all av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Undeploying for $line"
        echo "***********************************************************"
        cd $line 
        bash ./avtool.sh -a undeploy
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo "Undeploy for $line ran successfully" 
        else 
            echo "Undeploy for $line failed" 
        fi
        echo "***********************************************************"
        cd ../../tests
    done
    echo "Undeploying all the av-services done"
    exit 0
fi
if [[ "${action}" == "status" ]] ; then
    echo "Getting status for all av-services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Getting status for $line"
        echo "***********************************************************"
        cd $line 
        bash ./avtool.sh -a start
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo "Getting status for $line ran successfully" 
        else 
            echo "Getting status for $line failed" 
        fi
        echo "***********************************************************"
        cd ../../tests
    done
    echo "Getting status for all av-services done"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting all services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Starting for $line"
        echo "***********************************************************"
        cd $line 
        bash ./avtool.sh -a start
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo "Start for $line ran successfully" 
        else 
            echo "Start for $line failed" 
        fi
        echo "***********************************************************"
        cd ../../tests
    done
    echo "Starting all the av-services done"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping all services..."
    for line in $(cat ./listtests.txt) ; do
        echo "***********************************************************"
        echo "Stopping for $line"
        echo "***********************************************************"
        cd $line 
        bash ./avtool.sh -a stop
        STATUS=$?  
        echo "***********************************************************"
        if [ $STATUS -eq 0 ]; then 
            echo "Stop for $line ran successfully" 
        else 
            echo "Stop for $line failed" 
        fi
        echo "***********************************************************"
        cd ../../tests
    done
    echo "Stopping all the av-services done"
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
            echo "\e[32mTests for $line ran successfully" 
        else 
            echo "\e[91mTests for $line failed" 
        fi
        echo "***********************************************************"
        cd ../../tests
    done
    echo "Testing all the av-services SUCCESSFUL"
    exit 0
fi
