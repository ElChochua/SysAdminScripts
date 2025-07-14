Import-Module Z:\Functions.psm1 -Force
Install-WindowsFeature -Name DHCP -IncludeManagementTools
#Install-ADDSForest -DomainName YOURDOMAINHERE -InstallDNS
$adapters = get_all_adapters
if ($adapters -ne $null) {
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
    $dhcp_name = Read-Host "Ingrese un nombre a su servidor DHCP" 
    Write-Host "================================NOTA===================================== 
    `n` La direccion IP que asignes al servidor debe ser de la misma familia de la direccion IP estatica antes asignada EJ. 
    `n` Static: 192.168.1.5 Server: 192.168.1.0"
    $initial_range = Read-Host "Ingresa el rango inicial"
    $final_range = Read-Host "Ingresa el rango final"
    $netmask = Read-Host "Ingresa la mascara de la red"
    $adapter_ip = get_adapter_ip($adapters[$option])
    Write-Host $adapter_ip
    Write-Host $root_ip
    try {
        Add-DhcpServerv4Scope -Name $dhcp_name -StartRange $initial_range -EndRange $final_range -SubnetMask $netmask -State Active
        Set-DhcpServerv4OptionValue -ScopeId $root_ip -OptionId 3 -Value $default_gateway
        Set-DhcpServerv4OptionValue -ScopeId $root_ip -OptionId 6 -Value  $adapter_ip -Force
        Get-Service DHCPServer
        Write-Host "DHCP agregado con exito" -ForegroundColor Green
        Get-DhcpServerv4Scope
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host "Error al crear DHCP" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
else {
    Write-Host "No hay Adaptadores disponibles porfavor verifica que esten conectados correctamente"
    break
}
