# Log Analysis
This lab assignment is designed to give you practical experience deploying log analysis tools. There are interactive tools, command line tools, graphical tools, and automated reporting tools. You will need to submit screenshots of the working tools to get the marks for this asignment.

## Update **loghost** to demonstrate local log analysis basics with email notifications of reports

1. install fortune and logwatch

```bash
sudo apt install fortune logwatch
```
1. Manually run logwatch to ensure it is working properly

```bash
sudo logwatch --range all | more
```
1. Verify it is set to run out of cron.daily

```bash
cat /etc/cron.daily/00logwatch
```
1. Install fwanalog and apache2

```bash
sudo apt install fwanalog apache2
```
1. modify **/etc/fwanalog/fwanalog.opts** to store the output in **/var/www/html/fwanalog** and look in **kern.log** instead of **messages\*** for log entries
```bash
sudo sed -i -e 's,outdir="/var/log/fwanalog",outdir="/var/www/html/fwanalog",' -e 's,inputfiles_mask="messages,inputfiles_mask="kern.log,' /etc/fwanalog/fwanalog.opts
```
1. allow port 80/tcp through ufw on your loghost

```bash
sudo ufw allow 80/tcp
```
1. run `sudo fwanalog` and try viewing `http://loghostIP/fwanalog/alldates.html` with your host laptop browser - it should be a report showing no data, just empty report sections
1. Run `nmap` against your **loghost** from your host laptop to generate some **UFW** firewall log entries
1. Re-run `fwanalog` on **loghost** and check the report web page again to see what shows up in the report
1. Run `sudo analog +O/var/www/html/analog.html` and try viewing the resulting report `http://loghostip/analog.html` with a browser

## Create a VM for a webhost to allow separating the analysis of logs from the capture of logs
1. Create a VM with network attached to the private vmware lan
1. Install Ubuntu 22.04 server (minimal hardware requirements, 1 cpu, minimum 1GB of RAM)
1. Configure your new VM to have hostname **webhost**, address **4** on the private network, dns and gateway set to your pfsense router (same procedure as it was for **loghost**)
1. Use your first name for the user account name
1. Run `sudo poweroff` when it finishes installing

1. When it finishes powering off, use a text editor on the vmx file for the VM and add the following line to the end of the file:
```bash
disk.EnableUUID = "TRUE"
```

1. Boot your VM, login to it, and verify that you can ping the router from your new VM using the router's name
1. Install **apache2**, **mysql**, and **php** on **webhost**
1. Allow ssh and web access through your firewall, prevent everything else.

```bash
sudo apt install apache2 mysql-server php
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw enable
```
1. Configure the apache2 access log to be logged to rsyslog using the Customlog directive without removing the existing entry for Customlog, and set the ServerName directive to webhost.home.arpa

In /etc/apache2/sites-available/000-default.conf:
```bash
ServerName webhost.home.arpa
CustomLog "|/usr/bin/logger -t apache2 -i -p daemon.notice" combined
```
1. Reload the apache2 daemon to recognize the config change

```bash
sudo apachectl graceful
```
1. Add **webhost** with its address to **Services->DNS Resolver** on **pfsense** so you can use the name **webhost** on your private network and verify it works by pinging **webhost** from **loghost**

```bash
ssh loghost -C ping webhost
```

## Modify **loghost** to allow for remote logging from a new webhost
1. On **loghost**, allow remote database access for **webhost** through your firewall

```
sudo ufw allow from 192.168.16.4 to 192.168.16.3 port 3306 proto tcp
```
1. On **loghost** modify the **db** and **user** tables in the mysql permissions database to allow **select** and **insert** for user **rsyslog** accessing from **localhost** and **select** and **insert** for **rsyslog** accessing from **webhost** - the plugin uninstall may fail and you can ignore that

```bash
sudo mysql -u root <<<"uninstall plugin validate_password;" 2>/dev/null
sudo mysql -u root <<EOF
create user 'rsyslog'@'webhost.home.arpa' identified by 'rsyslogpassword';
grant select,alter,insert on Syslog.* to 'rsyslog'@'webhost.home.arpa';
flush privileges;
EOF
```
1. On **loghost** modify **bind-address** in `/etc/mysql/mysql.conf.d/mysqld.cnf` to allow access from the network by changing the default of **127.0.0.1** to **0.0.0.0** and restart the mysql server to recognize the config change

```
bind-address        = 0.0.0.0
systemctl restart mysql
```

## Modify webhost to send logs to loghost
1. On **webhost** verify you can remotely access the Syslog database on **loghost**

```bash
mysql -u rsyslog --password=rsyslogpassword -h loghost <<<"select count(*) from Syslog.SystemEvents;"
```
1. On **webhost** install and configure **rsyslog-mysql**, *do not let dbconfig automatically connect to mysql!*

```bash
sudo apt install rsyslog-mysql
```
1. On **webhost** configure remote logging to loghost

In /etc/rsyslog.d/mysql.conf:
```
module (load="ommysql")
*.* action(type="ommysql" server="loghost" db="Syslog" uid="rsyslog" pwd="rsyslogpassword")
```
1. Restart rsyslog on **webhost** to recognize the config change and verify log records are now going to the database on loghost

```bash
sudo systemctl restart rsyslog.service
mysql -u rsyslog --password=rsyslogpassword -h loghost <<< "select DeviceReportedTime,FromHost,Message from Syslog.SystemEvents;"|grep webhost
```

## Set up web-based log analysis on webhost
1. install [LogAnalyzer](https://loganalyzer.adiscon.com) [v4.1.12 (stable)](http://download.adiscon.com/loganalyzer/loganalyzer-4.1.12.tar.gz) along with the necessary php packages and configure loganalyzer

```bash
sudo bash
cd
wget http://download.adiscon.com/loganalyzer/loganalyzer-4.1.13.tar.gz
tar zxf loganalyzer-4.1.13.tar.gz
cp -r loganalyzer-4.1.13/src /var/www/html/loganalyzer
touch /var/www/html/loganalyzer/config.php
chown -R www-data /var/www/html/loganalyzer
apt install php-gd php-mysql
systemctl restart apache2
mysql -h localhost -u root <<EOF
create database loganalyzer;
create user 'loganalyzer'@'localhost' identified by 'loganalyzer';
grant all on loganalyzer.* to 'loganalyzer'@'localhost';
flush privileges;
EOF
exit
```
1. Use a web browser on your host laptop to access `http://webhostip/loganalyzer/install.php`
   1. Click through the install wizard for loganalyzer, watching for any errors you may get
   1. Configure a mysql user database (specify user **loganalyzer**, password **loganalyzer** to create it)
   1. Check the box to require login
   1. Set data source parameters:
      1. source type **MYSQL Native**
      1. table type **MonitorWare**
      1. database host **loghost**
      1. database name **Syslog**
      1. database tablename **SystemEvents**
      1. database user **rsyslog**
      1. database password **rsyslogpassword**
   1. Create an application administrative user like **admin** with a password of your choosing
   1. Keep clicking through to the end of the wizard, watching for errors
1. Login to loganalyzer with the admin login you created in the wizard
1. If you are getting an error saying authentication method unknown to the client, it may be because you turned on the validate password plugin when doing the loghost setup lab before this one, you can fix that it in a terminal window using the following **mysql** command on loghost:
```bash
sudo mysql -u root <<< "alter user 'rsyslog'@'webhost.home.arpa' identified with mysql_native_password by 'rsyslogpassword';"
```
1. Explore the interface for loganalyzer

## Grading
This lab includes several activities that count for marks. In order to mark them, I need to see that you can check them and see the results of those checks. This set of instructions will walk yoou through taking screenshots that you can submit to Blackboard for this lab assignment. Part marks are available, so if you don't have it all done, submit what you do have done.

1. webhost should be running as a server on your private network - run the following commands on webhost to verify it is working properly at a basic level and screenshot the results including the command prompts
```bash
uname -a
hostname -I
whoami
nslookup ibm.com
ping -c 1 ibm.com
```
1. logwatch and fwlogwatch both generate emails - screenshot viewing a logwatch email using the command line `mail` command
1. analog and fwanalog generate reports composed of multiple files designed to be viewed in a web browser - screenshot the report from either one of them in a web browser
1. apache2 and mysql should be providing services on your webhost - run the following commands to demonstrate this and screenshot the results including the command prompts
```bash
sudo systemctl status apache2
sudo systemctl status mysql
sudo ufw status
```
1. webhost should be sending logs to loghost - run the following command and screenshot the results including the command prompt
```bash
mysql -u rsyslog --password=rsyslogpassword -h loghost <<<"select count(*) from Syslog.SystemEvents where FromHost = 'webhost' or FromHost = 'webhost.home.arpa';"
```
1. loganalyzer should be running properly, showing log entries - screenshot the loganalyzer tool running in your web browser showing the default page with log entries in a list

Submit the screenshots either in a single PDF file, or as separate screenshots. **Do not submit Microsoft Office documents or zip files**.

## ManageEngine Eventlog Analyzer
ManageEngine Eventlog Analyzer is designed to provide a GUI to assist with sifting junk from useful information in Windows Eventlogs. It can be run in a limited mode for free and is a different way of viewing Windows eventlogs. It also has the capability to listen for syslog messages from the network, but it is a questionable practice to be sending your network logs to Windows only, so if you deploy that you likely will have your logs going multiple places.

1. [Download the ManageEngine Eventlog Analyzer](https://www.manageengine.com/products/eventlog/download-free.html)
1. Install it on a Windows VM, a Windows computer, or other Windows environment.
1. Allow it access to the network when the Windows Defender popups start coming out during install.
1. The tools will eventually start up and you can browser it to see how it tries to bring things to your attention from the logs.

There is nothing to submit for ManageEngine Eventlog Analyzer. This is simply to demonstrate an alternate tool for viewing logs on Windows.
