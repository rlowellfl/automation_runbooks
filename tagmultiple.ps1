# The following commands will append tags to multiple resources of a given type within a single resource group.

$RG = "YourResourceGroupGoesHere"
$type = "Microsoft.HybridCompute/machines"
$tags = @{"Key1" = "Value1"; "Key2" = "Value2" }

$resource = Get-AzResource -resourcetype $type -ResourceGroupName $RG
$resource | ForEach-Object { Update-AzTag -Tag $tags -ResourceId $_.ResourceId -Operation Merge }