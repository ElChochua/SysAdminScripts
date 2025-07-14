Import-Module Z:\Functions.psm1 -Force
$serversIps = get_adapter_ip -adapter "Ethernet 2"
$DhcpInDC=Get-DhcpServerInDC | ForEach-Object { $_.IPAddress.IPAddressToString }
$currentDomain=Get-Current-DomainName
if(-Not ($serversIps -eq $DhcpInDC)){
    Write-Host "Agregando Servicios al Dominio"
    Add-DhcpServerInDC -DnsName reprobados.com -IPAddress 192.168.1.5
    Set-DhcpServerv4OptionValue -ScopeId 192.168.1.0 -OptionId 6 -Value  192.168.1.5 -Force -ErrorAction SilentlyContinue
}
$groups=@("cuates","no cuates")
foreach ($group in $groups){
    if((Get-ADorganizationalUnit -Filter {Name -eq $group}) -eq $null){
        New-ADOrganizationalUnit -Name $group -Path "DC=$currentDomain,DC=com"
        Write-Host "El grupo $group ha sido creado." -ForegroundColor Green
    }else{
        Write-Host "El grupo $group ya existe asi que sera omitido." -ForegroundColor Yellow
    }
}
$numUsers = 2
for ($i = 0; $i -lt $numUsers; $i++) {
    $userName = Read-Host "Ingresa el nombre del usuario $($i+1)"
    while (-not (Validate-Username $userName)) {
        $username = Read-Host "Usuario invalido, ingresa un nombre valido"
    }
    $password = Read-Host -Prompt "Contraseña para $userName" -AsSecureString
    $unsecure = Convert-SecureString-To-PlainText $password
    while (-not (Validate-Password $unsecure)) {
        $password = Read-Host -Prompt "Contraseña invalida, ingresa una contraseña valida" -AsSecureString
        $unsecure = Convert-SecureString-To-PlainText $password
        if(Validate-Password $unsecure){
            break;
        }
    }
    $selectedGroup = Read-Host "Selecciona el grupo al que deseas agregar el usuario (cuates[0]/no cuates[1])"
    while ($selectedGroup -ne 0 -and $selectedGroup -ne 1) {
        $selectedGroup = Read-Host "Selecciona el grupo al que deseas agregar el usuario (cuates[0]/no cuates[1])"
    }
    $groupName = $groups[$selectedGroup]
    New-ADUser -Name $userName `
        -AccountPassword $password `
        -Enable $true `
        -Path "OU=$groupName,DC=$currentDomain,DC=com" `
        -UserPrincipalName "$userName@$currentDomain" `
        -PassThru
    Write-Host "El usuario $userName ha sido creado y agregado al grupo $groupName." -ForegroundColor Green
}   