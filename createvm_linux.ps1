###########################################################
## create linux server
###########################################################

# error action
$ErrorActionPreference = "Stop"

# login
. ".\login.ps1"

# read common variables
. ".\common.ps1"

# server owned values
$rgName = "{ resource group name }"
$vmName = "{ vm name }"
$vmSize = "{ vm size }"
$vmPublisher = "Canonical"
$vmOffer = "ubuntuServer"
$vmSku = "16.04-LTS"
$vmDiskSize = 32
$vmDiskType = "StandardLRS"
$diagStorageName = "{ diag storage name }"

# auto generated values
$pipName = $vmName + "-pip"
$domainNameLable = $vmName
$nicName = $vmName + "-nic"

###########################################################
##  main
###########################################################

# availability check for DNS Label
if (!( Test-AzureRmDnsAvailability -DomainNameLabe $domainNameLable -Location $loc ))
{
    Write-Host "Domain Name Label $domainNameLable already exists."
    exit
}

# creat Public IP Address
if ( Find-AzureRmResource -ResourceGroupNameEquals $rgName -ResourceNameEquals $pipName ) {
    "Public Ip Address Exists."
    $pip = Get-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName
    $pip.Name
} else {
    "Creating public ip..."
    $pip = New-AzureRmPublicIpAddress -Name $pipName `
             -ResourceGroupName $rgName `
             -Location $loc `
             -AllocationMethod Dynamic `
             -IpAddressVersion IPv4 `
             -DomainNameLabel $domainNameLable
    
    "Done."
}

### create nic
if ( Find-AzureRmResource -ResourceGroupNameEquals $rgName -ResourceNameEquals $nicName ) {
    "Public Ip Address Exists."
    $nic = Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName
    $nic.Name
} else {
    "Creating NetworkInterfaces..."
    $vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgNameCommon
    $subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

    $ipConf = New-AzureRmNetworkInterfaceIpConfig -Name ipconf1 `
            -PrivateIpAddressVersion IPv4 `
            -Primary `
            -Subnet $subnet `
            -PublicIpAddress $pip

    ### create nic
    $nic = New-AzureRmNetworkInterface -Name $nicName `
            -ResourceGroupName $rgName `
            -Location $loc `
            -IpConfiguration $ipConf
}

# create vm
# set dummy password
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminUser, $securePassword)

"Creating VM..."
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
Set-AzureRmVMOSDisk -VM $vm -Caching ReadWrite -CreateOption FromImage -Linux -DiskSizeInGB $vmDiskSize -StorageAccountType $vmDiskType
Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred -DisablePasswordAuthentication
Set-AzureRmVMSourceImage -VM $vm -PublisherName $vmPublisher -Offer $vmOffer -Skus $vmOffer -Version latest
Add-AzureRmVMNetworkInterface -VM $vm -NetworkInterfaceId $nic.id -Primary
Add-AzureRmVMSshPublicKey -VM $vm -KeyData $sshPublicKey -Path "/home/$adminUser/.ssh/authorized_keys"
#Set-AzureRmVMDiagnosticsExtension 

#Create Storage Account for boot diagnostics
if ( Find-AzureRmResource -ResourceGroupNameEquals $rgNameCommon -ResourceNameEquals $diagStorageName ) {
    "Diagnostic Storage already Exists."
    $diagStorage = Get-AzureRmStorageAccount -ResourceGroupName $rgNameCommon -Name $diagStorageName
} else {
    "Creating Diagnostic Storage Account..."
    $diagStorage = New-AzureRmStorageAccount -Location $loc -Name $diagStorageName -ResourceGroupName $rgName -SkuName Standard_LRS
    "Done."
}
Set-AzureRmVMBootDiagnostics -Enable -ResourceGroupName $rgNameCommon -VM $vm -StorageAccountName $diagStorage.StorageAccountName

New-AzureRmVM -ResourceGroupName $rgName -Location $loc -VM $vm -Verbose
"Done."
