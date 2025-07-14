Import-Module Z:\Functions.psm1 -Force
Install-WindowsFeature Web-Server -IncludeManagementTools
Import-Module WebAdministration
#Get-WindowsFeature -Name "NET-Framework-Core"
#Install-WindowsFeature -Name "NET-Framework-Core" -Source "C:\Sources\SxS"
Install-PegasusMail
Install-Xampp
Install-SquirrelMail