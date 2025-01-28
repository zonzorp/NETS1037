#!/bin/bash
# webhost check script to use at end of log analysis lab

echo Host config checks
echo ===================
. /etc/os-release
echo $(hostname) running $PRETTYNAME has IP $(hostname -I)
set -x
nslookup ibm.com
ping -c 1 ibm.com |head -3
whoami
set +x
echo ===================

echo logwatch email check
echo ====================
set -x
logwatchmsgnum=$(mail -H|fgrep "logwatch"|tail -1|awk '{print $2}')
[ -n "$logwatchmsgnum" ] && mail <<< "p $logwatchmsgnum
x"
set +x
echo ====================

echo rsyslog/mysql checks
echo ===================
set -x
mysql -u rsyslog --password=rsyslogpassword -h loghost <<<"select count(*) from Syslog.SystemEvents where FromHost = 'webhost' or FromHost = 'webhost.home.arpa';"
sudo ufw status
set +x
echo ===================

echo apache/mysql/firewall checks
echo ===================
echo checking for ports opened by syslogd
sudo ss -tlpn
sudo ufw status
echo ===================

