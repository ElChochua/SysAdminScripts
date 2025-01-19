function ip_default_gateway {
    param($ip)
    $ip = $ip -split "\."
    $ip[3] = 1
    $ip -join "."
}
function ip_root {
    param($ip)
    $ip = $ip -split "\."
    $ip[3] = 0
    $ip -join "."
}
function get_all_adapters{
    Get-NetAdapter | Select-Object -ExpandProperty Name
}
$ips = "192.168.1.5"
try {
    Write-Host $(ip_default_gateway($ips)) $(ip_root($ips))
}
catch {
    <#Do this if a terminating exception happens#>
    Write-Host "wew"
    Write-Host $_.Exception.Message
}