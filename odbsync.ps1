# Variables
$resourceGroupName = "myResourceGroup"
$vmName = "myVM"
$snapshotName = "myVMSnapshot"
$location = "East US"

# Sign in to Azure

Connect-AzAccount

# Freeze the database

Invoke-Command -ComputerName $vmName -ScriptBlock {

    & "C:\Epic\bin\INSTFREEZE" }

# Create a snapshot of the VM

$snapshotConfig = New-AzSnapshotConfig -SourceUri (Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName).StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption Copy

New-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig

# Thaw the database

Invoke-Command -ComputerName $vmName -ScriptBlock {

    & "C:\Epic\bin\INSTTHAW" }


# Output the snapshot details

$snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName
    
Write-Output "Snapshot ID: $($snapshot.Id)"
Write-Output "Snapshot Location: $($snapshot.Location)"
