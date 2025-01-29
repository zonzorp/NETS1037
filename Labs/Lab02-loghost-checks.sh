#!/bin/bash
# loghost check script for end of lab to create loghost

echo Host config checks
echo ===================
echo $(hostname) has IP $(hostname -I)
echo whoami
whoami
echo ===================

echo rsyslog/mysql checks
echo ===================
echo -n "record count in SystemEvents table: "
sudo mysql -u root  <<< "select count(*) from Syslog.SystemEvents;"
echo ===================

echo rsyslog/firewall checks
echo ===================
echo checking for ports opened by syslogd
sudo ss -tulpn|grep syslogd
sudo ufw status
echo ===================

echo logs being captured on loghost
echo ===================
echo -n "host appearances in /var/log/syslog: "
for h in webhost nmshost proxyhost mailhost dbhost pfsense; do echo -n "$h $(sudo grep -aicw $h /var/log/syslog)"; done
echo "distinct hostnames in SystemEvents table: "
sudo mysql -u root <<< "select distinct FromHost, count(*) from Syslog.SystemEvents;"
echo ===================
