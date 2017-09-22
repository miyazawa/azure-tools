###########################################################
# subscription
###########################################################
$subscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$tenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# 
# https://docs.microsoft.com/ja-jp/azure/azure-resource-manager/resource-group-authenticate-service-principal
#
# ----------
# Login-AzureRmAccount
# Import-Module -Name .\New-SelfSignedCertificateEx.ps1
# $appName = "{ application name }"
# $cn = "CN=$appName"
# New-SelfSignedCertificateEx -StoreLocation CurrentUser -Subject $cn -KeySpec "Exchange" -FriendlyName $appName -NotAfter $([datetime]::now.AddYears(5))
# $cert = Get-ChildItem -path Cert:\CurrentUser\my | where {$PSitem.Subject -eq $cn }
# $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
# $ServicePrincipal = New-AzureRMADServicePrincipal -DisplayName $appName -CertValue $keyValue -EndDate $cert.NotAfter -StartDate $cert.NotBefore
# $NewRole = $null
# $scope = "/subscriptions/" + $subscriptionId 
# New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $ServicePrincipal.ApplicationId -Scope $Scope
# $NewRole = Get-AzureRMRoleAssignment -ObjectId $ServicePrincipal.Id
# ----------
#
$appName = "{ application name }"
$applicationId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$cn = "CN=$appName"

###########################################################
# login
###########################################################
$thumbprint = (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $cn }).Thumbprint
Login-AzureRmAccount -ServicePrincipal -CertificateThumbprint $thumbprint -ApplicationId $applicationId -TenantId $tenantId
