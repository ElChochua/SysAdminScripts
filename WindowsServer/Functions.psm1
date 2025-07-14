
function saludar {
    param ([string]$nombre)
    Write-Host "Hola $nombre"
}
$ftp_route = "ftp://localhost/General/Resources"
function get_all_adapters {
    Get-NetAdapter | Select-Object -ExpandProperty Name
}

function get_adapter_ip {
    param($adapter)
    return (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $adapter).IPAddress
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

function get_adapter_ip_address {
    param($adapter_name)
    return (Get-NetIPAddress | Where-Object { $_.InterfaceAlias -eq $adapter_name }).IPAddress[1]
}

function get_last_octet {
    param($ip)
    $ip = $ip -split "\."
    return $ip[3]
}

function reverse_ip {
    param($ip)
    $IPBytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
    [Array]::Reverse($IPBytes)
    return $IPBytes -join '.'
}

function Get-IP-Address {
    return (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet 2").IPAddress
}

function Test-PortOpen {
    param($port)
    
    return (Get-NetTCPConnection | where Localport -eq $port | select Localport, OwningProcess)
}

function Test-PortValid {
    param($port)
    return ((Test-PortOpen -port $port) -and (In-CommonPorts -port $port) -and ($port -ge 1 -and $port -le 65535))
}

function Get-All-Zones {
    return (Get-DnsServerZone | Select-Object -ExpandProperty ZoneName)
}

function Validate-Username {
    param($user)
    return $user -match "^[a-zA-Z0-9_]{3,16}$"
}

function Test-UserExists {
    param($user)
    return [bool](Get-LocalUser -Name $user -ErrorAction SilentlyContinue)
}

function Validate-Password {
    param($password)
    return $password -match "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$"
}

function Test-UserNotInGroups {
    param($userName)
    $userGroups = @(Get-LocalGroupMember -Group "reprobados" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $userName }) +
    @(Get-LocalGroupMember -Group "recursados" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $userName })

    return ($userGroups.Count -eq 0)
}

function Get-TomcatVersions {
    param([int]$version, [int]$download_source)
    if ($download_source -eq 1) {

        $url = "https://dlcdn.apache.org/tomcat/tomcat-$version/"
        $html = Invoke-WebRequest  $url  -Verbose -UseBasicParsing 
        $versions = $html.Links.href | Where-Object { $_ -match "^v$version\.\d+\.\d+/$" }
        $versions = $versions -replace "^v|/$", ""
    }
    else {
        #Get The version from the ftp server
        $ftpUrl = "$ftp_route/tomcat/$version/"
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        $ftpRequest = [System.Net.FtpWebRequest]::Create($ftpUrl)
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $ftpRequest.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous")
        $ftpRequest.EnableSsl = $true

        $ftpResponse = $ftpRequest.GetResponse()
        $ftpStream = $ftpResponse.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($ftpStream)
        $entries = $reader.ReadToEnd().Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

        $versions = $entries |
        Where-Object { $_ -match '^apache-tomcat-(\d+\.\d+\.\d+)-windows-x64\.zip$' } |
        ForEach-Object {
            if ($_ -match '^apache-tomcat-(\d+\.\d+\.\d+)-windows-x64\.zip$') {
                $matches[1]
            }
        }
    }
    return , $versions
}

function Install-Tomcat {
    param([string]$version, [string]$version_number, [int]$download_source)
    Purge-Service -service_name "Tomcat"
    Start-Sleep -Seconds 3
    $url = "https://dlcdn.apache.org/tomcat/tomcat-$version/v$version_number/bin/apache-tomcat-$version_number-windows-x64.zip"
    $outputPath = "C:\Users\Administrator\Downloads\tomcat.zip"
    $extractPath = "C:\Users\Administrator\Downloads\Tomcat"
    $tomcatPath = "C:\Tomcat"
    $confFile = "$tomcatPath\conf\server.xml"
    $pattern = '(?s)<!--\s*(<Connector\s+port="8443".*?</Connector>)\s*-->'
    $keystorePath = "C:\Tomcat\conf\keyStore.jks"
    $javaPath = "C:\Program Files\Java\jdk-21"

    if (-not (Test-Path -Path $tomcatPath)) {
        New-Item -Path $tomcatPath -ItemType Directory
    }
    if (-not (Test-Path -Path $extractPath)) {
        New-Item -Path $extractPath -ItemType Directory
    }
    if ($download_source -eq 1) {
        (New-Object System.Net.WebClient).DownloadFile($url, $outputPath)
    }
    elseif ($download_source -eq 2) {
        #Get The version from the ftp server
        # Ruta del archivo FTP (ajusta nombre y extensión)
        $ftpFileUrl = "$ftp_route/tomcat/$version/apache-tomcat-$version_number-windows-x64.zip"
        Write-Host "Descargando Tomcat desde: $ftpFileUrl"
        # Ruta local donde guardar el archivo

        # Permitir certificados autofirmados (solo pruebas)
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        # Crear solicitud FTP con método DownloadFile
        $ftpRequest = [System.Net.FtpWebRequest]::Create($ftpFileUrl)
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
        $ftpRequest.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous")
        $ftpRequest.EnableSsl = $true

        # Obtener respuesta y escribir en archivo local
        $ftpResponse = $ftpRequest.GetResponse()
        $ftpStream = $ftpResponse.GetResponseStream()
        $localFileStream = [System.IO.File]::Create($outputPath)

        $buffer = New-Object byte[] 10240
        do {
            $read = $ftpStream.Read($buffer, 0, $buffer.Length)
            $localFileStream.Write($buffer, 0, $read)
        } while ($read -gt 0)

        # Cerrar flujos
        $localFileStream.Close()
        $ftpStream.Close()
        $ftpResponse.Close()

        Write-Host "✅ Archivo descargado correctamente en: $localPath"
    } 
    #Check if the file is downloaded
    if (-not (Test-Path -Path $outputPath)) {
        Write-Host "No se pudo descargar el archivo"
        return
    }
    $port = Read-Host "Ingresa el puerto del servidor Tomcat"
    while ($true) {
        if (-not (Test-PortValid -port $port)) {
            break
        }
        $port = Read-Host "Puerto no valido, porfavor ingresa un puerto valido"
    }
    Expand-Archive -Path $outputPath -DestinationPath "$extractPath" -Force
    Copy-Item -Path "$extractPath\apache-tomcat-$version_number\*" -Destination $tomcatPath -Recurse -Force
    (Get-Content -Path $confFile) -replace 'port="8080"', "port=`"$port`""  | Set-Content -Path $confFile
    #Set enviorment variables
    $sslResponse = Read-Host "Quieres instalar SSL? [S/N]"
    if ($sslResponse -eq "S") {
        $sslPort = Read-Host "Ingresa el puerto del servidor Tomcat con SSL"
        while ($true) {
            if (-not (Test-PortValid -port $sslPort)) {
                break
            }
            $sslPort = Read-Host "Puerto no valido, porfavor ingresa un puerto valido"
        }
        $content = Get-Content -Path $confFile -Raw
        $content = $content -replace $pattern, '$1'
        Set-Content -Path $confFile -Value $content -Encoding UTF8
        #(Get-Content -Path $confFile) -replace 'port="8443"', "port=`"$sslPort`""  | Set-Content -Path $confFile
        $keystorePassword = "SexomatasFc"
        $alias = "tomcat"
        $keytoolPath = "$env:JAVA_HOME\bin\keytool.exe"
        & $keytoolPath -genkeypair `
            -alias $alias `
            -keyalg RSA `
            -keysize 2048 `
            -keystore $keystorePath `
            -storepass $keystorePassword `
            -validity 365 `
            -dname "CN=Chuas, OU=IT, O=SexomatasFc, L=Momochis, S=Chinaloa, C=MX"
        (Get-Content -Path $confFile) -replace 'certificateKeystoreFile="conf/localhost-rsa.jks"', "certificateKeystoreFile=`"$keystorePath`"" | Set-Content -Path $confFile
        (Get-Content -Path $confFile) -replace 'certificateKeystorePassword="changeit"', "certificateKeystorePassword=`"$keystorePassword`"" | Set-Content -Path $confFile
        (Get-Content -Path $confFile) -replace 'port="8443"', "port=`"$sslPort`""  | Set-Content -Path $confFile
        (Get-Content -Path $confFile) -replace 'redirectPort="8443"', "redirectPort=`"$sslPort`""  | Set-Content -Path $confFile

    }

    [System.Environment]::SetEnvironmentVariable("CATALINA_HOME", "C:\Tomcat", [System.EnvironmentVariableTarget]::Machine)
    ([System.Environment]::SetEnvironmentVariable("CATALINA_HOME", $tomcatPath, [System.EnvironmentVariableTarget]::Machine))
    ([System.Environment]::SetEnvironmentVariable("CATALINA_BASE", $tomcatPath, [System.EnvironmentVariableTarget]::Machine))
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaPath, "Machine")
    [System.Environment]::SetEnvironmentVariable("JRE_HOME", $javaPath, "Machine")
    #Install the service
    Set-Location "$tomcatPath\bin"
    cmd.exe /c "service.bat install"
    Remove-Item -Path $outputPath -Force
    #Remove the extracted folder
    Remove-Item -Path $extractPath -Recurse -Force
    Set-Location C:\
    $server_Ip = Get-IP-Address
    Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
}
Function Install-Nginx {
    param([string]$version, [int]$download_source)
    Purge-Service -service_name "Nginx"
    $url = "https://nginx.org/download/nginx-$version.zip"
    $outputPath = "C:\Users\Administrator\Downloads\nginx.zip"
    $extractPath = "C:\Users\Administrator\Downloads\Nginx"
    $nginxPath = "C:\Nginx"
    $confFile = "$nginxPath\conf\nginx.conf"
    $sslCertPath = "C:/Nginx/conf/nginx-selfsigned.pem"
    $sslKeyPath = "C:/Nginx/conf/nginx-selfsigned.key"
    $openSSLPath = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"
    #check if the path of the nginx and extraction path exist before the installation.
    if (-not (Test-Path -Path $nginxPath)) {
        New-Item -Path $nginxPath -ItemType Directory
    }
    if (-not (Test-Path -Path $extractPath)) {
        New-Item -Path $extractPath -ItemType Directory
    }
    Write-Host "Descargando Nginx version $version"
    if ($download_source -eq 1) {
        (New-Object System.Net.WebClient).DownloadFile($url, $outputPath)
    }
    elseif ($download_source -eq 2) {
        
        $ftpFileUrl = "ftp://localhost/General/Resources/nginx/nginx-$version.zip"
        Write-Host "Descargando Tomcat desde: $ftpFileUrl"
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        # Crear solicitud FTP con método DownloadFile
        $ftpRequest = [System.Net.FtpWebRequest]::Create($ftpFileUrl)
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
        $ftpRequest.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous")
        $ftpRequest.EnableSsl = $true

        # Obtener respuesta y escribir en archivo local
        $ftpResponse = $ftpRequest.GetResponse()
        $ftpStream = $ftpResponse.GetResponseStream()
        $localFileStream = [System.IO.File]::Create($outputPath)

        $buffer = New-Object byte[] 10240
        do {
            $read = $ftpStream.Read($buffer, 0, $buffer.Length)
            $localFileStream.Write($buffer, 0, $read)
        } while ($read -gt 0)

        # Cerrar flujos
        $localFileStream.Close()
        $ftpStream.Close()
        $ftpResponse.Close()
    }
    #Check if the file is downloaded
    if (-not (Test-Path -Path $outputPath)) {
        Write-Host "No se pudo descargar el archivo"
        return
    }
    $port = Read-Host "Ingresa el puerto del servidor Nginx"
    while ($true) {
        if (-not (Test-PortValid -port $port)) {
            break
        }
        $port = Read-Host "Puerto no valido, porfavor ingresa un puerto valido"
    }
    if (-not (Test-Path "C:\Nginx\logs")) {
        New-Item -Path "C:\Nginx\logs" -ItemType Directory
    }
        
    if (-not (Test-Path "C:\Nginx\logs\error.log")) {
        New-Item -Path "C:\Nginx\logs\error.log" -ItemType File -Force
    }

    Expand-Archive -Path $outputPath -DestinationPath "$extractPath" -Force
    Copy-Item -Path "$extractPath\nginx-$version\*" -Destination $nginxPath -Recurse -Force
    $sslResponse = Read-Host "Quieres instalar SSL? [S/N]"
    if ($sslResponse -eq "S") {
        $sslPort = Read-Host "Ingresa el puerto del servidor Nginx con SSL"
        
        while ($true) {
            if (-not (Test-PortValid -port $sslPort)) {
                break
            }
            $sslPort = Read-Host "Puerto no valido, porfavor ingresa un puerto valido"
        }
        
        # Generar certificado SSL
        & $openSSLPath req -x509 -nodes -days 365 -newkey rsa:2048 `
            -keyout $sslKeyPath `
            -out $sslCertPath `
            -subj "/C=MX/ST=Chinaloa/L=Momochis/O=SexomatasFc/OU=IT/CN=Chuas"
        
        $sslConfig = @"
            worker_processes  1;
error_log  C:/Nginx/logs/error.log;
pid        C:/Nginx/logs/nginx.pid;

events {
    worker_connections  1024;
}

http {
	tcp_nopush on;

    include       mime.types;
    default_type  application/octet-stream;
    
    access_log  C:/Nginx/logs/access.log;
    
    sendfile        on;
    keepalive_timeout  65;
    	types_hash_max_size 2048;

    server {
        listen       ${port};
        server_name  localhost;
        
        location / {
            root   html;
            index  index.html index.htm;
        }
        
        error_page   500 502 503 504  /50x.html;
    }

            server {
                listen       ${sslPort} ssl;
                server_name  localhost;
        
                ssl_certificate      ${sslCertPath};
                ssl_certificate_key  ${sslKeyPath};
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
"@      # Leer la configuración existente
        Set-Content -Path $confFile -Value $sslConfig -Force


    }
    else {
    
        $insert_config = @"
worker_processes  1;
error_log  C:/Nginx/logs/error.log;
pid        C:/Nginx/logs/nginx.pid;

events {
    worker_connections  1024;
}

http {
	tcp_nopush on;

    include       mime.types;
    default_type  application/octet-stream;
    
    access_log  C:/Nginx/logs/access.log;
    
    sendfile        on;
    keepalive_timeout  65;
    	types_hash_max_size 2048;

    server {
        listen       $port;
        server_name  localhost;
        
        location / {
            root   html;
            index  index.html index.htm;
        }
        
        error_page   500 502 503 504  /50x.html;
    }
}
"@
        Set-Content -Path $confFile -Value $insert_config -Force
  
    }  #SSL Config
    #Remove the installation files
    Remove-Item -Path $outputPath -Force
    Remove-Item -Path $extractPath -Recurse -Force
    Set-Location $nginxPath
    $server_Ip = Get-IP-Address
    Start-Process ".\nginx.exe"
    tasklist /fi "imagename eq nginx.exe"
    .\nginx.exe -s reload
    $server_Ip = Get-IP-Address
    Set-Location C:\
    Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
}
Function Install-JDK {
    $jdk_url = "https://download.oracle.com/java/24/latest/jdk-24_windows-x64_bin.msi"
    $outPath = "C:\Users\Administrator\Downloads\jdk.msi"
    (New-Object System.Net.WebClient).DownloadFile($jdk_url, $outPath)
    Start-Process msiexec "/i $outPath /qn";
    Remove-Item -Path $outPath -Force
}
Function Purge-Service {
    param([string]$service_name)
    $services = (Get-Service -Name "$service_name*")
    if ($services) {
        foreach ($service in $services) {
            Stop-Process -Name $service.Name -Force -ErrorAction SilentlyContinue
            sc.exe stop $service.Name -Force
            Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
            sc.exe delete $service.Name -Force
            Write-Host "Stopping $($service.Name)"
        }
    }
    if ($service_name -eq "Tomcat") {
        [System.Environment]::SetEnvironmentVariable("CATALINA_HOME", $null, [System.EnvironmentVariableTarget]::Machine)
        [System.Environment]::SetEnvironmentVariable("CATALINA_BASE", $null, [System.EnvironmentVariableTarget]::Machine)
        if (Test-Path "C:\Tomcat") {
            Remove-Item -Path "C:\Tomcat\*" -Recurse -Force
        }

        #Remove enviorment variables
    }
    elseif ($service_name -eq "Nginx") {
        taskkill.exe /F /IM nginx.exe > $null 2>&1
        Stop-Service -Name "nginx*" -Force 2>$null
        if (Test-Path "C:\Nginx") {
            Remove-Item -Path "C:\Nginx\*" -Recurse -Force
        }
    }
    elseif ($service_name -eq "IIS") {
        #Do Something
        #Remove IIS Pages
        if (Test-Path "C:\Sites") {
            Remove-Item -Path "C:\Sites\*" -Recurse -Force
        }
        #remove IIS Websites and bindings
        Get-Website | Remove-Website
        Get-WebBinding | Remove-WebBinding
    }
}
Function Get-FilePath {
    param([string]$file_name)
    $path = (Get-ChildItem -Path "C:\ruta\a\tomcat" -Filter "service.bat" -Recurse -File | Select-Object -ExpandProperty FullName)
    if (-not $path) {
        <# Action to perform if the condition is true #>
        Write-Host "No se encontró el archivo"
    }
    return $path
}
Function ServiceExists {
    param([string]$service_name)
    return (Get-Service -Name "$service_name*" -ErrorAction SilentlyContinue)
}

Function Get-NginxVersions {
    param([int] $download_source)
    if ($download_source -eq 1) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor `
            [Net.SecurityProtocolType]::Tls11 -bor `
            [Net.SecurityProtocolType]::Tls

        $nginx_url = "https://nginx.org/download/"
        $nginx_versions = (Invoke-WebRequest -Uri $nginx_url -UseBasicParsing).Links.href | Where-Object { $_ -match "nginx-(\d+\.\d+\.\d+)\.zip" } 
        $versions = $nginx_versions -replace "nginx-|\.zip", "" | Where-Object { $_ -match "^\d+\.\d+\.\d+$" }
        return ($versions | Sort-Object { [System.Version]$_ } -Descending)
    }
    else {
        #Get The version from the ftp server
        $ftpUrl = "$ftp_route/nginx/"
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        $ftpRequest = [System.Net.FtpWebRequest]::Create($ftpUrl)
        $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        $ftpRequest.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous")
        $ftpRequest.EnableSsl = $true

        $ftpResponse = $ftpRequest.GetResponse()
        $ftpStream = $ftpResponse.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($ftpStream)
        $entries = $reader.ReadToEnd().Split("`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

        $versions = $entries |
        Where-Object { $_ -match '^nginx-(\d+\.\d+\.\d+)\.zip$' } |
        ForEach-Object {
            if ($_ -match '^nginx-(\d+\.\d+\.\d+)\.zip$') {
                $matches[1]
            }
        }
        return , $versions
    }


}
Function Install-IIS {
    Install-WindowsFeature web-server -IncludeManagementTools > $null 2>&1
    Import-Module WebAdministration
    Purge-Service -service_name "IIS"
    mkdir C:\Sites\ 2>$null
    $siteName = Read-Host "Ingresa el nombre del sitio web "
    mkdir C:\Sites\$siteName 2>$null
    $port = Read-Host "Ingresa el puerto del servidor IIS: "
    while ($true) {
        if (-not (Test-PortValid -port $port)) {
            break
        }
        $port = Read-Host "Puerto no valido, porfavor ingresa un puerto valido"
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
    $server_Ip = Get-IP-Address
    $sslChoise = Read-Host "Quieres instalar SSL? [S/N]"
    if ($sslChoise -eq "S") {
        $sport = Read-Host "Ingresa el puerto del servidor IIS con SSL: "
        $certificate = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $server_Ip -FriendlyName "Self-Signed-Certificate"
        Set-WebBinding -Name "$siteName" -PropertyName "Port" -Value "$port"
        New-WebBinding -Name "$siteName" -IPAddress "*" -Port $sport -Protocol "https"
        $webSite = Get-WebBinding -Name "$siteName" -Protocol "https"
        $webSite.AddSslCertificate($certificate.GetCertHashString(), "My")
        
    }
    Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
}
Function Print-Array {
    param([array]$array)
    if ($array.Count -eq 0) {
        Write-Host "No hay elementos en el array"
        return
    }
    foreach ($element in $array) {
        #index of the element
        Write-Host "[$($array.IndexOf($element))] $element"
    }
}
Function In-CommonPorts {
    param([int]$port)
    $common_ports = @(20, 21, 22, 23, 25, 53, 110, 143, 443, 465, 587, 993, 995, 3306, 5432)
    foreach ($port in $common_ports) {
        if ($port -eq $port) {
            return $true
            break
        }
    }
    return $false
}
Function Get-Current-DomainName {
    return Get-ADDomain | Select-Object -ExpandProperty Name
}
Function Is-Valid-DomainName {
    param([Parameter(Mandatory = $true)][string]$domainName)
    return $domainName -match "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"
}
Function Convert-SecureString-To-PlainText {
    param([Parameter(Mandatory = $true)][SecureString]$secureString)
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
}
Function Set-LogonHours {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateRange(0, 23)]
        $TimeIn24Format,
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True, 
            Position = 0)]$Identity,
        [parameter(mandatory = $False)]
        [ValidateSet("WorkingDays", "NonWorkingDays")]$NonSelectedDaysare = "NonWorkingDays",
        [parameter(mandatory = $false)][switch]$Sunday,
        [parameter(mandatory = $false)][switch]$Monday,
        [parameter(mandatory = $false)][switch]$Tuesday,
        [parameter(mandatory = $false)][switch]$Wednesday,
        [parameter(mandatory = $false)][switch]$Thursday,
        [parameter(mandatory = $false)][switch]$Friday,
        [parameter(mandatory = $false)][switch]$Saturday
    )
    Process {
        $FullByte = New-Object "byte[]" 21
        $FullDay = [ordered]@{}
        0..23 | ForEach-Object { $FullDay.Add($_, "0") }
        $TimeIn24Format.ForEach({ $FullDay[$_] = 1 })
        $Working = -join ($FullDay.values)
        Switch ($PSBoundParameters["NonSelectedDaysare"]) {
            'NonWorkingDays' { $SundayValue = $MondayValue = $TuesdayValue = $WednesdayValue = $ThursdayValue = $FridayValue = $SaturdayValue = "000000000000000000000000" }
            'WorkingDays' { $SundayValue = $MondayValue = $TuesdayValue = $WednesdayValue = $ThursdayValue = $FridayValue = $SaturdayValue = "111111111111111111111111" }
        }
        Switch ($PSBoundParameters.Keys) {
            'Sunday' { $SundayValue = $Working }
            'Monday' { $MondayValue = $Working }
            'Tuesday' { $TuesdayValue = $Working }
            'Wednesday' { $WednesdayValue = $Working }
            'Thursday' { $ThursdayValue = $Working }
            'Friday' { $FridayValue = $Working }
            'Saturday' { $SaturdayValue = $Working }
        }
        $AllTheWeek = "{0}{1}{2}{3}{4}{5}{6}" -f $SundayValue, $MondayValue, $TuesdayValue, $WednesdayValue, $ThursdayValue, $FridayValue, $SaturdayValue
        # Timezone Check
        if ((Get-TimeZone).baseutcoffset.hours -lt 0) {
            $TimeZoneOffset = $AllTheWeek.Substring(0, 168 + ((Get-TimeZone).baseutcoffset.hours))
            $TimeZoneOffset1 = $AllTheWeek.SubString(168 + ((Get-TimeZone).baseutcoffset.hours))
            $FixedTimeZoneOffSet = "$TimeZoneOffset1$TimeZoneOffset"
        }
        if ((Get-TimeZone).baseutcoffset.hours -gt 0) {
            $TimeZoneOffset = $AllTheWeek.Substring(0, ((Get-TimeZone).baseutcoffset.hours))
            $TimeZoneOffset1 = $AllTheWeek.SubString(((Get-TimeZone).baseutcoffset.hours))
            $FixedTimeZoneOffSet = "$TimeZoneOffset1$TimeZoneOffset"
        }
        if ((Get-TimeZone).baseutcoffset.hours -eq 0) {
            $FixedTimeZoneOffSet = $AllTheWeek
        }
        $i = 0
        $BinaryResult = $FixedTimeZoneOffSet -split '(\d{8})' | Where-Object { $_ -match '(\d{8})' }
        Foreach ($singleByte in $BinaryResult) {
            $Tempvar = $singleByte.tochararray()
            [array]::Reverse($Tempvar)
            $Tempvar = -join $Tempvar
            $Byte = [Convert]::ToByte($Tempvar, 2)
            $FullByte[$i] = $Byte
            $i++
        }
        Set-ADUser  -Identity $Identity -Replace @{logonhours = $FullByte }                                   
    }
    end {
        Write-Output "All Done :)"
    }
}
function Test-Credential {
    param (
        [Parameter(Mandatory = $true)]
        [string]$username,
        [Parameter(Mandatory = $true)]
        [securestring]$password
    )
    $plaintext = (New-Object System.Management.Automation.PSCredential 'N/A', $password).GetNetworkCredential().Password
    $CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
    $domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain, $username, $plaintext)
    if ($domain.name -eq $null) {
        Write-Warning "Contraseña incorrecta"
        return $false
    }
    else { 
        write-host "Successfully authenticated with domain" $domain.name
        return $true
    }
}
Function Set-PasswordPolicy {
    $CURRENT_DOMAIN = Get-Current-DomainName
    #Set the new policy to force the users to change their password on the first login
    Set-ADDefaultDomainPasswordPolicy -Identity $CURRENT_DOMAIN `
        -MinPasswordLength 8 `
        -ComplexityEnabled $true `
        -PasswordHistoryCount 1 `
        -MinPasswordAge "1.00:00:00" `
        -MaxPasswordAge "30.00:00:00"
    $group1Users = Get-ADUser -Filter * -SearchBase "OU=group_1,DC=$CURRENT_DOMAIN,DC=com"
    $group2Users = Get-ADUser -Filter * -SearchBase "OU=group_2,DC=$CURRENT_DOMAIN,DC=com"

    foreach ($user in $group1Users) {
        Set-ADUser -Identity $($user.sAMAccountName) -ChangePasswordAtLogon $true
    }
    foreach ($user in $group2Users) {
        Set-ADUser -Identity $($user.sAMAccountName) -PasswordNeverExpires $true
    }

}
Function CreateNewUserInDomain {
    param(
        [Parameter(Mandatory = $true)]
        [string]$userName,
        [Parameter(Mandatory = $true)]
        [securestring]$password,
        [Parameter(Mandatory = $true)]
        [string]$groupName,
        [Parameter(Mandatory = $true)]
        [string]$domainName
    )
    New-ADUser -Name $userName `
        -AccountPassword $password `
        -Enable $true `
        -Path "OU=$groupName,DC=$domainName,DC=com" `
        -UserPrincipalName "$userName@$domainName" `
        -ChangePasswordAtLogon $true `
        -PassThru
    Set-ADUser -Identity "$userName" -ProfilePath "\\$env:COMPUTERNAME\Profiles\$($userName)"
    Add-ADGroupMember -Identity "multiOtpGroup" -Members $userName
    Set-Location -Path "C:\multiOTP"
    .\multiotp.exe -debug -display-log -ldap-users-sync
    Write-Host "El usuario $userName ha sido creado y agregado al grupo $groupName." -ForegroundColor Green
}
function CreateNewFtpUser {
    param(
        [parameter(Mandatory = $true)]
        [string]$username,
        [parameter(Mandatory = $true)]
        [securestring]$password,
        [parameter(Mandatory = $true)]
        [string]$groupName
    )
    net user "$username" "$password" /add
    net localgroup "general" $username /add
    mkdir "C:\FTP\$username"
    mkdir "C:\FTP\LocalUser\$username"
    cmd /c mklink /D "C:\FTP\LocalUser\$username\$username"  "C:\FTP\$username"
    cmd /c mklink /D "C:\FTP\LocalUser\$username\General" "C:\FTP\General"
    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$username" -Filter "system.ftpServer/security/authorization" -Name "."
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType = "Allow"; users = "$username"; permissions = 3 } -PSPath IIS:\ -Location "FTP/$username"
    net localgroup "$groupName" "$username" /add
    cmd /c mklink /D "C:\FTP\LocalUser\$username\$groupName" "C:\FTP\$groupName"

}
function Install-SquirrelMail {
    $squirrelMailPath = "C:\xampp\htdocs\squirrelmail"
    $squirrelMailUrl = "https://www.squirrelmail.org/countdl.php?fileurl=http%3A%2F%2Fprdownloads.sourceforge.net%2Fsquirrelmail%2Fsquirrelmail-webmail-1.4.22.zip"
    $outputPath = "C:\Users\Administrator\Downloads\squirrelmail.zip"
    Remove-Item -Path $squirrelMailPath -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path -Path $squirrelMailPath)) {
        New-Item -Path $squirrelMailPath -ItemType Directory
    }
    curl.exe -L $squirrelMailUrl -o $outputPath
    Expand-Archive -Path $outputPath -DestinationPath "C:\Users\Administrator\Downloads" -Force
    Copy-Item -Path "C:\Users\Administrator\Downloads\squirrelmail-webmail-1.4.22\*" -Destination $squirrelMailPath -Recurse
    Rename-Item -Path "$squirrelMailPath\config\config_default.php" -NewName "config.php"
    (Get-Content -Path "$squirrelMailPath\config\config.php") -replace '\$domain\s*=\s*''[^'']+'';', '$domain = ''reprobados.com'';' | Set-Content "C:\xampp\htdocs\squirrelmail\config\config.php"
    (Get-Content -Path "$squirrelMailPath\config\config.php") -replace '\$data_dir\s*=\s*''[^'']+'';', '$data_dir = ''C:/xampp/htdocs/squirrelmail/data/'';' | Set-Content "C:\xampp\htdocs\squirrelmail\config\config.php"
    try {
        $acl = Get-Acl -Path "$squirrelMailPath"
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("All", "FullControl", "Allow", "ConainerInherit", "ObjectInherit", "None")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path "$squirrelMailPath" -AclObject $acl
        Write-Host "Permisos establecidos correctamente para SquirrelMail." -ForegroundColor Green
        Set-Location "C:\xampp\"
        Start-Process "C:\xampp\apache_start.bat" -Wait
    }
    catch {
        Write-Host "Error al establecer permisos para SquirrelMail: $_" -ForegroundColor Red
    }
}
function Install-PegasusMail {
    $pegasusUrl = "https://www.pmail.com/downloads/m32-491.exe"
    $pegasusInstaller = "$env:TEMP/pegasus_installer.exe"
    curl.exe -L $pegasusUrl -o $pegasusInstaller
    Start-Process -FilePath $pegasusInstaller -Wait
    New-NetFirewallRule -DisplayName "SMTP" -Direction Inbound -Protocol TCP -LocalPort 25, 110, 143, 587, 993, 995 -Profile Any -Enabled True
    Start-Process -FilePath "C:\MERCURY\mercury.exe"
}
function Install-Xampp {
    $xamppUrl = "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/5.6.40/xampp-windows-x64-5.6.40-1-VC11-installer.exe/download"
    $xamppInstaller = "$env:TEMP\xampp_installer.exe"
    curl.exe -L $xamppUrl -o $xamppInstaller
    Start-Process -FilePath $xamppInstaller -Wait
}
function Create-MercuryAccount {
    param(
        [Parameter(Mandatory = $true)]
        [string]$username,
        [Parameter(Mandatory = $true)]
        [string]$password
    )
    $pathMail = "C:\MERCURY\MAIL"
    $userPath = Join-Path -Path $pathMail $username
    $pmFile = Join-Path -Path $userPath "PASSWD.PM"
    if (-not (Test-Path -Path $userPath)) {
        New-Item -Path $userPath -ItemType Directory
        $pmFileContent = @"
        POP3_access: $username
        APOP_secret: 
"@
        try {
            $ansi = [System.Text.Encoding]::GetEncoding("Windows-1252")
            [System.IO.File]::WriteAllBytes($pmFile, $ansi.GetBytes($pmFileContent))
        }
        catch {
            Write-Host "Error al crear el archivo de usuario: $_" -ForegroundColor Red
            
        }
    }
}
# Exportar todas las funciones correctamente
Export-ModuleMember -Function saludar, get_all_adapters, get_adapter_ip, ip_default_gateway, ip_root, `
    get_adapter_ip_address, get_last_octet, reverse_ip, Get-IP-Address, Test-PortOpen, Test-PortValid, `
    Get-All-Zones, Validate-Username, Test-UserExists, Validate-Password, Test-UserNotInGroups, `
    Get-TomcatVersions, Install-Tomcat, Purge-Service, Get-FilePath, Print-Array, ServiceExists, Get-ApacheVersions, `
    Get-ServiceVersions, In-CommonPorts, Get-NginxVersions, Install-Nginx, Install-IIS, Install-JDK, Get-Current-DomainName, Convert-SecureString-To-PlainText, `
    Set-LogonHours, Set-PasswordPolicy, Test-Credential, CreateNewUserInDomain, Install-SquirrelMail, Install-PegasusMail, Install-Xampp, CreateNewFtpUser