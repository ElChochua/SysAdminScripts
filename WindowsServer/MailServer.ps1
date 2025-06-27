Import-Module Z:\Functions.psm1 -Force
Import-Module WebAdministration

# Configuración de rutas
$hMailPath = "C:\Program Files (x86)\hMailServer\Bin\hMailServer.exe"
$domainName = Get-ADDomain | Select-Object -ExpandProperty DNSRoot
if (-not $domainName) {
    $domainName = Read-Host "Introduce el nombre de dominio para hMailServer (ej. tuempresa.com)"
}

# Instalar hMailServer si no existe
if (-not (Test-Path $hMailPath)) {
    # Instalar características de Windows
    Install-WindowsFeature -Name Web-Server, Web-Mgmt-Console
    
    # Descargar e instalar hMailServer
   # $hMailServerURL = "https://dl.freesoftru.net/apps/25/245/24404/hMailServer-5.6.8-B2574.exe"
    $hMailServerInstaller = "$env:TEMP\hMailServer.exe"
    Copy-Item -Path Z:\hMailServer-5.6.8-B2574.exe -Destination $hMailServerInstaller -Force
    try {
        #(New-Object System.Net.WebClient).DownloadFile($hMailServerURL, $hMailServerInstaller)
        Write-Host "hMailServer descargado correctamente"
        
        # Pedir contraseña para el administrador de hMailServer
        $adminPassword = Read-Host "Introduce la contraseña para el administrador de hMailServer" -AsSecureString
        $plainPassword = Convert-SecureString-To-PlainText -secureString $adminPassword
        
        # Instalar silenciosamente con contraseña
        $installArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /PASSWORD=$plainPassword"
        Start-Process -FilePath $hMailServerInstaller -ArgumentList $installArgs -Wait
        
        Write-Host "hMailServer instalado correctamente"
    }
    catch {
        Write-Host "Error al instalar hMailServer: $_" -ForegroundColor Red
        exit 1
    }
    finally {
        # Eliminar instalador temporal
        if (Test-Path $hMailServerInstaller) {
            Remove-Item $hMailServerInstaller -Force
        }
    }
}

# Registrar componente COM
$hMailServerDLL = "C:\Program Files (x86)\hMailServer\Bin\hMailServer.dll"
if (Test-Path $hMailServerDLL) {
    Write-Host "Registrando componente COM de hMailServer..."
    Start-Process "regsvr32.exe" -ArgumentList "/s `"$hMailServerDLL`"" -Wait -NoNewWindow
}

# Iniciar servicio
$serviceName = "hMailServer"
try {
    Start-Service $serviceName -ErrorAction Stop
    Write-Host "Servicio hMailServer iniciado"
}
catch {
    Write-Host "Error al iniciar el servicio hMailServer: $_" -ForegroundColor Red
}

# Autenticación en hMailServer
$userName = "Administrator"
$password = Read-Host -Prompt "Introduce la contraseña del usuario $userName" -AsSecureString
while (-not (Test-Credential -username $userName -password $password)) {
    Write-Host "Credenciales incorrectas. Inténtalo de nuevo."
    $password = Read-Host -Prompt "Introduce la contraseña del usuario $userName" -AsSecureString
}
$plainPassword = Convert-SecureString-To-PlainText -secureString $password

try {
    $hMail = New-Object -ComObject hMailServer.Application
    $hMail.Authenticate($userName, $plainPassword)
    
    # Crear dominio si no existe
    $domain = $hMail.Domains | Where-Object { $_.Name -eq $domainName }
    if (-not $domain) {
        $domain = $hMail.Domains.Add()
        $domain.Name = $domainName
        $domain.Active = $true
        $domain.Save()
        Write-Host "Dominio $domainName creado"
    }

    # Crear cuentas de usuario
    @(
        @{Name = "usuario1"; Password = "P@ssw0rd1" },
        @{Name = "usuario2"; Password = "P@ssw0rd2" }
    ) | ForEach-Object {
        $email = "$($_.Name)@$domainName"
        $account = $domain.Accounts | Where-Object { $_.Address -eq $email }
        if (-not $account) {
            $account = $domain.Accounts.Add()
            $account.Address = $email
            $account.Password = $_.Password
            $account.Active = $true
            $account.MaxSize = 100
            $account.Save()
            Write-Host "Cuenta creada: $email"
        }
    }

    # Habilitar protocolos
    $hMail.Settings.Protocols.IMAP.Enabled = $true
    $hMail.Settings.Protocols.POP3.Enabled = $true
    $hMail.Settings.Protocols.SMTP.Enabled = $true
    $hMail.Settings.Protocols.Save()
    Write-Host "Protocolos habilitados: IMAP, POP3, SMTP"
}
catch {
    Write-Host "Error al configurar hMailServer: $_" -ForegroundColor Red
    exit 1
}

# Configurar reglas de firewall
Write-Host "Configurando reglas de firewall..."
@(
    @{Name = "Allow SMTP"; Port = 25 }
    @{Name = "Allow POP3"; Port = 110 }
    @{Name = "Allow IMAP"; Port = 143 }
    @{Name = "Allow HTTP"; Port = 80 }
) | ForEach-Object {
    try {
        New-NetFirewallRule -DisplayName $_.Name -Direction Inbound `
            -Protocol TCP -LocalPort $_.Port -Action Allow -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "Error al crear regla de firewall para $($_.Name): $_" -ForegroundColor Yellow
    }
}

# Instalar SquirrelMail
$squirrelPath = "C:\inetpub\wwwroot\squirrelmail"
$squirrelUrl = "https://github.com/squirrelmail/squirrelmail/releases/download/1.4.22/squirrelmail-1.4.22.zip"

if (-not (Test-Path $squirrelPath)) {
    try {
        Write-Host "Instalando SquirrelMail..."
        New-Item -Path $squirrelPath -ItemType Directory -Force | Out-Null
        
        # Descargar y extraer SquirrelMail
        $tempFile = "$env:TEMP\squirrelmail.zip"
        Invoke-WebRequest -Uri $squirrelUrl -OutFile $tempFile -UseBasicParsing
        Expand-Archive -Path $tempFile -DestinationPath $squirrelPath -Force
        Remove-Item $tempFile -Force

        # Crear archivo de configuración
        $configContent = @"
<?php
`$imap_server_type = 'hmailserver';
`$imap_server_address = 'localhost';
`$imap_server_port = 143;
`$smtp_server_address = 'localhost';
`$smtp_server_port = 25;
`$domain = '$domainName';
?>
"@
        $configPath = Join-Path $squirrelPath "config\config.php"
        Set-Content -Path $configPath -Value $configContent -Encoding UTF8 -Force

        # Configurar permisos
        icacls $squirrelPath /grant "IIS_IUSRS:(OI)(CI)F" | Out-Null
        Write-Host "SquirrelMail instalado correctamente"
    }
    catch {
        Write-Host "Error al instalar SquirrelMail: $_" -ForegroundColor Red
        exit 1
    }
}

# Crear aplicación web
try {
    if (-not (Get-WebApplication -Name "squirrelmail" -Site "Default Web Site" -ErrorAction SilentlyContinue)) {
        $port = Read-Host "Ingresa el puerto del servicio de SquirrelMail: "
        while ($true) {
            if (-not (Test-PortValid -port $port)) {
                break
            }
            $port = Read-Host "Puerto no valido, porfavor ingresa un puerto valido"
        }
        New-WebApplication -Name "squirrelmail" -Site "Default Web Site" `
            -PhysicalPath $squirrelPath -ApplicationPool "DefaultAppPool" | Out-Null
        New-WebBinding -Name "squirrelmail" -IPAddress "*" -Port $port -HostHeader "Default Web Site" -Protocol "http" 
        Start-WebSite -Name "squirrelmail"
        Write-Host "Aplicación web SquirrelMail creada"
    }
}
catch {
    Write-Host "Error al crear aplicación web: $_" -ForegroundColor Red
}

# Iniciar servicios
try {
    Start-Service $serviceName -ErrorAction SilentlyContinue
    Start-Service W3SVC -ErrorAction SilentlyContinue
    Write-Host "Servicios iniciados"
}
catch {
    Write-Host "Error al iniciar servicios: $_" -ForegroundColor Yellow
}

# Obtener direcciones IP
try {
    $localServer = (Get-NetIPAddress -AddressFamily IPv4 | 
        Where-Object { $_.InterfaceAlias -like "*Ethernet*" } |
        Select-Object -First 1).IPAddress
    
    $privateServer = (Get-NetIPAddress -AddressFamily IPv4 | 
        Where-Object { $_.InterfaceAlias -like "*Ethernet 2*" } |
        Select-Object -First 1).IPAddress

    if (-not $localServer) {
        $localServer = (Get-NetIPAddress -AddressFamily IPv4 -SkipAsSource $false | 
            Select-Object -First 1).IPAddress
    }
    
    Write-Host "`nAcceso a SquirrelMail:"
    Write-Host " - Local: http://$localServer/squirrelmail" -ForegroundColor Green
    if ($privateServer) {
        Write-Host " - Privado: http://$privateServer/squirrelmail" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error al obtener direcciones IP: $_" -ForegroundColor Yellow
    Write-Host "Acceso a SquirrelMail: http://localhost/squirrelmail" -ForegroundColor Green
}

Write-Host "`nConfiguración completada exitosamente!" -ForegroundColor Cyan