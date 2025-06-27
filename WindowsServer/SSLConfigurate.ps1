Import-Module Z:\Functions.psm1 -Force
Install-WindowsFeature -Name Web-Ftp-Server -IncludeManagementTools
Install-WindowsFeature Web-Server -IncludeManagementTools
Import-Module WebAdministration

$groupAName = "reprobados"
$groupBName = "recursados"   

mkdir C:\FTP -ErrorAction SilentlyContinue
mkdir C:\FTP\General -ErrorAction SilentlyContinue
mkdir C:\FTP\General\Resources -ErrorAction SilentlyContinue
#Copy the resorces from Z:\Resources to C:\FTP\General\Resources
Copy-Item -Path "Z:\Resources\*" -Destination "C:\FTP\General\Resources" -Recurse -Force
mkdir C:\FTP\$groupAName -ErrorAction SilentlyContinue
mkdir C:\FTP\$groupBName -ErrorAction SilentlyContinue
mkdir C:\FTP\LocalUser -ErrorAction SilentlyContinue
mkdir C:\FTP\LocalUser\Public -ErrorAction SilentlyContinue

cmd /c mklink /D C:\FTP\LocalUser\Public\General C:\FTP\General
cmd /c mklink /D C:\FTP\LocalUser\Public\Resources C:\FTP\General\Resources

New-WebFTPSite -Name FTP -Port 21 -PhysicalPath "C:\FTP" -Force

net localgroup "general" /add 
net localgroup "$groupAName" /add
net localgroup "$groupBName" /add 

Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value 1
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value 1
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly"

Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType = "Allow"; users = "*"; permissions = 1 } -PSPath IIS:\ -Location "FTP"

Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/General" -Filter "system.ftpServer/security/authorization" -Name "."
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$groupAName" -Filter "system.ftpServer/security/authorization" -Name "."
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$groupBName" -Filter "system.ftpServer/security/authorization" -Name "."

Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType = "Allow"; users = "*"; permissions = 1 } -PSPath IIS:\ -Location "FTP/General"
Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType = "Allow"; roles = "general"; permissions = 3 } -PSPath IIS:\ -Location "FTP/General"
Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType = "Allow"; roles = "$groupAName"; permissions = 3 } -PSPath IIS:\ -Location "FTP/$groupAName"
Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType = "Allow"; roles = "$groupBName"; permissions = 3 } -PSPath IIS:\ -Location "FTP/$groupBName"
Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType = "Allow"; users = "*"; permissions = 1 } -PSPath IIS:\ -Location "FTP/General/Resources"

$usuarios = Read-Host "Cuantos usuarios planeas agregar? "
for ($i = 1; $i -le $usuarios; $i++) {
    $username = Read-Host "Ingresa el nombre del usuario"
    while (-not (Validate-Username $username)) {
        $username = Read-Host "Ingresa un nombre de usuario valido"
    }

    if (Test-UserExists $username -and Test-UserNotInGroups $username) {
        Write-Host "El usuario ya existe y no pertenece a ningun grupo. Quieres agregarlo a un grupo? [Y/N]"
        $answer = Read-Host
        if ($answer -eq "Y") {
            $group = Read-Host "Ingresa el grupo al que pertenece  `n`A:$groupAName `n`B:$groupBName"
            net localgroup "general" $username /add
            mkdir "C:\FTP\$username"
            mkdir "C:\FTP\LocalUser\$username"
            cmd /c mklink /D "C:\FTP\LocalUser\$username\$username"  "C:\FTP\$username"
            cmd /c mklink /D "C:\FTP\LocalUser\$username\General" "C:\FTP\General"
            cmd /c mklink /D "C:\FTP\LocalUser\$username\Resources" "C:\FTP\General\Resources"
            Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$username" -Filter "system.ftpServer/security/authorization" -Name "."
            Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType = "Allow"; users = "$username"; permissions = 3 } -PSPath IIS:\ -Location "FTP/$username"
            if ($group -eq "A") {
                net localgroup "$groupAName" "$username" /add
                cmd /c mklink /D "C:\FTP\LocalUser\$username\$groupAName" "C:\FTP\$groupAName"
            }
            elseif ($group -eq "B") {
                net localgroup "$groupBName" $username /add
                cmd /c mklink /D "C:\FTP\LocalUser\$username\$groupBName" "C:\FTP\$groupBName"
            }
        }
        continue
    }
    else {
        $password = Read-Host "Ingresa la contraseña"
        while (-not (validate-password $password)) {
            $password = Read-Host "Ingresa una contraseña valida"
        }
        $group = Read-Host "Ingresa el grupo al que pertenece  `n`A:$groupAName `n`B:$groupBName"
        net user "$username" "$password" /add
        net localgroup "general" $username /add
        mkdir "C:\FTP\$username"
        mkdir "C:\FTP\LocalUser\$username"
        cmd /c mklink /D "C:\FTP\LocalUser\$username\$username"  "C:\FTP\$username"
        cmd /c mklink /D "C:\FTP\LocalUser\$username\General" "C:\FTP\General"
        cmd /c mklink /D "C:\FTP\LocalUser\$username\Resources" "C:\FTP\General\Resources"
        Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$username" -Filter "system.ftpServer/security/authorization" -Name "."
        Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType = "Allow"; users = "$username"; permissions = 3 } -PSPath IIS:\ -Location "FTP/$username"
        if ($group -eq "A") {
            net localgroup "$groupAName" "$username" /add
            cmd /c mklink /D "C:\FTP\LocalUser\$username\$groupAName" "C:\FTP\$groupAName"
        }
        elseif ($group -eq "B") {
            net localgroup "$groupBName" $username /add
            cmd /c mklink /D "C:\FTP\LocalUser\$username\$groupBName" "C:\FTP\$groupBName"
        }
    }
}

Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
$sslChoise = Read-Host "Quieres instalar un certificado SSL? [S/N]"
if ($sslChoise -eq "S") {
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike '*Loopback*' }).IPAddress
    $cert = New-SelfSignedCertificate -DnsName $ipAddress `
        -CertStoreLocation "Cert:\LocalMachine\My" `
        -FriendlyName "FTP SSL Cert" `
        -NotAfter (Get-Date).AddYears(5)

    $thumbprint = $cert.Thumbprint
    $ftpSiteName = "FTP"  
    
    Set-ItemProperty "IIS:\Sites\$ftpSiteName" -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslRequire"
    Set-ItemProperty "IIS:\Sites\$ftpSiteName" -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslRequire"
    Set-ItemProperty "IIS:\Sites\$ftpSiteName" -Name ftpServer.security.ssl.serverCertHash -Value $thumbprint
    Set-ItemProperty "IIS:\Sites\$ftpSiteName" -Name ftpServer.security.ssl.serverCertStoreName -Value "My"
}
Restart-WebItem "IIS:\Sites\FTP" -Verbose
$httpChoise = Read-Host "Quieres agregar un servicio HTTP? [S/N]"
if ($httpChoise -eq "S") {
    Z:\HTTPInstaller.ps1
}
else {
    Write-Output "No se ha agregado un servicio HTTP"
}
Write-Output "Servidor corriendo en ftp://$(Get-IP-Address)"
