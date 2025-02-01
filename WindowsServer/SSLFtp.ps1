$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
New-SelfSignedCertificate -CertStoreLocation   Cert:\LocalMachine\My -DnsName $ipAddress -FriendlyName "FTP" -NotAfter (Get-Date).AddYears(5) 
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslRequire" 
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslRequire" 
$thumbprint = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=$ipAddress"} | Select-Object -ExpandProperty Thumbprint
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.serverCertStoreName -Value "My" 
Set-ItemProperty "IIS:\Sites\FTP" -Name ftpServer.security.ssl.serverCertHash -Value "$thumbprint"
Set-NetFirewallProfile Domain,Public,Private -Enabled False
Restart-WebItem "IIS:\Sites\FTP"