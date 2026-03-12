# 1. Get current subscription context
$subId = (Get-AzContext).Subscription.Id

# 2. Call the REST API for locations
$uri = "/subscriptions/$subId/locations?api-version=2022-12-01"
$response = Invoke-AzRestMethod -Method GET -Path $uri

# 3. Parse JSON content and filter
$data = ($response.Content | ConvertFrom-Json).value

$results = $data | Where-Object { 
    ($_.name -eq "centralus" -or $_.name -eq "eastus2") -and 
    ($null -ne $_.availabilityZoneMappings) 
} | Select-Object @{Name="Region"; Expression={$_.displayName}}, 
                @{Name="Slug"; Expression={$_.name}}, 
                @{Name="Mappings"; Expression={$_.availabilityZoneMappings}}

# 4. Display results
$results | Format-List