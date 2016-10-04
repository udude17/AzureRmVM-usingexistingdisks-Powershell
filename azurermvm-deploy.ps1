#
# Simple PowerShell example for creating a Linux VM with a new NIC & VNET using existing OS and data disks. 
# Useful when needed to move the VM to a new VNET.  AzureRM or ARM-only (not Classic)
#
# Requires Azure PowerShell September 2016 or later
# VERSION:  1.0
# 
Login-AzureRMAccount 
$SubID  = "xxxxxyyynnn" #  
# Select-AzureRmSubscription –Subscriptionid $SubID 
Set-AzureRmContext -SubscriptionId $SubID 

#----------------------------ONE TIME SETUP-------------------------------------------
# The Azure Region Name  (script assumes only one region)
$Location=’westeurope’
#New ResourceGroup for the new VM & NIC
$RGvm="Linux35RG"
New-AzureRmResourceGroup -Location $Location -Name $RGvm
#--------------------------END ONE TIME SETUP-----------------------------------------


###--------------INPUT PARAMETERS SECTION-------------###
#Existing ResourceGroup that holds the VNET you are trying to load the VM into
$RGvnet=’MyVNET2’
#Name of the VNET you  are trying to load the VM into
$NetworkName=’MyVNET2’

#Subnet in the vnet you are trying to move the VM into
$SubnetName=’subnet2’

#New Public IP name
# $PIPName=’MovedVMpip’

#New Nic name and Internal IP address that will get created in the VNET we are moving the VM to
$Nic1Name=’LinuxNIC35’
$pvip = '10.0.1.135'

#New Virtual Machine Name
$VMName=’Linux-35’

#VMSize
$VMSize=’Standard_DS1’

#The storage account that holds the VHD OS disk you are trying to make a new VM from
$storageaccount=’101storage’
#The storage account that holds the VHD DATA disk(s) you are trying to make a new VM from
$storageaccount2=’101storage’

# The resource group(s) for $storageaccount(s)
# OS Disk storage account RG
$StorageRg = ’101-linux-storage’   
# Data Disk storage account RG
$StorageRg2 = ’101-linux-storage’  

# DISKS - Name of the OS VHD that resided in the $storageaccount
$VHDName=’linux101osdisk’
# DISKS - Name of the Data Disk VHDs
$DataDisk1Name=’linux101-disk01’
$DataDisk2Name=’linux101-disk02’

###--------------END INPUT PARAMETER SECTION-------------###

# NETWORK INTERFACE & VNET 
$network=Get-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $RGvnet
$subnet=Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $network
# Use of public IP optional thus commented out....
# $pip=New-AzureRmPublicIpAddress -Name $PIPName -ResourceGroupName $RGvm -Location $Location -DomainNameLabel $PIPDNSName -AllocationMethod Dynamic
# $nic1=New-AzureRmNetworkInterface -Name $Nic1Name -ResourceGroupName $RGvm -Location $Location -SubnetId $subnet -EnableIPForwarding -PublicIpAddressId $pip.Id
$nic1=New-AzureRmNetworkInterface -Location $Location -Name $Nic1Name -ResourceGroupName $RGvm -Subnet $subnet -EnableIPForwarding -PrivateIpAddress $pvip

# DISK LOCATIONS
$Stor=Get-AzureRmStorageAccount -ResourceGroupName $StorageRg -Name $storageaccount
$Stor2=Get-AzureRmStorageAccount -ResourceGroupName $StorageRg -Name $storageaccount2
$OSDiskUri   =$Stor.PrimaryEndpoints.Blob.ToString() + ‘vhds/’ +$VHDName +’.vhd’
$DataDisk1Uri=$Stor2.PrimaryEndpoints.Blob.ToString() + ‘vhds/’ +$DataDisk1Name+’.vhd’
$DataDisk2Uri=$Stor2.PrimaryEndpoints.Blob.ToString() + ‘vhds/’ +$DataDisk2Name+’.vhd’

# START VM CONFIG
$VM=New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$VM=Add-AzureRmVMNetworkInterface -Id $nic1.id -VM $VM -Primary

# ATTACH EXISTING DISKS TO VM
$VM = Set-AzureRmVMOSDisk -Name $VHDName -VhdUri $OSDiskUri -Caching ReadWrite -CreateOption attach -Linux -VM $VM
$VM = Add-AzureRmVMDataDisk -VM $VM -Name $DataDisk1Name -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 0 -VhdUri $DataDisk1Uri -CreateOption attach
$VM = Add-AzureRmVMDataDisk -VM $VM -Name $DataDisk2Name -Caching 'ReadOnly' -DiskSizeInGB 10 -Lun 1 -VhdUri $DataDisk2Uri -CreateOption attach

# NOTE: setting to null may not be needed in future if -DiskSizeInGB param is not required
$VM.StorageProfile.DataDisks[0].DiskSizeGB = $null
$VM.StorageProfile.DataDisks[1].DiskSizeGB = $null

## FINAL SCRIPT ACTION ## Create new VM ##
New-AzureRmVM -ResourceGroupName $RGvm -Location $location -VM $VM

###########--------------END----------------###############
