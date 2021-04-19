#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to deploy the Lorentz service
#- Support deploying to multiple regions as well as required global resources
#- Parameters are:
#- [-s] subscription - The subscription where the resources will reside.
#- [-a] serviceprincipalName - The service principal name to create.
###########################################################################################################################################################################################
set -u
parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd -P
)
cd "$parent_path"
#######################################################
#- function used to print out script usage
#######################################################
function usage() {
    echo
    echo "Arguments:"
    echo -e "\t-s\t Sets the subscription"
    echo -e "\t-a\t Sets the service principal name (required)"
    echo
    echo "Example:"
    echo -e "\tbash createrbacsp.sh -u e5c9fc83-fbd0-4368-9cb6-1b5823479b6a -a testazdosp "
}
while getopts "s:u:a:e:r:c:t:p:hq" opt; do
    case $opt in
    s) subscription=$OPTARG ;;
    a) appName=$OPTARG ;;
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
# Make sure we are connected using a user principal that has Azure AD Admin permissions.
# az logout
# az login

# Validation
if [[ $# -eq 0 || -z $subscription || -z $appName ]]; then
    echo "Required parameters are missing"
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
        echo -e "${RED}\nAn error occured in createrbacsp.sh bash${NC}"
        exit 1
    fi
}

echo Creating Service Principal for:
echo Service Principal Name: $appName
echo Subscription: $subscription
az account set --subscription $subscription
# Retrieve the tenant it
tenantId=$(az account show --query tenantId -o tsv)
echo "TenantId : $tenantId"
echo
echo "Create Service Principal:"
echo
spjson=$(az ad sp create-for-rbac --skip-assignment --sdk-auth  --name http://$appName  -o json)

appId=$(echo "$spjson" | jq -r .clientId)
appSecret=$(echo "$spjson" | jq -r .clientSecret)
echo "Service Principal created: $appId"
echo "Service Principal secret: $appSecret"
principalId=$(az ad sp show --id $appId --query "objectId" --output tsv)
echo "Service Principal objectId: $principalId"

# Microsoft Graph API 
API_Microsoft_Graph="00000003-0000-0000-c000-000000000000"
# Azure Active Directory Graph API
API_Windows_Azure_Active_Directory="00000002-0000-0000-c000-000000000000"
API_Microsoft_GraphId=$(az ad sp show --id $API_Microsoft_Graph --query "objectId" --output tsv)
echo "API_Microsoft_GraphId: $API_Microsoft_GraphId"
API_Windows_Azure_Active_DirectoryId=$(az ad sp show --id $API_Windows_Azure_Active_Directory --query "objectId" --output tsv)
echo "API_Windows_Azure_Active_DirectoryId: $API_Windows_Azure_Active_DirectoryId"
PERMISSION_MG_Application_ReadWrite_OwnedBy=$(az ad sp show --id $API_Microsoft_Graph --query "appRoles[?value=='Application.ReadWrite.OwnedBy']" | jq -r ".[].id")
echo "PERMISSION_MG_Application_ReadWrite_OwnedBy: $PERMISSION_MG_Application_ReadWrite_OwnedBy"
PERMISSION_AAD_Application_ReadWrite_OwnedBy=$(az ad sp show --id $API_Windows_Azure_Active_Directory --query "appRoles[?value=='Application.ReadWrite.OwnedBy']" | jq -r ".[].id")
echo "PERMISSION_AAD_Application_ReadWrite_OwnedBy: $PERMISSION_AAD_Application_ReadWrite_OwnedBy"

echo
echo "Request Microsoft Graph API Application.ReadWrite.OwnedBy Permissions"
echo
az ad app permission add --id $appId --api $API_Microsoft_Graph --api-permissions $PERMISSION_MG_Application_ReadWrite_OwnedBy=Role  1> /dev/null  
checkError
az ad app permission grant --id $appId --api $API_Microsoft_Graph --scope $PERMISSION_MG_Application_ReadWrite_OwnedBy  1> /dev/null 
checkError

echo
echo "Request Azure Active Directory Graph API Application.ReadWrite.OwnedBy Permissions"
echo
az ad app permission add --id $appId --api $API_Windows_Azure_Active_Directory --api-permissions $PERMISSION_AAD_Application_ReadWrite_OwnedBy=Role  1> /dev/null 2> /dev/null 
checkError
az ad app permission grant --id $appId --api $API_Windows_Azure_Active_Directory --scope $PERMISSION_AAD_Application_ReadWrite_OwnedBy  1> /dev/null 2> /dev/null 
checkError

echo
echo "Grant Application and Delegated permissions through admin-consent"
echo
echo "Wait 60 seconds to be sure Service Principal is present on https://graph.microsoft.com/"
sleep 60
cmd="az rest --method GET --uri https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments | jq -r '.value[] | select(.principalId == \"$principalId\" and .resourceId == \"$API_Microsoft_GraphId\" and .appRoleId == \"$PERMISSION_MG_Application_ReadWrite_OwnedBy\")'"
echo "$cmd"
result=$(eval "$cmd") 
if [[ $? == 1 || -z $result ]]; then
    cmd="az rest --method POST --uri https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments --body '{\"principalId\": \"$principalId\",\"resourceId\": \"$API_Microsoft_GraphId\",\"appRoleId\": \"$PERMISSION_MG_Application_ReadWrite_OwnedBy\"}' "
    echo "$cmd"
    eval "$cmd" 1> /dev/null 
    checkError
else
    echo "Service Principal already registered:"
    echo "$result"
fi

cmd="az rest --method GET --uri https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments | jq -r '.value[] | select(.principalId == \"$principalId\" and .resourceId == \"$API_Windows_Azure_Active_DirectoryId\" and .appRoleId == \"$PERMISSION_AAD_Application_ReadWrite_OwnedBy\")'"
echo "$cmd"
result=$(eval "$cmd") 
if [[ $? == 1 || -z $result ]]; then
    cmd="az rest --method POST --uri https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments --body '{\"principalId\": \"$principalId\",\"resourceId\": \"$API_Windows_Azure_Active_DirectoryId\",\"appRoleId\": \"$PERMISSION_AAD_Application_ReadWrite_OwnedBy\"}' "
    echo "$cmd"
    eval "$cmd" 1> /dev/null 
    checkError
else
    echo "Service Principal already registered:"
    echo "$result"
fi
echo
echo "Assign role \"Owner\" to service principal" 
echo
az role assignment create --assignee $appId  --role "Owner" 1> /dev/null 
checkError

subscriptionName=$(az account list --output tsv --query "[?id=='$subscription'].name")
echo
echo "Information for the creation of an Azure DevOps Service Connection:"
echo
echo "Service Principal Name: $appName"
echo "Subscription: $subscription"
echo "Subscription Name: $subscriptionName"
echo "AppId: $appId"
echo "Password: $appSecret"
echo "TenantID: $tenantId"
echo
echo 
echo "Information for the creation of Github Action Secret AZURE_CREDENTIALS:"
echo 
echo "$spjson"

