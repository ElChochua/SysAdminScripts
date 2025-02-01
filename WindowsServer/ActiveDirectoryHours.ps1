Function Set-LogonHours{
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True)]
    [ValidateRange(0,23)]
    $TimeIn24Format,
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True,
    ValueFromPipelineByPropertyName=$True, 
    Position=0)]$Identity,
    [parameter(mandatory=$False)]
    [ValidateSet("WorkingDays", "NonWorkingDays")]$NonSelectedDaysare="NonWorkingDays",
    [parameter(mandatory=$false)][switch]$Sunday,
    [parameter(mandatory=$false)][switch]$Monday,
    [parameter(mandatory=$false)][switch]$Tuesday,
    [parameter(mandatory=$false)][switch]$Wednesday,
    [parameter(mandatory=$false)][switch]$Thursday,
    [parameter(mandatory=$false)][switch]$Friday,
    [parameter(mandatory=$false)][switch]$Saturday
    )
    Process{
    $FullByte=New-Object "byte[]" 21
    $FullDay=[ordered]@{}
    0..23 | foreach{$FullDay.Add($_,"0")}
    $TimeIn24Format.ForEach({$FullDay[$_]=1})
    $Working= -join ($FullDay.values)
    Switch ($PSBoundParameters["NonSelectedDaysare"])
    {
    'NonWorkingDays' {$SundayValue=$MondayValue=$TuesdayValue=$WednesdayValue=$ThursdayValue=$FridayValue=$SaturdayValue="000000000000000000000000"}
    'WorkingDays' {$SundayValue=$MondayValue=$TuesdayValue=$WednesdayValue=$ThursdayValue=$FridayValue=$SaturdayValue="111111111111111111111111"}
    }
    Switch ($PSBoundParameters.Keys)
    {
    'Sunday' {$SundayValue=$Working}
    'Monday' {$MondayValue=$Working}
    'Tuesday' {$TuesdayValue=$Working}
    'Wednesday' {$WednesdayValue=$Working}
    'Thursday' {$ThursdayValue=$Working}
    'Friday' {$FridayValue=$Working}
    'Saturday' {$SaturdayValue=$Working}
    }
    $AllTheWeek="{0}{1}{2}{3}{4}{5}{6}" -f $SundayValue,$MondayValue,$TuesdayValue,$WednesdayValue,$ThursdayValue,$FridayValue,$SaturdayValue
   # Timezone Check
    if ((Get-TimeZone).baseutcoffset.hours -lt 0){
    $TimeZoneOffset = $AllTheWeek.Substring(0,168+ ((Get-TimeZone).baseutcoffset.hours))
    $TimeZoneOffset1 = $AllTheWeek.SubString(168 + ((Get-TimeZone).baseutcoffset.hours))
    $FixedTimeZoneOffSet="$TimeZoneOffset1$TimeZoneOffset"
    }
    if ((Get-TimeZone).baseutcoffset.hours -gt 0){
    $TimeZoneOffset = $AllTheWeek.Substring(0,((Get-TimeZone).baseutcoffset.hours))
    $TimeZoneOffset1 = $AllTheWeek.SubString(((Get-TimeZone).baseutcoffset.hours))
    $FixedTimeZoneOffSet="$TimeZoneOffset1$TimeZoneOffset"
    }
    if ((Get-TimeZone).baseutcoffset.hours -eq 0){
    $FixedTimeZoneOffSet=$AllTheWeek
    }
    $i=0
    $BinaryResult=$FixedTimeZoneOffSet -split '(\d{8})' | Where {$_ -match '(\d{8})'}
    Foreach($singleByte in $BinaryResult){
    $Tempvar=$singleByte.tochararray()
    [array]::Reverse($Tempvar)
    $Tempvar= -join $Tempvar
    $Byte = [Convert]::ToByte($Tempvar, 2)
    $FullByte[$i]=$Byte
    $i++
    }
    Set-ADUser -Identity $Identity -Replace @{logonhours = $FullByte}                                   
    }
    end{
    Write-Output "All Done :)"
    }
    }
    $domainName = Read-Host -Prompt "Dominio del entorno (ej. reprobados)"
    $workGroup = Read-Host -Prompt "Organización del AC-DR"
    New-ADOrganizationalUnit -Name "$workGroup" -Path "DC=$domainName,DC=com"
    
    Write-Host "Crear los usuarios"
    $option = Read-Host "¿Quieres crear usuarios o mover usuarios a los grupos? (C/M)"
    if($option -eq "C"){
        $numUsers = Read-Host -Prompt "Número de usuarios a crear"
        for ($i = 1; $i -le $numUsers; $i++) {
            $userName = Read-Host -Prompt "Nombre de usuario $i"
            $userPassword = Read-Host -Prompt "Contraseña de usuario $i" -AsSecureString
            New-ADUser -Name $userName -AccountPassword $userPassword -Enabled $True -Path "OU=$workGroup,DC=$domainName,DC=com" -UserPrincipalName "$userName@$domainName.com"
            $logonHoursInput = Read-Host -Prompt "Horas a trabajar (ej. 1,2,3)"
            $logonHours = $logonHoursInput -split ',' | ForEach-Object { [int]$_ }
            Set-LogonHours -Identity "$userName" -TimeIn24Format $logonHours -Monday -Tuesday -Wednesday -Thursday -Friday
        }    
    }else{
        $user_move_count = Read-Host "¿Cuántos usuarios deseas mover?"
        for ($i = 1; $i -le $user_move_count; $i++) {
            $user_name = Read-Host "Nombre del usuario a mover:"
            $target_group = Read-Host "Nombre del grupo de destino (OU):"
            $user = Get-ADUser -Identity $user_name
            Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=$target_group,DC=$domain,DC=com"
            $logonHoursInput = Read-Host -Prompt "Horas a trabajar (ej. 1,2,3)"
            $logonHours = $logonHoursInput -split ',' | ForEach-Object { [int]$_ }
            Set-LogonHours -Identity "$userName" -TimeIn24Format $logonHours -Monday -Tuesday -Wednesday -Thursday -Friday
        }
    }
    ipconfig
    
    Write-Host ""
    $netAlias = Read-Host -Prompt "Alias de la interfaz de red"
    $netIP = Read-Host -Prompt "Dirección IP"
    Set-DnsClientServerAddress -InterfaceAlias $netAlias -ServerAddresses $netIP
    
    Add-Computer -DomainName "$domainName.com" -Restart -Force
    