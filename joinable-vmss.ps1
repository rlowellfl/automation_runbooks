# Variables
$resourceGroupName = "VMSSFlexResourceGroup"
$location = "CentralUS"
$vmssName = "MyFlexVMSS"

# Create Resource Group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create VMSS Configuration
$vmssConfig = New-AzVmssConfig -Location $location -OrchestrationMode Flexible -PlatformFaultDomainCount 1 -SinglePlacementGroup $false -Zone @("1", "2", "3")

# Create the VMSS (no autoscale profile)
New-AzVmss -ResourceGroupName $resourceGroupName -Name $vmssName -VirtualMachineScaleSet $vmssConfig