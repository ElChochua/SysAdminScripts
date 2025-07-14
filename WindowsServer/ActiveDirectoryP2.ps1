Import-Module Z:\Functions.psm1 -Force
Import-Module ActiveDirectory
$domainName = Get-Current-DomainName
$groups = @("group_1", "group_2")
if ($domainName -eq $null) {
    Write-Host "No se ha podido obtener el nombre del dominio actual." -ForegroundColor Red
    exit
}
foreach ($group in $groups) {
    if ((Get-ADOrganizationalUnit -Filter { Name -eq $group }) -eq $null) {
        New-ADOrganizationalUnit -Name $group -Path "DC=$domainName,DC=com"
        Write-Host "El grupo $group ha sido creado." -ForegroundColor Green
    }
    else {
        Write-Host "El grupo $group ya existe, se omitirá." -ForegroundColor Yellow
    }
}
#$ErrorActionPreference = 'SilentlyContinue'
#check if the profile folder exists, if not create it
#Create the folder for the users
$profilePath = "C:\Profiles"
if (-not (Test-Path -Path $profilePath)) {
    New-Item -ItemType Directory -Name "Profiles" -Path "C:\"
    New-SmbShare -Name "Profiles" -Path "$profilePath"
    Grant-SmbShareAccess -Name "Profiles" -AccountName "Everyone" -AccessRight Full -Confirm:$false
    Write-Host "La carpeta de perfiles ha sido creada en $profilePath." -ForegroundColor Green
}
else {
    Write-Host "La carpeta de perfiles ya existe en $profilePath." -ForegroundColor Yellow
}

#if the folder multiOtp exists, dont create it again
if (-not(Test-Path -Path "C:\multiotp")) {
    #Stop the services if they are running
    $option = Read-Host "Parece que ya existe una instalacion de multiOTP, deseas re-instalarlo? (S/N)"
    if ($option -eq "S") {
        Write-Host "Re-instalando multiOTP." -ForegroundColor Green
        Start-Process -FilePath "C:\multiotp\radius_uninstall.cmd" -Verb RunAs -Wait
        Start-Process -FilePath "C:\multiotp\webservice_uninstall.cmd" -Verb RunAs -Wait
        $PROCESSES_TO_KILL = @(
            "nssm",
            "nginx",
            "radiusd",
            "SRVANY"
        )
        foreach ($PROCESS in $PROCESSES_TO_KILL) {
            $processes = Get-Process -Name $PROCESS -ErrorAction SilentlyContinue
            if ($processes) {
                foreach ($process in $processes) {
                    Stop-Process -Id $process.Id -Force
                }
            }
        }
        Set-Location -Path "C:\"
        Remove-Item -Path "C:\multiotp" -Recurse -Force

        
        $urlMultiOtp = "https://download.multiotp.net/multiotp_5.9.9.1.zip"
        $outputOtpPath = "C:\Users\Administrator\Downloads\multiotp.zip"
        $extractOtpPath = "C:\Users\Administrator\Downloads\multiotp"
        if (-not(Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Visual C++*" }
            )) {
            $redisx86 = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
            $redisx64 = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            $redisx86Path = "C:\Users\Administrator\Downloads\vc_redist.x86.exe"
            $redisx64Path = "C:\Users\Administrator\Downloads\vc_redist.x64.exe"
            #Download the redistributable files
    (New-Object System.Net.WebClient).DownloadFile($redisx86, $redisx86Path)
    (New-Object System.Net.WebClient).DownloadFile($redisx64, $redisx64Path)
            #install the multiotp and multiotp service
            Start-Process -FilePath $redisx64Path -ArgumentList "/install", "/quiet", "/norestart" -Wait
            Start-Process -FilePath $redisx86Path -ArgumentList "/install", "/quiet", "/norestart" -Wait
            #Remove the redistributable files
            Remove-Item -Path $redisx86Path -Force
            Remove-Item -Path $redisx64Path -Force
        }

        #Download the files and extract them in downloads folder
(New-Object System.Net.WebClient).DownloadFile($urlMultiOtp, $outputOtpPath)

        write-host "Redistributable files installed successfully."
        Expand-Archive -Path $outputOtpPath -DestinationPath $extractOtpPath -Force

        Rename-Item -Path "$extractOtpPath\windows" -NewName "multiOTP" -Force
        Copy-Item -Path "$extractOtpPath\multiotp" -Destination "C:\" -Recurse -Force
        Set-Location -Path "C:\multiOTP"
        Start-Process -FilePath "C:\multiOTP\radius_install.cmd" -Verb RunAs -Wait
        Start-Process -FilePath "C:\multiOTP\webservice_install.cmd" -Verb RunAs -Wait
        #group to group the users of multiOTP
        $group = Get-ADGroup -Filter { Name -eq "multiOtpGroup" } -ErrorAction SilentlyContinue
        if (-not($group)) {
            New-ADgroup -Name "multiOtpGroup" -GroupScope Global -Description "Grupo de usuarios multiOTP"
            Write-Host "El grupo multiOtpGroup ha sido creado." -ForegroundColor Green
            #Add the administrator to the group to make changes in the group
            Add-ADGroupMember -Identity "multiOtpGroup" -Members "Administrator"
            #Select the users from group_1 and group_2
            $group1Users = Get-ADUser -Filter * -SearchBase "OU=group_1,DC=$domainName,DC=com"
            $group2Users = Get-ADUser -Filter * -SearchBase "OU=group_2,DC=$domainName,DC=com"
            #Add the users to the multiOtpGroup
            foreach ($user in $group1Users) {
                #if the user already exists in the group, skip it
                if (Get-ADGroupMember -Identity "multiOtpGroup" | Where-Object { $_.SamAccountName -eq $user.SamAccountName }) {
                    Write-Host "El usuario $($user.SamAccountName) ya existe en el grupo multiOtpGroup, se omitirá." -ForegroundColor Yellow
                    continue
                }
                Add-ADGroupMember -Identity "multiOtpGroup" -Members $user
                Write-Host "El usuario $($user.SamAccountName) ha sido agregado al grupo multiOtpGroup." -ForegroundColor Green
            }
            foreach ($user in $group2Users) {
                if (Get-ADGroupMember -Identity "multiOtpGroup" | Where-Object { $_.SamAccountName -eq $user.SamAccountName }) {
                    Write-Host "El usuario $($user.SamAccountName) ya existe en el grupo multiOtpGroup, se omitirá." -ForegroundColor Yellow
                    continue
                }
                Add-ADGroupMember -Identity "multiOtpGroup" -Members $user
                Write-Host "El usuario $($user.SamAccountName) ha sido agregado al grupo multiOtpGroup." -ForegroundColor Green
            }
        }
        else {
            Write-Host "El grupo multiOtpGroup ya existe, se omitirá." -ForegroundColor Yellow
        }
        .\multiotp.exe -config default-request-prefix-pin=0
        .\multiotp.exe -config default-request-ldap-pwd=0
        .\multiotp.exe -config ldap-server-type=1
        .\multiotp.exe -config ldap-cn-identifier="sAMAccountName"
        .\multiotp.exe -config ldap-group-cn-identifier="sAMAccountName"
        .\multiotp.exe -config ldap-group-attribute="memberOf"
        .\multiotp.exe -config ldap-ssl=1
        .\multiotp.exe -config ldap-ssl-port=636
        .\multiotp.exe -config ldap-domain-controllers=reprobados.com,ldap://192.168.1.5:636
        .\multiotp.exe -config ldap-base-dn="DC=reprobados,DC=com"
        .\multiotp.exe -config ldap-bind-dn="CN=Administrator,CN=Users,DC=reprobados,DC=com"
        .\multiotp.exe -config ldap-server-password=S2ltb1wk**
        .\multiotp.exe -config ldap-in-group=multiOtpGroup
        .\multiotp.exe -config ldap-network-timeout=10
        .\multiotp.exe -config ldap-time-limit=30
        .\multiotp.exe -config ldap_activated=1
        .\multiotp.exe -config debug=1
        .\multiotp.exe -config server_secret=secretOTP

        #remove downloaded files
        Remove-Item -Path $outputOtpPath -Force

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
            
            #while user already exists ask for a new username
            while ((Get-ADUser -Identity $userName -ErrorAction SilentlyContinue)) {
                $userName = Read-Host "Usuario ya existe, ingresa un nombre valido"
                $user = Get-ADUser -Identity $userName -ErrorAction SilentlyContinue
            }
            while (-not (Validate-Password $unsecure)) {
                $password = Read-Host -Prompt "Contraseña invalida, ingresa una contraseña valida" -AsSecureString
                $unsecure = Convert-SecureString-To-PlainText $password
                if (Validate-Password $unsecure) {
                    break;
                }
            }
            $selectedGroup = Read-Host "Selecciona el grupo al que deseas agregar el usuario (Grupo1[1] /Grupo2[2])"
            while ($selectedGroup -lt 1 -or $selectedGroup -gt 2) {
                $selectedGroup = Read-Host "Selecciona el grupo al que deseas mover el usuario (Grupo1[1] /Grupo2[2])"
            }
            $groupName = $groups[$selectedGroup - 1]
            CreateNewUserInDomain -userName $userName -password $password -groupName $groupName -domainName $domainName
        }   
    }
}
elseif ($option -eq "M") {
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
        Add-ADGroupMember -Identity "multiOtpGroup" -Members $userName
    }
}
Set-Location -Path "C:\multiOTP"
.\multiotp.exe -debug -display-log -ldap-users-sync

#Role Creation
#pos yano, se cancela

#Policy Creation
$group1PolicyName = "Group_1_Policy"
$group2PolicyName = "Group_2_Policy"
#Set-PasswordPolicy
#if the policy already exist remove it
if (Get-GPO -Name $group1PolicyName -ErrorAction SilentlyContinue) {
    Remove-GPO -Name $group1PolicyName -Confirm:$false -ErrorAction SilentlyContinue
    Remove-GPLink -Name $group1PolicyName -Target "OU=$($groups[0]),DC=$domainName,DC=com" -Confirm:$false -ErrorAction SilentlyContinue
}
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

#Set the logon hours for each user in group
if (Get-GPO -Name $group2PolicyName -ErrorAction SilentlyContinue) {
    remove-gpo -name $group2PolicyName -confirm:$false -ErrorAction SilentlyContinue
    Remove-GPLink -Name $group2PolicyName -Target "OU=$($groups[1]),DC=$domainName,DC=com" -Confirm:$false -ErrorAction SilentlyContinue
}
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
#Auditory Enabled
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Directory Service Access" /success:enable /failure:enable
$group_1_users = Get-ADUser -Filter * -SearchBase "OU=group_1,DC=reprobados,DC=com"  
foreach ($user in $group_1_users){
    Set-LogonHours -Identity $($user.SamAccountName)  -TimeIn24Format @(8,14) -Monday -Tuesday -Wednesday -Thursday -Friday -Saturday -Sunday -NonSelectedDaysare NonWorkingDays
 }
$group_2_users = Get-ADUser -Filter * -SearchBase "OU=group_2,DC=reprobados,DC=com"  
foreach ($user in $group_2_users){
    Set-LogonHours -Identity $($user.SamAccountName)   -TimeIn24Format @(15..23 + 0..2) -Monday -Tuesday -Wednesday -Thursday -Friday -Saturday -Sunday -NonSelectedDaysare NonWorkingDays
}
 