Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install openssl
$env:path = $env:path + ";C:\Program Files\OpenSSL-Win64\bin"
#$env:Path = ($env:Path -split ";" | Where-Object { $_ -notmatch "OpenSSL" }) -join ";"
#$env:Path += ";C:\Program Files\OpenSSL-Win64\bin"