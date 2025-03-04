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
function get_all_adapters {
    Get-NetAdapter | Select-Object -ExpandProperty Name
}
function get_adapter_ip{
    param($adapter)
    return (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $adapter).IPAddress
}
function saludar{
    param ([string]$nombre)
    Write-Host "Hola $nombre"
}
function get_all_adapters {
    Get-NetAdapter | Select-Object -ExpandProperty Name
}
function get_adapter_ip_addresss{
    param($adapter_name)
    return (Get-NetIPAddress | Where-Object {$_.InterfaceAlias -eq $adapter_name}).IPAddress[1]
}
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
function get_last_octet{
    param($ip)
    $ip = $ip -split "\."
    $octeto = $ip[3]
    return $octeto 
}
function reverse_ip {
    param($ip)
    $IPBytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
    $IPBytes = $IPBytes[0..($IPBytes.Length - 2)] 
    [Array]::Reverse($IPBytes)  
    $IPBytes -join '.'
}
function Get-IP-Address{
    return (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
}
function Port-Is-Open{
    param($port)
    return (Test-NetConnection -ComputerName $env:COMPUTERNAME -Port $port -InformationLevel Quiet)
}
function Get-All-Zones(){
    return (Get-DnsServerZone | Select-Object -ExpandProperty ZoneName)

}
function valdiate-username{
    param($user)
    if ($user -match "^[a-zA-Z0-9_]{3,16}$"){
        return $true
    }
    return $false
}
function user-exists{
    param($user)
    $users = Get-LocalUser
    if (Get-LocalUser -Name $user -ErrorAction SilentlyContinue){
        return $true
    }
    return $false
}
function validate-password{
    param($password)
    if ($password -match "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$"){
        return $true
    }
    return $false
}
function user-is-not-in-groups{
    param($userName)
    $userGroups = (Get-LocalGroupMember -Group "reprobados" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $userName }) + 
              (Get-LocalGroupMember -Group "recursados" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $userName })

    if ($userGroups.Count -eq 0) {
        return $true
    }
return $false
}

Export-ModuleMember -Function saludar
Export-ModuleMember -Function get_all_adapters
Export-ModuleMember -Function get_adapter_ip
Export-ModuleMember -Function ip_default_gateway
Export-ModuleMember -Function ip_root
Export-ModuleMember -Function get_adapter_ip_addresss
Export-ModuleMember -Function get_last_octet
Export-ModuleMember -Function reverse_ip
Export-ModuleMember -Function Get-IP-Address
Export-ModuleMember -Function Port-Is-Open
Export-ModuleMember -Function Get-All-Zones
Export-ModuleMember -Function valdiate-username
Export-ModuleMember -Function user-exists
Export-ModuleMember -Function validate-password
Export-ModuleMember -Function user-is-not-in-groups

