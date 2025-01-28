Set up icinga2 on a fresh vm

Start by adding snmp client tools

Add the non-free repos to your /etc/apt/sources.list and run apt update

apt install snmp snmp-mibs-downloader

Download the mibs with download-mibs

Remove the mibs : line from your /etc/snmp/snmp.conf

Install some keys for apt, and add the repositories needed for this lab

Run the package installs (i.e. apt install icinga2 monitoring-plugins)

curl https://repos.influxdata.com/influxdb.key | apt-key add -

curl https://packagecloud.io/gpg.key | apt-key add -

curl http://debmon.org/debmon/repo.key | apt-key add -

echo "deb https://repos.influxdata.com/debian jessie stable" > /etc/apt/sources.list.d/influxdata-com.list

echo "deb https://packagecloud.io/grafana/stable/debian/ wheezy main" > /etc/apt/sources.list.d/grafana-org.list

echo "deb http://debmon.org/debmon debmon-jessie main" > /etc/apt/sources.list.d/debmon.list

apt install apt-transport-https

run apt update to add the new sources' package lists to your local db

icinga2 is now installed

It is running using the config defined in /etc/icinga2/icinga2.conf

It is monitoring localhost per /etc/icinga2/conf.d/hosts/localhost.conf

Data being gathered is stored in flat files

The configured features are defined in /etc/icinga2/features-enabled/*.conf

The features are enabled and disabled using icinga2 feature enable and icinga2 feature disable

constants.conf defines global variables such as the plugins directory and NodeName which you might want to change from localhost to your server name

Add logging to syslog, database storage of gathered data, manubulon snmp plugins

Enable the syslog feature to make icinga2 log events to syslog - restart icinga2 after enabling (e.g. systemctl restart icinga2)

apt install mysql-server icinga2-ido-mysql in order to have icinga2 store collected data in a database instead of flat files - agree to enable ido-mysql when asked, use dbconfig-common when asked, a random password for the webapp is fine

Use icinga2 feature enable ido-mysql to configure icinga2 to actually use the database and restart icinga2 (i.e. systemctl restart icinga2)

Add include <manubulon> to /etc/icinga2/icinga2.conf to allow use of the manubulon snmp plugins for remote monitoring
Install icingaweb2 interface

Install icingaweb2 using apt install icingaweb2 php5-gd php5-intl php5-imagick

Use icingacli setup token create to create a token for login to run the icingaweb2 setup pages

Add nagios as a group for www-data user so that apache can access the necessary nagios components (usermod -a -G nagios www-data)

Add icingaweb2 as a group for www-data user so that apache can access the necessary icingaweb2 components (usermod -a -G icingaweb2 www-data)

Add a default timezone in /etc/php5/apache2/php.ini and restart apache2

Run through the setup web pages at http://localhost/icingaweb2, clicking on the setup wizard link instead of logging in as a user

Make directories in /etc/icinga2/conf.d/hosts/ for each of your other hosts (webhost, loghost, router) and copy some monitoring scripts from the localhost directory into the other host's directories so they get monitored, edit as needed - use icinga2 daemon -C to syntax check those configs before restarting icinga2 to try to use them

Click to add the Doc module if you want the docs handy

Ignore errors about missing postgres modules, we are using mysql

Authentication type is database, type is MySQL

Name the user database something meaningful, like icingaweb2_userdb

The database username and password are the MySQL root user's login info

Make the info persistent and use the Validate Configuration button before clicking on Next

The default backend DB name is fine

Specify an admin user and password for yourself to use when administering the icinga2 services

The Application Configuration defaults are fine

Review your changes and click Next

Click Next on the monitoring modules splash page

The default Backend Name is fine

The database name and user login name and password can be found in /etc/icinga2/features-enabled/ido-mysql.conf

Make the info persistent and use the Validate Configuration button before clicking on Next

The defaults for Command Transport are fine for our use

The defaults for Monitoring Security are fine for our use

Before clicking on Finish, switch to a terminal window and provide permission for apache2 to create the files which the setup will try to create

chgrp icingaweb2 /etc/icingaweb2/modules

chmod g+w /etc/icingaweb2/modules

chmod g+rwx /var/run/icinga2/cmd

Return to the browser and click Finish to setup icingaweb2

Login to icingaweb2 using the admin user you created - icingaweb2 should show you current information about localhost

Install influxdb

apt install influxdb

configure influxdb to accept graphite data stream and do batching in influxdb.conf ([[graphite]] section)

configure icinga2 to send data to influxdb with icinga2-enable-feature graphite and restart icinga2

verify graphite db was created in influxdb and is getting data from icinga2 (http://icinga2host:8083)

Install grafana

apt install grafana

start the grafana server with service grafana-server start

add the graphite database in influxdb as a data source to grafana (http://icinga2host:3000)

click on the button labelled Home in the upper left, add a dashboard, add rows and graphs to that
