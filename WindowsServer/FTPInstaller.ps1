Install-WindowsFeature -Name Web-Ftp-Server -IncludeManagementTools
Install-WindowsFeature Web-Server -IncludeManagementTools
Import-Module WebAdministration

$groupAName = Read-Host "Ingresa el nombre del grupo A"
$groupBName = Read-Host "Ingresa el nombre del grupo B"

mkdir C:\FTP
mkdir C:\FTP\General
mkdir C:\FTP\$groupAName
mkdir C:\FTP\$groupBName
mkdir C:\FTP\LocalUser
mkdir C:\FTP\LocalUser\Public

cmd /c mklink /D C:\FTP\LocalUser\Public\General C:\FTP\General

New-WebFTPSite -Name FTP -Port 21 -PhysicalPath "C:\FTP"

net localgroup "general" /add
net localgroup "$groupAName" /add
net localgroup "$groupBName" /add

Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value 1
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value 1
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly"

Add-WebConfiguration "/system.ftpServer/security/authorization" -value @{accessType="Allow";users="*";permissions=1} -PSPath IIS:\ -Location "FTP"

Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/General" -Filter "system.ftpServer/security/authorization" -Name "."
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$groupAName" -Filter "system.ftpServer/security/authorization" -Name "."
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$groupBName" -Filter "system.ftpServer/security/authorization" -Name "."

Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType="Allow";users="*";permissions=1} -PSPath IIS:\ -Location "FTP/General"
Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="general";permissions=3} -PSPath IIS:\ -Location "FTP/General"
Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="$groupAName";permissions=3} -PSPath IIS:\ -Location "FTP/$groupAName"
Add-WebConfiguration "system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="$groupBName";permissions=3} -PSPath IIS:\ -Location "FTP/$groupBName"

$usuarios = Read-Host "Cuantos usuarios planeas agregar? "
for ($i = 1; $i -le $usuarios; $i++) {
    <# Action that will repeat until the condition is met #>
    $username = Read-Host "Ingresa el nombre del usuario"
    $password = Read-Host "Ingresa la contraseña"
    $group = Read-Host "Ingresa el grupo al que pertenece  `n`A:$groupAName `n`B:$groupBName"
    net user "$username" "$password" /add
    net localgroup "general" $username /add
    mkdir "C:\FTP\$username"
    mkdir "C:\FTP\LocalUser\$username"
    cmd /c mklink /D "C:\FTP\LocalUser\$username\$username"  "C:\FTP\$username"
    cmd /c mklink /D "C:\FTP\LocalUser\$username\General" "C:\FTP\General"

    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTP/$username" -Filter "system.ftpServer/security/authorization" -Name "."
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="$username";permissions=3} -PSPath IIS:\ -Location "FTP/$username"


    if ($group -eq "A") {
        <# Action to perform if the condition is true #>
        net localgroup "$groupAName" "$username" /add
        cmd /c mklink /D "C:\FTP\LocalUser\$username\$groupAName" "C:\FTP\$groupAName"
    }elseif ($group -eq "B") {
        <# Action when this condition is true #>
        net localgroup "$groupBName" $username /add
        cmd /c mklink /D "C:\FTP\LocalUser\$username\$groupBName" "C:\FTP\$groupBName"
    }
}
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0

Restart-WebItem "IIS:\Sites\FTP" -Verbose

Set-NetFireWallProfile -Profile Private,Domain,Public -Enabled False