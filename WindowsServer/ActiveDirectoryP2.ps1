Import-Module Z:\Functions.psm1 -Force
Import-Module ActiveDirectory
$ErrorActionPreference = 'SilentlyContinue'
#Create the folder for the users
#check if the profile folder exists, if not create it
$profilePath = "C:\Profiles"
if (-not (Test-Path -Path $profilePath)) {
    New-Item -ItemType Directory -Name "Profiles" -Path "C:\"
    New-SmbShare -Name "Profiles" -Path "$profilePath"
    Grant-SmbShareAccess -Name "Profiles" -AccountName "Everyone" -AccessRight Full
    Write-Host "La carpeta de perfiles ha sido creada en $profilePath." -ForegroundColor Green
} else {
    Write-Host "La carpeta de perfiles ya existe en $profilePath." -ForegroundColor Yellow
}

$urlMultiOtp = "https://github.com/multiOTP/multiotp/releases/download/5.9.9.1/multiotp_5.9.9.1.zip"
$outputOtpPath = "C:\Users\Administrator\Downloads\multiotp.zip"
$extractOtpPath = "C:\Users\Administrator\Downloads\multiotp"

$urlMultiOtpCredentials = "https://github.com/multiOTP/multiOTPCredentialProvider/releases/download/5.9.9.2/multiOTPCredentialProvider-5.9.9.2.zip"
$outputOtpCredentialsPath = "C:\Users\Administrator\Downloads\multiOTPCredentialProvider.zip"
$extractOtpCredentialsPath = "C:\Users\Administrator\Downloads\multiOTPCredentialProvider"
#Download the files and extract them in downloads folder
#(New-Object System.Net.WebClient).DownloadFile($urlMultiOtp, $outputOtpPath)
#(New-Object System.Net.WebClient).DownloadFile($urlMultiOtpCredentials, $outputOtpCredentialsPath)
#Expand-Archive -Path $outputOtpPath -DestinationPath $extractOtpPath -Force
#Expand-Archive -Path $outputOtpCredentialsPath -DestinationPath $extractOtpCredentialsPath -Force
#remove the zip files
#Remove-Item -Path $outputOtpPath -Force
#Remove-Item -Path $outputOtpCredentialsPath -Force
#install the multiotp and multiotp service
$serverAddress = Get-IP-Address
$groups = @("group_1","group_2")
$domainName = Get-Current-DomainName
if($domainName -eq $null) {
    Write-Host "No se ha podido obtener el nombre del dominio actual." -ForegroundColor Red
    exit
}
foreach ($group in $groups) {
    if ((Get-ADOrganizationalUnit -Filter {Name -eq $group}) -eq $null) {
        New-ADOrganizationalUnit -Name $group -Path "DC=$domainName,DC=com"
        Write-Host "El grupo $group ha sido creado." -ForegroundColor Green
    } else {
        Write-Host "El grupo $group ya existe, se omitirá." -ForegroundColor Yellow
    }
}
Write-Host "Crear los usuarios"
$option = Read-Host "¿Quieres crear usuarios o mover usuarios a los grupos? (C/M)"
if ($option -eq "C") {
    $numUsers = Read-Host -Prompt "Numero de usuarios a crear"
    for ($i = 1; $i -le $numUsers; $i++) {

        for ($i = 0; $i -lt $numUsers; $i++) {
            $userName = Read-Host "Ingresa el nombre del usuario $($i+1)"
            while (-not (Validate-Username $userName)) {
                $username = Read-Host "Usuario invalido, ingresa un nombre valido"
            }
            $password = Read-Host -Prompt "Contraseña para $userName" -AsSecureString
            $unsecure = Convert-SecureString-To-PlainText $password
            $user = Get-ADUser -Identity $userName -ErrorAction SilentlyContinue
            #while user already exists ask for a new username
            while ($user -ne $null) {
                $userName = Read-Host "Usuario ya existe, ingresa un nombre valido"
                $user = Get-ADUser -Identity $userName -ErrorAction SilentlyContinue
            }
            while (-not (Validate-Password $unsecure)) {
                $password = Read-Host -Prompt "Contraseña invalida, ingresa una contraseña valida" -AsSecureString
                $unsecure = Convert-SecureString-To-PlainText $password
                if(Validate-Password $unsecure){
                    break;
                }
            }
            $selectedGroup = Read-Host "Selecciona el grupo al que deseas agregar el usuario (Grupo1[1] /Grupo2[2])"
            while ($selectedGroup -lt 1 -or $selectedGroup -gt 2) {
                $selectedGroup = Read-Host "Selecciona el grupo al que deseas mover el usuario (Grupo1[1] /Grupo2[2])"
            }
            $groupName = $groups[$selectedGroup - 1]
            New-ADUser -Name $userName `
                -AccountPassword $password `
                -Enable $true `
                -Path "OU=$groupName,DC=$domainName,DC=com" `
                -UserPrincipalName "$userName@$domainName" `
                -PassThru
            Set-ADUser -Identity "$userName" -ProfilePath "\\$env:COMPUTERNAME\Profiles\$($userName)"
            Write-Host "El usuario $userName ha sido creado y agregado al grupo $groupName." -ForegroundColor Green
            #create user folder in profile path
        }   
    }
}
else {
    $user_move_count = Read-Host "¿Cuántos usuarios deseas mover?"
    for ($i = 1; $i -le $user_move_count; $i++) {
        $user_name = Read-Host "Nombre del usuario a mover:"
        $user = Get-ADUser -Identity $user_name
        #while user not exists ask for a new username
        while ($user -eq $null) {
            $user_name = Read-Host "Usuario no encontrado, ingresa un nombre valido"
            $user = Get-ADUser -Identity $user_name
        }
        $selectedGroup = Read-Host "Selecciona el grupo al que deseas mover el usuario (Grupo1[1] /Grupo2[2])"
        $target_group = $groups[$selectedGroup - 1]
        while ($selectedGroup -lt 1 -or $selectedGroup -gt 2) {
            $selectedGroup = Read-Host "Selecciona el grupo al que deseas mover el usuario (Grupo1[1] /Grupo2[2])"
        }
        Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=$target_group,DC=$domainName,DC=com"
        #$logonHoursInput = Read-Host -Prompt "Horas a trabajar (ej. 1,2,3)"
        #$logonHours = $logonHoursInput -split ',' | ForEach-Object { [int]$_ }
        #Set-LogonHours -Identity "$user_name" -TimeIn24Format $logonHours -Monday -Tuesday -Wednesday -Thursday -Friday
    }
}
#Role Creation
#pos yano, se cancela

#Policy Creation
$group1PolicyName = "Group_1_Policy"
$group2PolicyName = "Group_2_Policy"
#if the policy already exist continue
if (Get-GPO -Name $group1PolicyName -ErrorAction SilentlyContinue) {
    Write-Host "La política $group1PolicyName ya existe, se omitirá." -ForegroundColor Yellow
} else {
    Write-Host "Creando la política $group1PolicyName." -ForegroundColor Green
    New-GPO -Name "$group1PolicyName" -Comment "Policy For Group 1, can only logon on 8:00 to 15:00. Grupo 1 can only store files of 5MB. Grupo 1 can only use notepad." -ErrorAction SilentlyContinue
    New-GPLink -Name "$group1PolicyName" -Target "OU=$($groups[0]),DC=$domainName,DC=com" -LinkEnabled Yes -Enforced No -ErrorAction SilentlyContinue
    #Grupo 1 can only logon on 8:00 to 15:00. Grupo 1 can only store files of 5MB. Grupo 1 can only use notepad.
    Start-Sleep -Seconds 2
    Set-GPRegistryValue -Name "$group1PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName RestrictRun -Type DWord -Value 1
    Set-GPRegistryValue -Name "$group1PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\RestrictRun" -ValueName 1 -Type String -Value notepad.exe
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName RestrictRun -Type String -Value "Esta Aplicacion esta bloqueada. Si crees que es un error, contacta al administrador"
    Set-GPRegistryValue -Name "$group1PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName MaxProfileSize -Type DWord -Value 5120
    Set-GPRegistryValue -Name "$group1PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName EnableProfileQuota -Type DWord -Value 1
    Set-GPRegistryValue -Name "$group1PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName WarnUser -Type DWord -Value 1
    Set-GPRegistryValue -Name "$group1PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName WarnUserTimeout -Type DWord -Value 10
    Set-GPRegistryValue -Name "$group1PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName ProfileQuotaMessage -Type String -Value "Este Archivo supera el limite de 5MB"
}
if (Get-GPO -Name $group2PolicyName -ErrorAction SilentlyContinue) {
    Write-Host "La política $group2PolicyName ya existe, se omitirá." -ForegroundColor Yellow
}else{
    New-GPO -Name "$group2PolicyName" -Comment "Policy For Group 2, can only logon on 15:00 to 02:00. Grupo 2 can access every program except notepad. Grupo 2 can only store files of 10MB." -ErrorAction SilentlyContinue
    New-GPLink -Name "$group2PolicyName" -Target "OU=$($groups[1]),DC=$domainName,DC=com" -LinkEnabled Yes -Enforced No -ErrorAction SilentlyContinue
    Write-Host "Asignacion de reglas a las OU's"
    #Grupo 2 can only logon on 15:00 to 02:00. Grupo 2 can access every program except notepad. Grupo 2 can only store files of 10MB.
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName DisallowRun -Type DWord -Value 1
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" -ValueName 1 -Type String -Value notepad.exe
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName DisallowRun -Type String -Value "Esta Aplicacion esta bloqueada. Si crees que es un error, contacta al administrador"
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName EnableProfileQuota -Type DWord -Value 1
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName MaxProfileSize -Type DWord -Value 10240
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName WarnUser -Type DWord -Value 1
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName WarnUserTimeout -Type DWord -Value 10
    Set-GPRegistryValue -Name "$group2PolicyName" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName ProfileQuotaMessage -Type String -Value "Este Archivo supera el limite de 10MB"
}
#Auditory Enabled
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Directory Service Access" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Lockout" /success:enable /failure:enable


