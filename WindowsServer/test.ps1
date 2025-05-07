Import-Module Z:\Functions.psm1 -Force
$password = "s2ltb1wkl*" | ConvertTo-SecureString -AsPlainText -Force
$unsecure = Convert-SecureString-To-PlainText $password
Write-Host "Contraseña en texto plano: $unsecure"
Validate-Password  $unsecure