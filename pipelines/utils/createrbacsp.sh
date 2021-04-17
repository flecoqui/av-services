#!/bin/bash
##########################################################################################################################################################################################
#- Purpose: Script is used to deploy the Lorentz service
#- Support deploying to multiple regions as well as required global resources
#- Parameters are:
#- [-s] subscription - The subscription where the resources will reside.
#- [-a] serviceprincipalName - The service principal name to create.
###########################################################################################################################################################################################
set -eu
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
    echo -e "\t-a \t Sets the service principal name (required)"
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

echo Creating Service Principal for:
echo Service Principal Name: $appName
echo Subscription: $subscription
echo
echo Setting Azure Subscription 
echo 
az account set --subscription $subscription

# Retrieve the tenant it
tenantId=$(az account show --query tenantId -o tsv)
echo
echo TenantId : $tenantId
echo 

echo
echo Create Service Principal
echo

read aks_sp_password <<< $(az ad sp create-for-rbac --skip-assignment --name http://$appName --query [password] -o tsv)
read aks_sp_id <<< $(az ad sp show  --id http://$appName --query [appId] -o tsv)
appId=$aks_sp_id

# Microsoft Graph API 
API_Microsoft_Graph="00000003-0000-0000-c000-000000000000"
# Application.ReadWrite.OwnedBy
PERMISSION_MG_Application_ReadWrite_OwnedBy="18a4783c-866b-4cc7-a460-3d5e5662c884"

# Azure Active Directory Graph API
API_Windows_Azure_Active_Directory="00000002-0000-0000-c000-000000000000"
# Application.ReadWrite.OwnedBy
PERMISSION_AAD_Application_ReadWrite_OwnedBy="824c81eb-e3f8-4ee6-8f6d-de7f50d565b7"

echo
echo "Service Principal AppId = $appId"
echo

echo
echo Request Microsoft Graph API Application.ReadWrite.OwnedBy Permissions
echo
# Request Microsoft Graph API Application.ReadWrite.OwnedBy Permissions
az ad app permission add --id $appId --api $API_Microsoft_Graph --api-permissions $PERMISSION_MG_Application_ReadWrite_OwnedBy=Role
az ad app permission grant --id $appId --api $API_Microsoft_Graph --scope $PERMISSION_MG_Application_ReadWrite_OwnedBy

echo
echo Request Azure Active Directory Graph API Application.ReadWrite.OwnedBy Permissions
echo
# Request Azure Active Directory Graph API Application.ReadWrite.OwnedBy Permissions
az ad app permission add --id $appId --api $API_Windows_Azure_Active_Directory --api-permissions $PERMISSION_AAD_Application_ReadWrite_OwnedBy=Role
az ad app permission grant --id $appId --api $API_Windows_Azure_Active_Directory --scope $PERMISSION_AAD_Application_ReadWrite_OwnedBy

echo
echo "Grant Application and Delegated permissions through admin-consent"
echo
# Grant Application & Delegated permissions through admin-consent
# deprecated
# az ad app permission admin-consent --id $appId

principalId=$(az ad sp show --id $appId --query "objectId" --output tsv)
echo "principalId: $principalId"

API_Microsoft_GraphId=$(az ad sp show --id $API_Microsoft_Graph --query "objectId" --output tsv)
echo "API_Microsoft_GraphId: $API_Microsoft_GraphId"

API_Windows_Azure_Active_DirectoryId=$(az ad sp show --id $API_Windows_Azure_Active_Directory --query "objectId" --output tsv)
echo "API_Windows_Azure_Active_DirectoryId: $API_Windows_Azure_Active_DirectoryId"


PERMISSION_MG_Application_ReadWrite_OwnedBy=$(az ad sp show --id $API_Microsoft_Graph --query "appRoles[?value=='Application.ReadWrite.OwnedBy']" | jq -r ".[].id")
echo "PERMISSION_MG_Application_ReadWrite_OwnedBy: $PERMISSION_MG_Application_ReadWrite_OwnedBy"

PERMISSION_AAD_Application_ReadWrite_OwnedBy=$(az ad sp show --id $API_Windows_Azure_Active_Directory --query "appRoles[?value=='Application.ReadWrite.OwnedBy']" | jq -r ".[].id")
echo "PERMISSION_AAD_Application_ReadWrite_OwnedBy: $PERMISSION_AAD_Application_ReadWrite_OwnedBy"

echo "Wait 60 seconds to be sure Service Principal is present on https://graph.microsoft.com/"
sleep 60
cmd="az rest --method POST --uri https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments --body '{\"principalId\": \"$principalId\",\"resourceId\": \"$API_Microsoft_GraphId\",\"appRoleId\": \"$PERMISSION_MG_Application_ReadWrite_OwnedBy\"}' "
echo "$cmd"
eval "$cmd" || true
cmd="az rest --method POST --uri https://graph.microsoft.com/v1.0/servicePrincipals/$API_Microsoft_GraphId/appRoleAssignedTo --body '{\"principalId\": \"$principalId\",\"resourceId\": \"$API_Microsoft_GraphId\",\"appRoleId\": \"$PERMISSION_MG_Application_ReadWrite_OwnedBy\"}'"
echo "$cmd"
eval "$cmd" || true
cmd="az rest --method POST --uri https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments --body '{\"principalId\": \"$principalId\",\"resourceId\": \"$API_Windows_Azure_Active_DirectoryId\",\"appRoleId\": \"$PERMISSION_AAD_Application_ReadWrite_OwnedBy\"}' "
echo "$cmd"
eval "$cmd" || true
cmd="az rest --method POST --uri https://graph.microsoft.com/v1.0/servicePrincipals/$API_Windows_Azure_Active_DirectoryId/appRoleAssignedTo --body '{\"principalId\": \"$principalId\",\"resourceId\": \"$API_Windows_Azure_Active_DirectoryId\",\"appRoleId\": \"$PERMISSION_AAD_Application_ReadWrite_OwnedBy\"}'"
echo "$cmd"
eval "$cmd" || true


echo
echo Assign role "Owner" to service principal 
echo
az role assignment create --assignee $appId  --role "Owner"

subscriptionName=$(az account list --output tsv --query "[?id=='$subscription'].name")

echo
echo "Service Principal Name: $appName"
echo "Subscription: $subscription"
echo "Subscription Name: $subscriptionName"
echo "AppId: $aks_sp_id"
echo "Password: $aks_sp_password"
echo "TenantID: $tenantId"
echo

