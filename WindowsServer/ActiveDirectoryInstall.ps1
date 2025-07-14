Import-Module Z:\Functions.psm1 -Force

Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools
$adapters = (Get-NetAdapter | Select-Object -ExpandProperty Name)
$choise = Read-Host "Quieres agregar una direccion IP estatica ahora ? [S/N]"
if($choise -eq "s"){
    if ($adapters -ne $null) {
        Write-Host "Seleccione un adaptador"
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            Write-Host "[$i]: $($adapters[$i])"
        }
        $option = Read-Host    
        $ip_static = Read-Host "Ingresa una direccion IP estatica para el adaptador" 
        $default_gateway = ip_default_gateway($ip_static)
        New-NetIPAddress -InterfaceAlias $adapters[$option] -IPAddress $ip_static -PrefixLength 24 -DefaultGateway $default_gateway
        Set-DnsClientServerAddress -InterfaceAlias $adapters[$option] -ServerAddresses 8.8.8.8,8.8.4.4
    }
}
$domain = Read-Host -Prompt "Nombre del Dominio: "
while (Is-Valid-DomainName -domainName $domain -eq $false) {
    $domain = Read-Host -Prompt "Nombre del Dominio: "
    if (Is-Valid-DomainName domainName $domain) {
        break;
    }
}

Install-ADDSForest -DomainName "reprobados.com" -DomainNetbiosName "reprobados" -InstallDNS: $true -CreateDNSDelegation: $false -DatabasePath "C:\NTDS" -SysvolPath "C:\SYSVOL" -LogPath "C:\NTDS" -Force
