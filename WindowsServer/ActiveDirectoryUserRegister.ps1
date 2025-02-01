$domainName = Read-Host -Prompt "Dominio "
$workgroup = Read-Host -Prompt "Organizacion AD "

#New-ADOrganizationalUnit -Name "$workgroup" -Path "DC=$domain,DC=com"
$windows = Read-Host -Prompt "Usuario Windows "
$windowsPass = Read-Host -Prompt "Contrasenia "
$ubuntu = Read-Host -Prompt "Usuario Ubuntu "
$ubuntuPass = Read-Host -Prompt "Contrasenia "

# Agregamos a los usuarios
New-ADUser -Name "$windows" -AccountPassword (ConvertTo-SecureString "$windowsPass" -AsPlainText -Force) -Enable $true -Path "OU=$workgroup,DC=$domainName,DC=com" -UserPrincipalName "$windows@$domainName.com"
New-ADUser -Name "$ubuntu" -AccountPassword (ConvertTo-SecureString "$ubuntuPass" -AsPlainText -Force) -Enable $true -Path "OU=$workgroup,DC=$domainName,DC=com" -UserPrincipalName "$ubuntu@$domainName.com"
Get-ADUser -Filter *
