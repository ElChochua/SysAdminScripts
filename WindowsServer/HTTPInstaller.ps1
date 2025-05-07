Import-Module Z:\Functions.psm1 -Force
Clear-Host
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Clear-Host
Write-Host "INSTALADOR DE SERVICIOS HTTP"
$serverOption = Read-Host "¿Qué tipo de servidor deseas instalar? `n1) Tomcat `n2) Nginx `n3) IIS"
$server_Ip = Get-IP-Address
while ($true){
    if($serverOption -eq 1 -or $serverOption -eq 2 -or $serverOption -eq 3){
        break
    }else{
        $serverOption = Read-Host "Opcion no valida, porfavor ingresa una opcion valida"
    }
}
switch ($serverOption) {
    1{
        Write-Host "Apache2 `nQue version deseas instalar? `n1)Tomcat 9 `n2)Tomcat 10"
        $tomcatOption = Read-Host
        while ($true){
            if($tomcatOption -eq 1 -or $tomcatOption -eq 2){
                break
            }else{
                $tomcatOption = Read-Host "Opcion no valida, porfavor ingresa una opcion valida"
            }
            
        }
        switch ($tomcatOption) {
            1 {$tomcatVersion=9}
            2 {$tomcatVersion=10}
        }
        $tomcatVersions = Get-TomcatVersions -version $tomcatVersion
        if ($tomcatVersions.Count -lt 2 -and $tomcatVersions.Count -gt 0) {
            <# Action to perform if the condition is true #>
            $version_to_install = $tomcatVersions | Select-Object -First 1
            Write-Host "La version $tomcatVersion solo tiene la version $version_to_install"
            $installChoise = Read-Host "Quieres instalar esa version? [S/N]" 
            if ($installChoise -ne "S") {
                <# Action to perform if the condition is true #>
                Write-Host "Instalacion cancelada" -ForegroundColor Red
                break
            }
        }else{
            <# Action to perform if the condition is true #>
            Print-Array -array $tomcatVersions
            $versionChoise = Read-Host "Ingresa el numero de la version que deseas instalar"
            while($true){
                if($versionChoise -ge 0 -and $versionChoise -le $tomcatVersions.Count - 1 ){
                    break
                }
                $versionChoise = Read-Host "Opcion no valida, porfavor ingresa una opcion valida"
            }
            $version_to_install = $tomcatVersions[$versionChoise]
        }
        Install-Tomcat -version $tomcatVersion -version_number $version_to_install
        Start-Sleep -Seconds 3
        Start-Service -Name "Tomcat*"
        break

    }
    2{
        $versions = Get-NginxVersions
        $stable = $versions[0]
        $mainline = $versions[1]
        Write-Host "NgInx `nQue version deseas instalar? `n1)Stable $stable `n2)Mainline $mainline"
        $nginxOption = Read-Host
        while ($true){
            if($nginxOption -eq 1 -or $nginxOption -eq 2){
                break
            }else{
                $nginxOption = Read-Host "Opcion no valida, porfavor ingresa una opcion valida"
            }
        }
        switch ($nginxOption) {
            1 {$version_to_install=$stable}
            2 {$version_to_install=$mainline}
        }
        Install-Nginx -version $version_to_install
        break
    }
    3{
       Install-IIS
    }
    Default {
        Write-Host "Opcion no valida" -ForegroundColor Red
    }
}