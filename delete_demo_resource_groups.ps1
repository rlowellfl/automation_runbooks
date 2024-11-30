# The following PowerShell runbook queries all Azure Resource Groups in a given subscription with a tag and value matching the parameters ('Demo-Delete' and 'True' by default).
# All matching RGs, including all contained resources, are deleted


##########################
# Parameters and Variables
##########################

Param(
    [Parameter (Mandatory = $true)]
    [string]$subscription,
    [string]$tagName = "Demo-Delete",
    [string]$tagValue = "True",
    [string]$managedIdentityType = "SA"
)


##############################
# Log in with Managed Identity
##############################

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect using a Managed Service Identity
try {
    $AzureContext = (Connect-AzAccount -Identity).context
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
    Write-Output "There is no system-assigned user identity. Aborting."; 
    exit
}

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $subscription `
    -DefaultProfile $AzureContext

if ($managedIdentityType -eq "SA") {
    Write-Output "Using system-assigned managed identity"
}
elseif ($managedIdentityType -eq "UA") {
    Write-Output "Using user-assigned managed identity"

    # Connects using the Managed Service Identity of the named user-assigned managed identity
    $identity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroup `
        -Name $UAMI -DefaultProfile $AzureContext

    # validates assignment only, not perms
    if ((Get-AzAutomationAccount -ResourceGroupName $resourceGroup `
                -Name $automationAccount `
                -DefaultProfile $AzureContext).Identity.UserAssignedIdentities.Values.PrincipalId.Contains($identity.PrincipalId)) {
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
    Write-Output "Invalid managed identity type. Choose UA or SA."
    exit
}


####################
# Primary operations
####################

# Get Resource Groups with deletion tag
try {
    $resourceGroup = Get-AzResourceGroup -Tag @{$tagName = $tagValue } | ForEach-Object {
        Remove-AzResourceGroup -Force       
    }
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}