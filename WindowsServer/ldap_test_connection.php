<?php

$ldap_host = "reprobados.com"; // O usa la IP directa o FQDN
$ldap_port = 389;              // Cambia a 636 para LDAPS si aplica
$ldaprdn   = 'CN=Administrator,CN=Users,DC=reprobados,DC=com';
$ldappass  = 'S2ltb1wk**';

// Conexión
$ldapconn = ldap_connect($ldap_host, $ldap_port);
if (!$ldapconn) {
    die("❌ No se pudo conectar al servidor LDAP.");
}

// Configuración de opciones LDAP
ldap_set_option($ldapconn, LDAP_OPT_PROTOCOL_VERSION, 3);
ldap_set_option($ldapconn, LDAP_OPT_REFERRALS, 0);
ldap_set_option($ldapconn, LDAP_OPT_NETWORK_TIMEOUT, 10);

// Autenticación
if (@ldap_bind($ldapconn, $ldaprdn, $ldappass)) {
    echo "✅ Conexión y autenticación LDAP exitosa.\n";
} else {
    echo "❌ Falló la autenticación LDAP.\n";
    echo "Error: " . ldap_error($ldapconn) . "\n";
}

ldap_unbind($ldapconn);
?>
