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

Write-host $plainPassword