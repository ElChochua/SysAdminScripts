Import-Module Z:Functions.psm1
Clear-Host
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Write-Host "INSTALADOR DE SERVICIOS HTTP"
$server_Ip = Get-IP-Address
$serverOption = Read-Host "¿Qué tipo de servidor deseas instalar? `n1) Apache2 `n2) Nginx `n3) IIS"
while ($true){
    if($serverOption -eq 1 -or $serverOption -eq 2 -or $serverOption -eq 3){
        break
    }else{
        $serverOption = Read-Host "Opcion no valida, porfavor ingresa una opcion valida"
    }
}
switch ($serverOption) {
    1{
        Write-Host "Apache2 `nQue version deseas instalar? `n1)LTS `n2)Apache 2.57"
        $apacheOption = Read-Host
        while ($true){
            if($apacheOption -eq 1 -or $apacheOption -eq 2){
                break
            }else{
                $apacheOption = Read-Host "Opcion no valida, porfavor ingresa una opcion valida"
            }
            
        }
        Set-Content STOP "Apache24" 2>$null
        Set-Content DELETE "Apache24" 2>$null 
        if ($apacheOption -eq 1) {
            <# Action to perform if the condition is true #>
            Stop-Service -Name "Apache*" -Force 2>$null
            Get-ChildItem -Path C:\ -Directory -Filter "Apache*" | Remove-Item -Recurse -Force
            (New-Object System.Net.WebClient).DownloadFile("https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250122-win64-VS17.zip", "C:\Users\Administrator\Downloads\serviceApache.zip")
            (New-Object System.Net.WebClient).DownloadFile("https://vcredist.com/install.ps1", "C:\Users\Administrator\Downloads\vc.ps1")
        }else{
            Stop-Service -Name "Apache*" -Force 2>$null
            Stop-Service -Name "Apache*" -Force 2>$null
            Get-ChildItem -Path C:\ -Directory -Filter "Apache*" | Remove-Item -Recurse -Force
            (New-Object System.Net.WebClient).DownloadFile("https://www.apachelounge.com/download/VS16/binaries/httpd-2.4.57-win64-VS16.zip", "C:\Users\Administrator\Downloads\serviceApache.zip")
            (New-Object System.Net.WebClient).DownloadFile("https://vcredist.com/install.ps1", "C:\Users\Administrator\Downloads\vc.ps1")
        }
        Set-Location "C:\Users\Administrator\Downloads"
        Expand-Archive ".\serviceApache.zip" -DestinationPath "C:\" -Force 
        .\vc.ps1
        Set-Location "C:\Apache24\bin"
            $httpdPath = 'C:\Apache24\conf\httpd.conf'
            .\httpd.exe -k install -n "Apache24"

        $port = Read-Host "Ingresa el puerto que deseas usar para APACHE: "
        while ($true){
            if(-not (Port-Is-Open($port) -and Port-Is-Valid($port))){
                break
            }else{
                $port = Read-Host "El puerto $port ya esta en uso, porfavor ingresa otro puerto"
            }
        }
        Remove-Item "C:\Users\Administrator\Downloads\serviceApache.zip"
        Remove-Item "C:\Users\Administrator\Downloads\vc.ps1"
                $fileContent = Get-Content -Path $httpdPath
                $fileContent = $fileContent -replace 'Listen 80', "Listen $port"
                $fileContent = $fileContent -replace '#LoadModule include_module modules/mod_include.so', "LoadModule include_module modules/mod_include.so"
                $fileContent = $fileContent -replace '#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so', "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so"
                $fileContent | Set-Content -Path $httpdPath

        net start "Apache24"

        Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
        break
    }
    2{
        Write-Host "NgInx `nQue version deseas instalar? `n1)Stable `n2)Mainline"
        $nginxOption = Read-Host
        while ($true){
            if($nginxOption -eq 1 -or $nginxOption -eq 2){
                break
            }else{
                $nginxOption = Read-Host "Opcion no valida, porfavor ingresa una opcion valida"
            }
            
        }
        taskkill /F /IM nginx.exe > $null 2>&1
        Stop-Service -Name "nginx*" -Force 2>$null
        if ($nginxOption -eq 1) {
            <# Action to perform if the condition is true #>
            Get-ChildItem -Path C:\ -Directory -Filter "nginx*" | Remove-Item -Recurse -Force
            (New-Object System.Net.WebClient).DownloadFile("https://nginx.org/download/nginx-1.26.2.zip", "C:\Users\Administrator\Downloads\serviceNginx.zip")
            Set-Location "C:\Users\Administrator\Downloads" 
            Expand-Archive ".\serviceNginx.zip" -DestinationPath "C:\" -Force 
            Set-Location "C:\nginx-1.26.2"
            $confPath = "C:\nginx-1.26.2\conf\nginx.conf"
        }elseif ($nginxOption -eq 2){
            <# Action to perform if the condition is true #>
            Get-ChildItem -Path C:\ -Directory -Filter "nginx*" | Remove-Item -Recurse -Force
            (New-Object System.Net.WebClient).DownloadFile("https://nginx.org/download/nginx-1.27.3.zip", "C:\Users\Administrator\Downloads\serviceNginx.zip")
            Set-Location "C:\Users\Administrator\Downloads"
            Expand-Archive ".\serviceNginx.zip" -DestinationPath "C:\" -Force
            Set-Location "C:\nginx-1.27.3"
            $confPath = "C:\nginx-1.27.3\conf\nginx.conf"
        }
        $port = Read-Host "Ingresa el puerto que deseas usar: "
        while ($true){
            if(-not (Port-Is-Open($port) -and Port-Is-Valid($port))){
                break
            }else{
                $port = Read-Host "El puerto $port ya esta en uso, porfavor ingresa otro puerto"
            }
        } 
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
                #server {
                #    listen       443 ssl;
                #    server_name  localhost;
                #    ssl_certificate      certificate_path;
                #    ssl_certificate_key  certificate_key_path;
                #    ssl_session_cache    shared:SSL:1m;
                #    ssl_session_timeout  5m;
                #    ssl_ciphers  HIGH:!aNULL:!MD5;
                #    ssl_prefer_server_ciphers  on;
                #    location / {
                #        root   html;
                #        index  index.html index.htm;
                #    }
                #}

            }
"@
        Set-Content -Path $confPath -Value $insert_config -Force
        Remove-Item "C:\Users\Administrator\Downloads\serviceNginx.zip"
        $server_Ip = Get-IP-Address
        Start-Process ".\nginx.exe"
        tasklist /fi "imagename eq nginx.exe"
        .\nginx.exe -s reload
        Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
        break
    }
    3{
        Install-WindowsFeature web-server -IncludeManagementTools > $null 2>&1
        Import-Module WebAdministration
        mkdir C:\Sites\ 2>$null
        $siteName = Read-Host "Ingresa el nombre del sitio web: "
        mkdir C:\Sites\$siteName 2>$null
        $port = Read-Host "Ingresa el puerto que deseas usar: "
        while ($true){
            if(-not (Port-Is-Open($port) -and Port-Is-Valid($port))){
                break
            }else{
                $port = Read-Host "El puerto $port ya esta en uso, porfavor ingresa otro puerto"
            }
        }
        $pageContent = @"
        <html>
            <head>
                <title>$siteName</title>
            </head>
            <body>
                <h1>¡Hola Mundo!</h1>
                <h2>Desde $siteName</h2>
                <p>Este es un servidor web de prueba</p>
            </body>

"@
        New-WebSite -Name "$siteName" -Port $port -PhysicalPath "C:\Sites\$siteName" -ApplicationPool "DefaultAppPool"
        New-WebBinding -Name "$siteName" -IPAddress "*" -Port $port -HostHeader "$siteName" -Protocol "http" 
        Start-WebSite -Name "$siteName"
        Set-Content -Path "C:\Sites\$siteName\index.html" -Value $pageContent
        Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
    }
    Default {
        Write-Host "Opcion no valida" -ForegroundColor Red
    }
}