#!/bin/bash

sudo sed -i '/^mail_location = mbox:\/mail:INBOX=\/var\/mail\/%u/d' /etc/dovecot/conf.d/10-mail.conf
sudo echo "mail_location = maildir:\/Maildir/' /etc/dovecot/conf.d/10-mail.conf" | sudo tee -a /etc/dovecot/conf.d/10-mail.conf
sudo echo "home_mailbox = Maildir/" | sudo tee -a /etc/postfix/main.cf
sudo echo "mailbox_command =" | sudo tee -a /etc/postfix/main.cf