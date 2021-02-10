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
repoRoot="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"
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
configuration_file=avtool.env
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

# Read variables in configuration file
export $(grep RESOURCE_GROUP $configuration_file)

if [[ "${action}" == "install" ]] ; then
    echo "Installing pre-requisite"
    exit 0
fi

if [[ "${action}" == "deploy" ]] ; then
    echo "Deploying service"
    exit 0
fi

if [[ "${action}" == "undeploy" ]] ; then
    echo "Undeploying service"
    exit 0
fi

if [[ "${action}" == "start" ]] ; then
    echo "Starting service"
    exit 0
fi

if [[ "${action}" == "stop" ]] ; then
    echo "Stopping service"
    exit 0
fi
if [[ "${action}" == "test" ]] ; then
    echo "Testing service"
    exit 0
fi
