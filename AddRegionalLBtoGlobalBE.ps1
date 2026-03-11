##########################################
### Purpose ###
##########################################

# For adding a backend pool from a different region than the region that the cross region load balancer sits in

### Change These Variables ###

#Regional
$RegionalFEName = "Epic-MyChartFSC-USEA2-FE"
#Example - $RegionalFEName = "Epic-CareEverywhereNonProd-USCE-FE"


#Global
$GlobalBEName = "Epic-MyChartFSC-USEA2-Global-BE"
#Example - $GlobalBEName = "Epic-CareEverywhereNonProd-USCE-Global-BE"

##########################################
### Don't Change Below This Line ###
##########################################


#Regional
$RegionalLBName = "epic-dr-region-pub"
$RegionalRGName = "rg-netsec-usea2-shr-b344"
$RegionalSubName = "hub-shr-ae99"


##Global
$GlobalLBName = "epic-global-pub"
$GlobalRGName = "shared-services-hub-prod-rg"
$GlobalSubName = "Shared Services Central"

######################################################################

##Regional Code
Set-AzContext -SubscriptionName $RegionalSubName

#Regional Load Balancer Information
$rlb = Get-AzLoadBalancer -Name $RegionalLBName -ResourceGroupName $RegionalRGName
$rlbfe=get-AzLoadBalancerFrontendIpConfig -Name $RegionalFEName -LoadBalancer $rlb
$rlbbaf = @{
    # name of the be pool on the global lb
    Name = $GlobalBEName
    LoadBalancerFrontendIPConfigurationId = $rlbfe.Id
}


##Global Code

Set-AzContext -SubscriptionName $GlobalSubName

$beaddressconfigRLB = New-AzLoadBalancerBackendAddressConfig @rlbbaf
$bepoolcr = @{
    ResourceGroupName = $GlobalRGName
    LoadBalancerName = $GlobalLBName
    Name = $GlobalBEName
    LoadBalancerBackendAddress = $beaddressconfigRLB
}
New-AzLoadBalancerBackendAddressPool @bepoolcr