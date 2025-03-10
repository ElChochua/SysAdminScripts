#Apache
$sslConfig = 'C:\Apache24\conf\extra\httpd-ssl.conf'
$sslContent = Get-Content -Path $sslConfig
$sslContent = $sslContent -replace 'Listen 443', "Listen $sport https"
$sslContent = $sslContent -replace '<VirtualHost _default_:443>', "<VirtualHost _default_:$sport>"
$sslContent = $sslContent.Replace('${SRVROOT}/conf/server.crt', "$apache_crt_path")
$sslContent = $sslContent.Replace('${SRVROOT}/conf/server.key', "$apache_key_path")
$sslContent | Set-Content -Path $sslConfig

#NGINX
                #HTTPS server
                #server {
                #    listen       $sport ssl;
                #    server_name  localhost;
                #    ssl_certificate      $certificate_path;
                #    ssl_certificate_key  $certificate_key_path;
                #    ssl_session_cache    shared:SSL:1m;
                #    ssl_session_timeout  5m;
                #    ssl_ciphers  HIGH:!aNULL:!MD5;
                #    ssl_prefer_server_ciphers  on;
                #    location / {
                #        root   html;
                #        index  index.html index.htm;
                #    }
                #}
                Set-Content -Path $confPath -Value $insert_config -Force
#WebServices 
$certificate = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $server_Ip -FriendlyName "Self-Signed-Certificate"
        Set-WebBinding -Name "Default Web Site" -PropertyName "Port" -Value "$port"
        New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port $sport -Protocol "https"
        $webSite = Get-WebBinding -Name "Default Web Site" -Protocol "https"
        $webSite.AddSslCertificate($certificate.GetCertHashString(), "My")