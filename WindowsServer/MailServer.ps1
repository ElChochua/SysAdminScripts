Invoke-WebRequest -Uri "https://www.hmailserver.com/files/hMailServer-5.6.8-B2574.exe" -OutFile "hMailServer.exe"
Start-Process -Wait -FilePath "hMailServer.exe" -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
$domain = Read-Host "Ingrese el nombre de dominio: "
$server_ip = Read-Host "Ingrese la direccion IP del servidor: "
#creacion de la base de datos interna.
$hmail = New-Object -ComObject hMailServer.Application
$hmail.Database.ServerType = 2  # 2 = Base de datos interna
$hmail.Database.DatabaseFile = "C:\hMailServer\Data\hMailServer.sdf"
$hmail.Database.Connect()
$user_number = Read-Host "Ingrese el numero de usuarios que desea crear: "
for ($i=1; $i -le $user_number; $i++) {
    $domain = $hmail.Domains.ItemByName("localhost")
    $account = $domain.Accounts.Add()
    $account.Address = "user$i@localhost"
    $account.Password = "password"
    $account.Active = $True
    $account.Save()
}
$hmail.Settings.TCPIPPorts.ItemByName("SMTP").PortNumber = 25
$hmail.Settings.TCPIPPorts.ItemByName("POP3").PortNumber = 110
$hmail.Settings.TCPIPPorts.ItemByName("IMAP").PortNumber = 143
New-NetFirewallRule -DisplayName "SMTP (TCP 25)" -Direction Inbound -Protocol TCP -LocalPort 25 -Action Allow
New-NetFirewallRule -DisplayName "POP3 (TCP 110)" -Direction Inbound -Protocol TCP -LocalPort 110 -Action Allow
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "$server_ip $domain"

