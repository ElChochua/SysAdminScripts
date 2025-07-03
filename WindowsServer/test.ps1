Import-Module Z:\Functions.psm1 -Force
<#

$redisx86 = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
$redisx64 = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$redisx86Path = "C:\Users\Administrator\Downloads\vc_redist.x86.exe"
$redisx64Path = "C:\Users\Administrator\Downloads\vc_redist.x64.exe"
#Download the redistributable files
(New-Object System.Net.WebClient).DownloadFile($redisx86, $redisx86Path)
(New-Object System.Net.WebClient).DownloadFile($redisx64, $redisx64Path)


Start-Process -FilePath $redisx64Path -ArgumentList "/install", "/quiet", "/norestart" -Wait
Start-Process -FilePath $redisx86Path -ArgumentList "/install", "/quiet", "/norestart" -Wait

write-host "Redistributable files installed successfully."
#Remove the redistributable files
Remove-Item -Path $redisx86Path -Force
Remove-Item -Path $redisx64Path -Force

$tempdir = Get-Location
$tempdir = $tempdir.tostring()

.\multiotp.exe -config default-request-prefix-pin=0
.\multiotp.exe -config default-request-ldap-pwd=0
.\multiotp.exe -config ldap-server-type=1
.\multiotp.exe -config ldap-cn-identifier="sAMAccountName"
.\multiotp.exe -config ldap-group-cn-identifier="sAMAccountName"
.\multiotp.exe -config ldap-group-attribute="memberof"
.\multiotp.exe -config ldap-ssl=0
.\multiotp.exe -config ldap-ssl-port=389
.\multiotp.exe -config ldap-domain-controllers=reprobados.com,ldaps://192.168.1.5:389
.\multiotp.exe -config ldap-base-dn="DC=$domainName,DC=com"
.\multiotp.exe -config ldap-bind-dn="CN=Administrator,CN=Users,DC=reprobados,DC=com"
.\multiotp.exe -config ldap-bind-pwd="S2ltb1wk**"
.\multiotp.exe -config ldap-in-group=
.\multiotp.exe -config ldap-network-timeout=10
.\multiotp.exe -config ldap-time-limit=30
.\multiotp.exe -config ldap-activated=1
.\multiotp.exe -config debug=1
.\multiotp.exe -config server-secret=secretOTP
.\multiotp.exe -config 

#>
#Get-WinEvent -LogName Security | Where-Object { $_.Id -in @(5136, 4720, 4726, 4662) } | Select-Object TimeCreated, Id, Message -Last 40
#Get-EventLog -LogName Security -Newest 50 | Where-Object {$_.Id -in @(5136, 4720, 4726, 4662, 4364)} | Select-Object TimeGenerated, EventID, Message
$userName = Read-Host "Introduce el nombre de usuario"
$password = Read-Host "Introduce la contraseña" -AsSecureString
$group = Read-Host "Introduce el nombre del grupo al que se añadirá el usuario"
$groupName = ""
if ($group -eq 1) {
    $groupName = "group_1"
}
else {
    $groupName = "group_2"
}
$domainName = "reprobados"
CreateNewUserInDomain -userName $userName -password $password -groupName $groupName -domainName $domainName
$group1Users = Get-ADUser -Filter * -SearchBase "OU=group_1,DC=reprobados,DC=com"
$group2Users = Get-ADUser -Filter * -SearchBase "OU=group_2,DC=reprobados,DC=com"
foreach ($user in $group1Users) {
    Set-LogonHours -Identity $($user.SamAccountName)  -TimeIn24Format @(8, 14) -Monday -Tuesday -Wednesday -Thursday -Friday -Saturday -Sunday -NonSelectedDaysare NonWorkingDays
}
$group_2_users = Get-ADUser -Filter * -SearchBase "OU=group_2,DC=reprobados,DC=com"  
foreach ($user in $group2Users) {
    Set-LogonHours -Identity $($user.SamAccountName)   -TimeIn24Format @(15..23 + 0..2) -Monday -Tuesday -Wednesday -Thursday -Friday -Saturday -Sunday -NonSelectedDaysare NonWorkingDays
}
 