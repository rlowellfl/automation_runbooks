# The following PowerShell runbook queries all Azure Virtual Machines in a given subscription with a tag and value matching the parameters ('Snapshot' and 'True' by default).
# All matching VMs have a Full disk snapshot created for all OS and Data disks.

Param(
 [string]$subscription,
 [string]$tagName = "Snapshot",
 [string]$tagValue = "True",
 [string]$storageType = "Standard_LRS",
 [string]$method = "SA"
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect using a Managed Service Identity
try {
        $AzureContext = (Connect-AzAccount -Identity).context
    }
catch{
    Write-Error -Message $_.Exception
    throw $_.Exception
    Write-Output "There is no system-assigned user identity. Aborting."; 
        exit
    }

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $subscription `
    -DefaultProfile $AzureContext

if ($method -eq "SA")
    {
        Write-Output "Using system-assigned managed identity"
    }
elseif ($method -eq "UA")
    {
        Write-Output "Using user-assigned managed identity"

        # Connects using the Managed Service Identity of the named user-assigned managed identity
        $identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroup `
            -Name $UAMI -DefaultProfile $AzureContext

        # validates assignment only, not perms
        if ((Get-AzAutomationAccount -ResourceGroupName $resourceGroup `
                -Name $automationAccount `
                -DefaultProfile $AzureContext).Identity.UserAssignedIdentities.Values.PrincipalId.Contains($identity.PrincipalId))
            {
                $AzureContext = (Connect-AzAccount -Identity -AccountId $identity.ClientId).context

                # set and store context
                $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
            }
        else {
                Write-Output "Invalid or unassigned user-assigned managed identity"
                exit
            }
    }
else {
        Write-Output "Invalid method. Choose UA or SA."
        exit
     }

# Get VMs with snapshot tag
try {
    $tagResList = Get-AzResource -ResourceType "Microsoft.Compute/virtualMachines" -TagName $tagName -TagValue $tagValue | ForEach-Object {
 
        Get-AzResource -ResourceId $_.resourceid
        
        }
    }
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
    }

 
foreach($tagRes in $tagResList) {
 
$vmInfo = Get-AzVM -ResourceID $tagRes.ResourceID
 
#Set local variables
 
$location = $vmInfo.Location
 
$resourceGroupName = $vmInfo.ResourceGroupName
 
$timestamp = Get-Date -f MM-dd-yyyy_HH_mm_ss
 
#Snapshot name of OS data disk
 
$snapshotName = $vmInfo.Name + "-os-" + $timestamp
 
#Create snapshot configuration
 
$snapshot = New-AzSnapshotConfig -SourceUri $vmInfo.StorageProfile.OsDisk.ManagedDisk.Id -AccountType $storageType -Location $location -CreateOption copy

#Take snapshot
 
New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

if($vmInfo.StorageProfile.DataDisks.Count -ge 1){
 
#Condition with more than one data disks
 
for($i=0; $i -le $vmInfo.StorageProfile.DataDisks.Count - 1; $i++){
 
#Snapshot name of OS data disk
 
$snapshotName = $vmInfo.StorageProfile.DataDisks[$i].Name + $timestamp

#Create snapshot configuration
 
$snapshot = New-AzSnapshotConfig -SourceUri $vmInfo.StorageProfile.DataDisks[$i].ManagedDisk.Id -Location $location -CreateOption copy

#Take snapshot
 
New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

}
 
}
 
else{
 
Write-Host $vmInfo.Name + " doesn't have any additional data disks."
 
}
 
}