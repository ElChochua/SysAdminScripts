Import-Module .\Functions.psm1
$ips = get-all-ip-addresses
Write-Host "IPs: $ips"