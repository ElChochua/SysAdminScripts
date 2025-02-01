#!/bin/bash
sudo openssl req -x509 -nodes -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/private/vsftpd.pem -days 365 -newkey rsa:2048

sudo " " >> /etc/vsftpd.conf
sudo echo rsa_cert_file=/etc/ssl/private/vsftpd.pem >> /etc/vsftpd.conf
sudo echo rsa_private_key_file=/etc/ssl/private/vsftpd.pem >> /etc/vsftpd.conf
sudo echo ssl_enable=YES >> /etc/vsftpd.conf
sudo " " >> /etc/vsftpd.conf
sudo echo allow_anon_ssl=YES >> /etc/vsftpd.conf
sudo echo force_local_data_ssl=YES >> /etc/vsftpd.conf
sudo echo force_local_logins_ssl=YES >> /etc/vsftpd.conf
sudo echo ssl_tlsv1=YES >> /etc/vsftpd.conf
sudo echo ssl_sslv2=NO >> /etc/vsftpd.conf
sudo echo ssl_sslv3=NO >> /etc/vsftpd.conf
sudo echo require_ssl_reuse=NO >> /etc/vsftpd.conf
sudo echo ssl_ciphers=HIGH >> /etc/vsftpd.conf

sudo systemctl restart vsftpd
sudo systemctl status vsftpd