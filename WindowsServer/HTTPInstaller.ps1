function Get-IP-Address{
    return (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
}
function Port-Is-Open{
    param($port)
    return (Test-NetConnection -Port $port -InformationLevel Quiet)
}
function Get-All-Zones(){
    return (Get-DnsServerZone | Select-Object -ExpandProperty ZoneName)

}
$available_zones = Get-All-Zones
Clear-Host
Write-Host "INSTALADOR DE SERVICIOS HTTP"
$server_Ip = Get-IP-Address
$serverOption = Read-Host "¿Qué tipo de servidor deseas instalar? `n1) Apache 2 `n2) Nginx `n3) IIS"
switch ($serverOption) {
    1{
        Write-Host "Apache 2 `nQue version deseas instalar? `n1)LTS `n2)dev-build"
        $apacheOption = Read-Host
        if ($apacheOption -eq 1) {
            <# Action to perform if the condition is true #>
            (New-Object System.Net.WebClient).DownloadFile("https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.62-240904-win64-VS17.zip", "C:\Users\Administrator\Downloads\serviceApache.zip")
            (New-Object System.Net.WebClient).DownloadFile("https://vcredist.com/install.ps1", "C:\Users\Administrator\Downloads\vc.ps1")
        }else{
            (New-Object System.Net.WebClient).DownloadFile("https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.62-240904-win64-VS17.zip", "C:\Users\Administrator\Downloads\serviceApache.zip")
            (New-Object System.Net.WebClient).DownloadFile("https://vcredist.com/install.ps1", "C:\Users\Administrator\Downloads\vc.ps1")
        }
        Set-Location "C:\Users\Administrator\Downloads"
        Expand-Archive ".\serviceApache.zip" -DestinationPath "C:\"
        .\vc.ps1
        Set-Location "C:\Apache24\bin"
        .\httpd.exe -k install -n "Apache24LTS"
        $port = Read-Host "Ingresa el puerto que deseas usar para APACHE: "
        while ($true){
            if(-not (Port-Is-Open($port))){
                break
            }else{
                $port = Read-Host "El puerto $port ya esta en uso, porfavor ingresa otro puerto"
            }
        }
        $server_name = Read-Host "Ingresa el nombre del Dominio: "
        $confPath = "C:\Apache24\conf\httpd.conf"
        $fileContent = Get-Content $confPath
        $fileContent = $fileContent -replace "Listen 80", "Listen $port"
        $fileContent | Set-Content -Path $confPath
        Remove-Item "C:\Users\Administrator\Downloads\serviceApache.zip"
        Remove-Item "C:\Users\Administrator\Downloads\vc.ps1"
        net start "Apache24LTS"
        $dnsChoise = Read-Host "Quieres añadir tu Dominio al Servidor DNS?"
        if($dnsChoise -eq 1){
            for ($i = 0; $i -lt $available_zones.Count; $i++) {
                <# Action that will repeat until the condition is met #>
                Write-Host "$i.- $($available_zones[$i])"
            }
            $selected_dns = Read-Host "Selecciona la zona a la que quieres añadir tu dominio: "
            Add-DnsServerResourceRecordA -ZoneName "$($available_zones[$selected_dns])" -Name "$($server_name)" -IPv4Address "$($server_Ip)"
        }else{
            Clear-Host
        }
        Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
        break
    }
    2{
        Write-Host "NgInx `nQue version deseas instalar? `n1)Stable `n2)Mainline"
        $nginxOption = Read-Host
        if ($nginxOption -eq 1) {
            <# Action to perform if the condition is true #>
            (New-Object System.Net.WebClient).DownloadFile("https://nginx.org/download/nginx-1.26.2.zip", "C:\Users\Administrator\Downloads\serviceNginx.zip")
            Set-Location "C:\Users\Administrator\Downloads"
            Expand-Archive ".\serviceNginx.zip" -DestinationPath "C:\"
            Set-Location "C:\nginx-1.26.2"
            $confPath = "C:\nginx-1.26.2\conf\nginx.conf"
        }elseif ($nginxOption -eq 2){
            <# Action to perform if the condition is true #>
            (New-Object System.Net.WebClient).DownloadFile("https://nginx.org/download/nginx-1.27.3.zip", "C:\Users\Administrator\Downloads\serviceNginx.zip")
            Set-Location "C:\Users\Administrator\Downloads"
            Expand-Archive ".\serviceNginx.zip" -DestinationPath "C:\"
            Set-Location "C:\nginx-1.27.3"
            $confPath = "C:\nginx-1.27.3\conf\nginx.conf"
        }
        $port = Read-Host "Ingresa el puerto que deseas usar para NGINX: "
        while ($true){
            if(-not (Port-Is-Open($port))){
                break
            }else{
                $port = Read-Host "El puerto $port ya esta en uso, porfavor ingresa otro puerto"
            }
        }
        $dnsChoise = Read-Host "Quieres añadir tu Dominio al Servidor DNS?"
        $fileContent = Get-Content $confPath
        $fileContent = $fileContent -replace "listen       80;", "listen       $port;"
        $fileContent | Set-Content -Path $confPath
        Remove-Item "C:\Users\Administrator\Downloads\serviceNginx.zip"
        $server_Ip = Get-IP-Address
        Start-Process ".\nginx.exe"
        tasklist /fi "imagename eq nginx.exe"
        .\nginx.exe -s reload
        if($dnsChoise -eq 1){
            for ($i = 0; $i -lt $available_zones.Count; $i++) {
                <# Action that will repeat until the condition is met #>
                Write-Host "$i.- $($available_zones[$i])"
            }
            $selected_dns = Read-Host "Selecciona la zona a la que quieres añadir tu dominio: "
            $server_name = Read-Host "Ingresa el nombre del Dominio: "
            Add-DnsServerResourceRecordA -ZoneName "$($available_zones[$selected_dns])" -Name "$($server_name)" -IPv4Address "$($server_Ip)"
        }else{
            Clear-Host
        }

        break
    }
    3{
        Install-WindowsFeature web-server -IncludeManagementTools > $null 2>&1
        $port = Read-Host "Ingresa el puerto que deseas usar: "
        while ($true){
            if(-not (Port-Is-Open($port))){
                break
            }else{
                $port = Read-Host "El puerto $port ya esta en uso, porfavor ingresa otro puerto"
            }
        }
        $bindingInformation = (Get-WebBinding | Select-Object -ExpandProperty BindingInformation)
         Set-WebBinding -Name "Default Web Site" -BindingInformation "$bindingInformation" -PropertyName "Port" -Value "$port"
        $dnsChoise = Read-Host "Quieres añadir tu Dominio al Servidor DNS?"
        if($dnsChoise -eq 1){
            for ($i = 0; $i -lt $available_zones.Count; $i++) {
                <# Action that will repeat until the condition is met #>
                Write-Host "$i.- $($available_zones[$i])"
            }
            $selected_dns = Read-Host "Selecciona la zona a la que quieres añadir tu dominio: "
            $server_name = Read-Host "Ingresa el nombre del Dominio: "
            Add-DnsServerResourceRecordA -ZoneName "$($available_zones[$selected_dns])" -Name "$($server_name)" -IPv4Address "$($server_Ip)"
        }else{
            Clear-Host
        }
    }
    Default {
        Write-Host "Opcion no valida" -ForegroundColor Red
    }
}