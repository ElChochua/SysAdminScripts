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
$available_zones = Get-All-Zones
Clear-Host
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Write-Host "INSTALADOR DE SERVICIOS HTTP"
$server_Ip = Get-IP-Address
$serverOption = Read-Host "¿Qué tipo de servidor deseas instalar? `n1) Apache 2 `n2) Nginx `n3) IIS"
switch ($serverOption) {
    1{
        Write-Host "Apache 2 `nQue version deseas instalar? `n1)LTS `n2)dev-build"
        $apacheOption = Read-Host
        if ($apacheOption -eq 1) {
            <# Action to perform if the condition is true #>
            (New-Object System.Net.WebClient).DownloadFile("https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250122-win64-VS17.zip", "C:\Users\Administrator\Downloads\serviceApache.zip")
            (New-Object System.Net.WebClient).DownloadFile("https://vcredist.com/install.ps1", "C:\Users\Administrator\Downloads\vc.ps1")
        }else{
            (New-Object System.Net.WebClient).DownloadFile("https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250122-win64-VS17.zip", "C:\Users\Administrator\Downloads\serviceApache.zip")
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
        $sport = Read-Host "Agrega un puerto para el HTTPS: "
        while ($true){
            if(-not (Port-Is-Open($sport))){
                break
            }else{
                $sport = Read-Host "El puerto $sport ya esta en uso, porfavor ingresa otro puerto"
            }
        }
        $server_name = Read-Host "Ingresa el nombre del Dominio: "
        Remove-Item "C:\Users\Administrator\Downloads\serviceApache.zip"
        Remove-Item "C:\Users\Administrator\Downloads\vc.ps1"
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
        $apache_key_path = "C:\Apache24\bin\apache.key"
        $apache_crt_path = "C:\Apache24\bin\apache.crt"
        & "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" req -x509 -nodes -newkey rsa:2048 -keyout $apache_key_path -out $apache_crt_path -days 365
                $httpdPath = 'C:\Apache24\conf\httpd.conf'
                $fileContent = Get-Content -Path $httpdPath
                $fileContent = $fileContent -replace 'Listen 80', "Listen $port"
                $fileContent = $fileContent -replace '#LoadModule include_module modules/mod_include.so', "LoadModule include_module modules/mod_include.so"
                $fileContent = $fileContent -replace '#LoadModule ssl_module modules/mod_ssl.so', "LoadModule ssl_module modules/mod_ssl.so"
                $fileContent = $fileContent -replace '#Include conf/extra/httpd-default.conf', "Include conf/extra/httpd-default.conf"
                $fileContent = $fileContent -replace '#Include conf/extra/httpd-ssl.conf', "Include conf/extra/httpd-ssl.conf" 
                $fileContent = $fileContent -replace '#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so', "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so"
                $fileContent | Set-Content -Path $httpdPath

                $sslConfig = 'C:\Apache24\conf\extra\httpd-ssl.conf'
                $sslContent = Get-Content -Path $sslConfig
                $sslContent = $sslContent -replace 'Listen 443', "Listen $sport https"
                $sslContent = $sslContent -replace '<VirtualHost _default_:443>', "<VirtualHost _default_:$sport>"
                $sslContent = $sslContent.Replace('${SRVROOT}/conf/server.crt', "$apache_crt_path")
                $sslContent = $sslContent.Replace('${SRVROOT}/conf/server.key', "$apache_key_path")
                $sslContent | Set-Content -Path $sslConfig
        net start "Apache24LTS"
        Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
        Write-Host "https://$($server_Ip):$($sport)" -ForegroundColor Green
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
        $sport = Read-Host "Agrega un puerto para el HTTPS: "
        while ($true){
            if(-not (Port-Is-Open($sport))){
                break
            }else{
                $sport = Read-Host "El puerto $sport ya esta en uso, porfavor ingresa otro puerto"
            }
        }
        $certificate_path = "C:/nginx-1.26.2/cert.pem"
        $certificate_key_path = "C:/nginx-1.26.2/cert.key"
        & "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" req -x509 -nodes -newkey rsa:2048 -keyout $certificate_key_path -out $certificate_path -days 365
        $dnsChoise = Read-Host "Quieres añadir tu Dominio al Servidor DNS?"        
        $insert_config = @"
        worker_processes  1;
        events {
            worker_connections  1024;
        }
            http{
                include       mime.types;
                default_type  application/octet-stream;
                sendfile        on;
                keepalive_timeout  65;
                server{
                    listen       $port;
                    server_name  localhost;
                    error_page   500 502 503 504  /50x.html;
                    location / {
                        root   html;
                        index  index.html index.htm;
                    }
                    
                }
                #HTTPS server
                server {
                    listen       $sport ssl;
                    server_name  localhost;
                    ssl_certificate      $certificate_path;
                    ssl_certificate_key  $certificate_key_path;
                    ssl_session_cache    shared:SSL:1m;
                    ssl_session_timeout  5m;
                    ssl_ciphers  HIGH:!aNULL:!MD5;
                    ssl_prefer_server_ciphers  on;
                    location / {
                        root   html;
                        index  index.html index.htm;
                    }
                }

            }
"@
        Set-Content -Path $confPath -Value $insert_config -Force

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
        Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
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
        $sport = Read-Host "Agrega un puerto para el HTTPS: "
        while ($true){
            if(-not (Port-Is-Open($sport))){
                break
            }else{
                $sport = Read-Host "El puerto $sport ya esta en uso, porfavor ingresa otro puerto"
            }
        }
        $certificate = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $server_Ip -FriendlyName "Self-Signed-Certificate"
        Set-WebBinding -Name "Default Web Site" -PropertyName "Port" -Value "$port"
        New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port $sport -Protocol "https"
        $webSite = Get-WebBinding -Name "Default Web Site" -Protocol "https"
        $webSite.AddSslCertificate($certificate.GetCertHashString(), "My")
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
        Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
        Write-Host "https://$($server_Ip):$($sport)" -ForegroundColor Green
    }
    Default {
        Write-Host "Opcion no valida" -ForegroundColor Red
    }
}