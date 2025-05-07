function saludar {
    param ([string]$nombre)
    Write-Host "Hola $nombre"
}

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
    
    return (Get-NetTCPConnection | where Localport -eq $port | select Localport,OwningProcess)
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
    param([int]$version)
    
    $url = "https://dlcdn.apache.org/tomcat/tomcat-$version/"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $versions = $html.Links.href | Where-Object { $_ -match "^v$version\.\d+\.\d+/$" }
    $versions = $versions -replace "^v|/$", ""
    # Return as array regardless of number of elements
    return ,$versions
}

function Install-Tomcat {
    param([string]$version, [string]$version_number)
    Purge-Service -service_name "Tomcat"
    Start-Sleep -Seconds 3
    $url = "https://dlcdn.apache.org/tomcat/tomcat-$version/v$version_number/bin/apache-tomcat-$version_number-windows-x64.zip"
    $outputPath = "C:\Users\Administrator\Downloads\tomcat.zip"
    $extractPath = "C:\Users\Administrator\Downloads\Tomcat"
    $tomcatPath = "C:\Tomcat"
    $confFile = "$tomcatPath\conf\server.xml"
    if(-not (Test-Path -Path $tomcatPath)){
        New-Item -Path $tomcatPath -ItemType Directory
    }
    if(-not (Test-Path -Path $extractPath)){
        New-Item -Path $extractPath -ItemType Directory
    }
    (New-Object System.Net.WebClient).DownloadFile($url, $outputPath)
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
    #Remove the downloaded file
    #Set enviorment variables
    ([System.Environment]::SetEnvironmentVariable("CATALINA_HOME", $tomcatPath, [System.EnvironmentVariableTarget]::Machine))
    ([System.Environment]::SetEnvironmentVariable("CATALINA_BASE", $tomcatPath, [System.EnvironmentVariableTarget]::Machine))
    #Install the service
    Set-Location "$tomcatPath\bin"
    Start-Process -FilePath "$tomcatPath\bin\service.bat" install
    Remove-Item -Path $outputPath -Force
    #Remove the extracted folder
    Remove-Item -Path $extractPath -Recurse -Force
    Set-Location C:\
    $server_Ip = Get-IP-Address
    Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
}
Function Install-Nginx{
    param([string]$version)
    Purge-Service -service_name "Nginx"
    $url = "https://nginx.org/download/nginx-$version.zip"
    $outputPath = "C:\Users\Administrator\Downloads\nginx.zip"
    $extractPath = "C:\Users\Administrator\Downloads\Nginx"
    $nginxPath = "C:\Nginx"
    $confFile = "$nginxPath\conf\nginx.conf"
    #check if the path of the nginx and extraction path exist before the installation.
    if(-not (Test-Path -Path $nginxPath)){
        New-Item -Path $nginxPath -ItemType Directory
    }
    if(-not (Test-Path -Path $extractPath)){
        New-Item -Path $extractPath -ItemType Directory
    }
    (New-Object System.Net.WebClient).DownloadFile($url, $outputPath)
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
    $insert_config = @"
worker_processes  1;

error_log  C:/Nginx/logs/error.log;
pid        C:/Nginx/logs/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    
    access_log  C:/Nginx/logs/access.log;
    
    sendfile        on;
    keepalive_timeout  65;
    
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
    #Remove the installation files
    Remove-Item -Path $outputPath -Force
    Remove-Item -Path $extractPath -Recurse -Force
    Set-Location $nginxPath
    $server_Ip = Get-IP-Address
    #For some reasons the Start-Process with $path doesn't work
    #Buf if you're in the same directory as the executable it works 🦧🦧🦧
    #nginx/Windows uses the directory where it has been run as the prefix for relative paths in the configuration. 
    #In the example above, the prefix is C:\nginx-1.27.4\. Ahhh thats why🙉
    #Start-Process "$nginxPath\nginx.exe" -ArgumentList "-p", "C:\Nginx", "-c", "C:\Nginx\conf\nginx.conf"
    #Start-Process "$nginxPath\nginx.exe" -ArgumentList "-p", "C:\Nginx", "-s", "reload"
    Start-Process ".\nginx.exe"
    tasklist /fi "imagename eq nginx.exe"
    .\nginx.exe -s reload
    $server_Ip = Get-IP-Address
    Set-Location C:\
    Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
}
Function Install-JDK{
    $jdk_url = "https://download.oracle.com/java/24/latest/jdk-24_windows-x64_bin.msi"
    $outPath = "C:\Users\Administrator\Downloads\jdk.msi"
    (New-Object System.Net.WebClient).DownloadFile($jdk_url, $outPath)
    Start-Process msiexec "/i $outPath /qn";
    Remove-Item -Path $outPath -Force
}
Function Purge-Service{
    param([string]$service_name)
    $services = (Get-Service -Name "$service_name*")
    if($services){
        foreach($service in $services){
            Stop-Process -Name $service.Name -Force -ErrorAction SilentlyContinue
            sc.exe stop $service.Name -Force
            Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
            sc.exe delete $service.Name -Force
            Write-Host "Stopping $($service.Name)"
        }
    }
    if($service_name -eq "Tomcat"){
        [System.Environment]::SetEnvironmentVariable("CATALINA_HOME", $null, [System.EnvironmentVariableTarget]::Machine)
        [System.Environment]::SetEnvironmentVariable("CATALINA_BASE", $null, [System.EnvironmentVariableTarget]::Machine)
         if(Test-Path "C:\Tomcat"){
            Remove-Item -Path "C:\Tomcat\*" -Recurse -Force
        }

        #Remove enviorment variables
    }elseif ($service_name -eq "Nginx"){
        taskkill.exe /F /IM nginx.exe > $null 2>&1
        Stop-Service -Name "nginx*" -Force 2>$null
        if(Test-Path "C:\Nginx"){
            Remove-Item -Path "C:\Nginx\*" -Recurse -Force
        }
    }elseif ($service_name -eq "IIS"){
        #Do Something
        #Remove IIS Pages
        if(Test-Path "C:\Sites"){
            Remove-Item -Path "C:\Sites\*" -Recurse -Force
        }
        #remove IIS Websites and bindings
        Get-Website | Remove-Website
        Get-WebBinding | Remove-WebBinding
    }
}
Function Get-FilePath{
    param([string]$file_name)
    $path = (Get-ChildItem -Path "C:\ruta\a\tomcat" -Filter "service.bat" -Recurse -File | Select-Object -ExpandProperty FullName)
    if (-not $path) {
        <# Action to perform if the condition is true #>
        Write-Host "No se encontró el archivo"
    }
    return $path
}
Function ServiceExists{
    param([string]$service_name)
    return (Get-Service -Name "$service_name*" -ErrorAction SilentlyContinue)
}

Function Get-NginxVersions{
$nginx_url = "https://nginx.org/download/"
$nginx_versions = (Invoke-WebRequest -Uri $nginx_url -UseBasicParsing).Links.href | Where-Object { $_ -match "nginx-(\d+\.\d+\.\d+)\.zip" } 
$versions = $nginx_versions -replace "nginx-|\.zip", "" | Where-Object { $_ -match "^\d+\.\d+\.\d+$" }
return ($versions | Sort-Object {[System.Version]$_} -Descending)

}
Function Install-IIS{
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
    Write-Host "Servidor corriendo en http://$($server_Ip):$($port)" -ForegroundColor Green
}
Function Print-Array{
    param([array]$array)
    if($array.Count -eq 0){
        Write-Host "No hay elementos en el array"
        return
    }
    foreach($element in $array){
        #index of the element
        Write-Host "[$($array.IndexOf($element))] $element"
    }
}
Function In-CommonPorts{
    param([int]$port)
    $common_ports = @(20,21,22,23,25,53,110,143,443,465,587,993,995,3306,5432)
    foreach($port in $common_ports){
        if($port -eq $port){
            return $true
            break
        }
    }
    return $false
}
Function Get-Current-DomainName{
    return Get-ADDomain | Select-Object -ExpandProperty Name
}
Function Is-Valid-DomainName{
    param([Parameter(Mandatory=$true)][string]$domainName)
    return $domainName -match "^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"
}
Function Convert-SecureString-To-PlainText{
    param([Parameter(Mandatory=$true)][SecureString]$secureString)
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
}
Function Set-LogonHours {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateRange(0, 23)]
        $TimeIn24Format,

        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, Position = 0)]
        $Identity,

        [Parameter(Mandatory = $False)]
        [ValidateSet("WorkingDays", "NonWorkingDays")]
        $NonSelectedDaysare = "NonWorkingDays",

        [Parameter(Mandatory = $False)][switch]$Sunday,
        [Parameter(Mandatory = $False)][switch]$Monday,
        [Parameter(Mandatory = $False)][switch]$Tuesday,
        [Parameter(Mandatory = $False)][switch]$Wednesday,
        [Parameter(Mandatory = $False)][switch]$Thursday,
        [Parameter(Mandatory = $False)][switch]$Friday,
        [Parameter(Mandatory = $False)][switch]$Saturday
    )
    Process {
        $FullByte = New-Object "byte[]" 21
        $FullDay = [ordered]@{}
        0..23 | ForEach-Object { $FullDay.Add($_, "0") }
        $TimeIn24Format.ForEach({ $FullDay[$_] = 1 })
        $Working = -join ($FullDay.values)

        Switch ($PSBoundParameters["NonSelectedDaysare"]) {
            'NonWorkingDays' {
                $SundayValue = $MondayValue = $TuesdayValue = $WednesdayValue = $ThursdayValue = $FridayValue = $SaturdayValue = "000000000000000000000000"
            }
            'WorkingDays' {
                $SundayValue = $MondayValue = $TuesdayValue = $WednesdayValue = $ThursdayValue = $FridayValue = $SaturdayValue = "111111111111111111111111"
            }
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
        if ((Get-TimeZone).BaseUtcOffset.Hours -lt 0) {
            $TimeZoneOffset = $AllTheWeek.Substring(0, 168 + ((Get-TimeZone).BaseUtcOffset.Hours))
            $TimeZoneOffset1 = $AllTheWeek.Substring(168 + ((Get-TimeZone).BaseUtcOffset.Hours))
            $FixedTimeZoneOffSet = "$TimeZoneOffset1$TimeZoneOffset"
        }
        elseif ((Get-TimeZone).BaseUtcOffset.Hours -gt 0) {
            $TimeZoneOffset = $AllTheWeek.Substring(0, ((Get-TimeZone).BaseUtcOffset.Hours))
            $TimeZoneOffset1 = $AllTheWeek.Substring(((Get-TimeZone).BaseUtcOffset.Hours))
            $FixedTimeZoneOffSet = "$TimeZoneOffset1$TimeZoneOffset"
        }
        else {
            $FixedTimeZoneOffSet = $AllTheWeek
        }

        $i = 0
        $BinaryResult = $FixedTimeZoneOffSet -split '(\d{8})' | Where-Object { $_ -match '(\d{8})' }
        Foreach ($singleByte in $BinaryResult) {
            $Tempvar = $singleByte.ToCharArray()
            [array]::Reverse($Tempvar)
            $Tempvar = -join $Tempvar
            $Byte = [Convert]::ToByte($Tempvar, 2)
            $FullByte[$i] = $Byte
            $i++
        }

        Set-ADUser -Identity $Identity -Replace @{ logonhours = $FullByte }
    }
    End {
        Write-Output "All Done :)"
    }
}
# Exportar todas las funciones correctamente
Export-ModuleMember -Function saludar, get_all_adapters, get_adapter_ip, ip_default_gateway, ip_root, `
    get_adapter_ip_address, get_last_octet, reverse_ip, Get-IP-Address, Test-PortOpen, Test-PortValid, `
    Get-All-Zones, Validate-Username, Test-UserExists, Validate-Password, Test-UserNotInGroups, `
    Get-TomcatVersions, Install-Tomcat, Purge-Service, Get-FilePath, Print-Array, ServiceExists, Get-ApacheVersions, `
    Get-ServiceVersions, In-CommonPorts, Get-NginxVersions, Install-Nginx, Install-IIS, Install-JDK, Get-Current-DomainName,Convert-SecureString-To-PlainText, `
    Set-LogonHours