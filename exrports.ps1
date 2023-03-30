# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

$storageAccount = Get-AzStorageAccount -ResourceGroupName "exr-ports-fcn" -AccountName "exrportsweb456457657"
$ctx = $storageAccount.Context

$erloclist = Get-AzExpressRoutePortsLocation

[System.Collections.ArrayList]$locations = $erloclist
$locations.RemoveAt(3)
$locations.RemoveAt(8)

foreach ($location in $locations) {
    $bw = Get-AzExpressRoutePortsLocation -LocationName $location.Name
    $value = New-Object -TypeName PSObject -Property @{ 
        Provider = $bw.Name; 
        AvailableBandwidths = ""+$bw.AvailableBandwidths.OfferName; 
        Address = $bw.Address 
    }
    if ($locarray) {
        $locarray += @($value)  
    } else {
        $locarray = @($value)
    }
}

$Header = @"
<title>ExpressRouteDirect Availability</title>
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

$locarray | ConvertTo-Html -Head $Header -Property Provider, AvailableBandwidths, Address | Out-File "index.html"

Add-Content -Path "index.html" -Value "<br><b>Last Updated: $(Get-Date) UTC</b>" -PassThru

# upload a file
set-AzStorageblobcontent -File "index.html" `
-Container `$web `
-Blob "index.html" `
-Context $ctx `
-Properties @{"ContentType" = "text/html"} `
-Force
