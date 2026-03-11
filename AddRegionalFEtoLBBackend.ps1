##########################################
### Purpose ###
##########################################

# For adding a regional public Load Balancer Frontend to an existing Cross-Region load balancer backend

### Change These Variables ###

#Regional
$RegionalFEName = "Epic-SFDProd-USEA2-FE"

#Global
$GlobalBEName = "Epic-SFDProd-USCE-Global-BE"


##########################################
### Don't Change Below This Line ###
##########################################

#Regional
$RegionalLBName = "epic-dr-region-pub"
$RegionalRGName = "rg-netsec-usea2-shr-b344"
$RegionalSubName = "hub-shr-ae99"

#Global
$GlobalLBName = "epic-global-pub"
$GlobalRGName = "shared-services-hub-prod-rg"
$GlobalSubName = "Shared Services Central"


######################################################################
## 1. Get Regional LB Frontend IP
######################################################################

Set-AzContext -SubscriptionName $RegionalSubName

$rlb = Get-AzLoadBalancer -Name $RegionalLBName -ResourceGroupName $RegionalRGName
$rlbfe = Get-AzLoadBalancerFrontendIpConfig -Name $RegionalFEName -LoadBalancer $rlb

# Create backend address object referencing the regional LB frontend
#    and set the AdminState to down
$newBackendAddress = New-AzLoadBalancerBackendAddressConfig -Name $RegionalFEName -LoadBalancerFrontendIPConfigurationId $rlbfe.Id -AdminState "Down"


######################################################################
## 2. Add It to the Global LB Backend Pool (Append, Not Replace)
######################################################################

Set-AzContext -SubscriptionName $GlobalSubName

# Get the global LB
$globalLB = Get-AzLoadBalancer -Name $GlobalLBName -ResourceGroupName $GlobalRGName

# Get the backend pool object
$backendPool = $globalLB.BackendAddressPools | Where-Object { $_.Name -eq $GlobalBEName }
#Saving contents for comparison before application
#Update:  THis only works if you compare before appending the new backend address below (line 56 currently)
$backendPoolPre = $globalLB.BackendAddressPools | Where-Object { $_.Name -eq $GlobalBEName }


# Append the new backend address
$backendPool.LoadBalancerBackendAddresses.Add($newBackendAddress)

# Push the update back to Azure
Set-AzLoadBalancerBackendAddressPool -InputObject $backendpool