Import-Module Z:\Functions.psm1 -Force
$port = Read-Host "Ingresa el puerto del servidor Tomcat"
while ($true) {
    if (-not (Test-PortValid -port $port)) {
        break
    }
    $port = Read-Host "Puerto no valido, porfavor ingresa un puerto valido"
}