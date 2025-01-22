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
function get_all_zones(){
    return (Get-DnsServerZone | Select-Object -ExpandProperty ZoneName)

}
$zones =get_all_zones
for ($i = 0; $i -lt $zones.Count; $i++) {
    <# Action that will repeat until the condition is met #>
    Write-Host "$i.- $($zones[$i])"
}
$choise = Read-Host
Write-Host $zones[$choise]