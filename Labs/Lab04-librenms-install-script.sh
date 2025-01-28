#!/bin/bash

# this script runs the commands found at https://docs.librenms.org/#Installation/Installation-Ubuntu-1604-Apache/
# it has modifications specific to the NETS1037 course for W18 at Georgian College

sudo apt install apache2 composer fping git graphviz imagemagick libapache2-mod-php7.0 mariadb-client mariadb-server mtr-tiny nmap php7.0-cli php7.0-curl php7.0-gd php7.0-json php7.0-mcrypt php7.0-mysql php7.0-snmp php7.0-xml php7.0-zip python-memcache python-mysqldb rrdtool snmp snmpd whois curl
sudo useradd librenms -d /opt/librenms -M -r
sudo usermod -a -G librenms www-data

cd /opt
sudo composer create-project --no-dev --keep-vcs librenms/librenms librenms dev-master

sudo systemctl restart mysql
mysql -u root --password=root <<EOF
CREATE DATABASE librenms CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER 'librenms'@'localhost' IDENTIFIED BY 'librenmspassword';
GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';
FLUSH PRIVILEGES;
EOF

grep -q 'innodb_file_per_table=1' || sudo sed -e '/[mysqld]/a
innodb_file_per_table=1
sql-mode=""
lower_case_table_names=0
' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mysql

sudo sed -e '/^;date.timezone =/s/.*/date.timezone = America/Toronto/' /etc/php/7.0/apache2/php.ini
sudo sed -e '/^;date.timezone =/s/.*/date.timezone = America/Toronto/' /etc/php/7.0/cli/php.ini

sudo a2enmod php7.0
sudo a2dismod mpm_event
sudo a2enmod mpm_prefork
sudo phpenmod mcrypt
cat > /etc/apache2/sites-available/librenms.conf <<EOF
<VirtualHost *:80>
  DocumentRoot /opt/librenms/html/
  ServerName  nmshost

  AllowEncodedSlashes NoDecode
  <Directory "/opt/librenms/html/">
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
  </Directory>
</VirtualHost>
EOF

sudo a2dissite 000-default
sudo a2ensite librenms.conf
sudo a2enmod rewrite
sudo apachectl graceful

sudo sed -e 's/RANDOMSTRINGGOESHERE/public/' /opt/librenms/snmpd.conf.example |tee /etc/snmp/snmpd.conf
sudo curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
sudo chmod +x /usr/bin/distro
sudo systemctl restart snmpd

sudo cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms
sudo cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

sudo chown -R librenms:librenms /opt/librenms
sudo setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs
sudo setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs
sudo touch /opt/librenms/config.php
sudo chown librenms:www-data /opt/librenms/config.php

# now open a browser at go to http://nmshost/install.php

