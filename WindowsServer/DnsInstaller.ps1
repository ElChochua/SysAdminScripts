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

$adapters = get_all_adapters
Install-WindowsFeature -Name DNS -IncludeManagementTools
Install-WindowsFeature -NAME RSAT-DNS-Server

Get-WindowsFeature -Name DNS
if($adapters -ne $null){
    $configure = Read-Host "Quieres configurar un adaptador con una IP estatica = [S/n]"
    if($configure -eq "s"){
        Write-Host "Seleccione un adaptador"
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            Write-Host "[$i]: $($adapters[$i])"
        }
        $option = Read-Host
        $ip_static = Read-Host "Ingresa una direccion IP estatica para el adaptador" 
        $default_gateway = ip_default_gateway($ip_static)
        $root_ip = ip_root($ip_static)
        New-NetIPAddress -InterfaceAlias $adapters[$option] -IPAddress $ip_static -PrefixLength 24 -DefaultGateway $default_gateway
        Set-DnsClientServerAddress -InterfaceAlias $adapters[$option] -ServerAddresses 8.8.8.8,8.8.4.4
        Write-Host "Se ha configurado el IP estatico del adaptador"
        $IPV4Address = $ip_static
    }else{
    Write-Host "Seleccione un adaptador"
    for ($i = 0; $i -lt $adapters.Count; $i++) {
        Write-Host "[$i]: $($adapters[$i])"
    }
    $option = Read-Host
    $IPV4Address = get_adapter_ip_addresss($adapters[$option])
    $default_gateway = ip_default_gateway($IPV4Address)
    $root_ip = ip_root($IPV4Address)
    }
    Write-Host $last_octet
    $reversed = reverse_ip($IPV4Address)
    $zone_name = Read-Host "Ingresa el nombre de tu zona  EJ. example.local"
    $zone_file = Read-Host "Ingresa el nombre del archivo donde guardaras los datos de zona EJ. example.local.dns"
    $server_name = Read-Host "Ingresa el Nombre del Servidor EJ. server1"
    $DNS_Point_IP = Read-Host "Ingresa la IP a la que apuntara el registro"
    $last_octet = get_last_octet($DNS_Point_IP)
    try {
        Add-DnsServerPrimaryZone -Name "$($zone_name)" -ZoneFile "$($zone_file)"
        Add-DnsServerResourceRecordA -ZoneName "$($zone_name)" -Name "$($server_name)" -IPv4Address "$($IPV4Address)"
        
        if(-not(Get-DnsServerZone | Where-Object {$_.ZoneName -eq "$($reversed).in-addr.arpa"} -ne $null)){
            Add-DnsServerPrimaryZone -NetworkId "$($root_ip)/24" -ZoneFile "$($reversed).in-addr.arpa.dns"
            Add-DnsServerResourceRecordPtr -ZoneName "$($reversed).in-addr.arpa" -Name "$($last_octet)" -PtrDomainName "$($server_name).$($zone_name)"
        }
        Add-DnsServerResourceRecordCName -ZoneName "$($zone_name)" -Name "www" -HostNameAlias "$($server_name).$($zone_name)"
        Start-Sleep -s 1
        Get-DnsServerZone
        Start-Sleep -s 1
        Get-DnsServerResourceRecord -ZoneName "$($zone_name)"
    
    }
    catch {
        Write-Host "Error al agregar servidor DNS" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}else{
    Write-Host "NO SE ENCONTRARON ADAPADORES REVISE SUS CONEXIONES"
}
