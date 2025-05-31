#!/bin/bash
# loghost check script for end of lab to create loghost

#!/bin/bash

username="$(id -un)"
mid="$(hostnamectl |grep -i machine)"

echo "
Report for $mid by $username
$(date)
================
"

score=0

mysqlrecordcount="$(sudo mysql -u root  <<< 'select count(*) from Syslog.SystemEvents;')"
if [ "$mysqlrecordcount" -gt 0 ]; then
  echo "mysql db has SystemEvents records"
  ((score+=3))
else
    echo "***Problem*** SystemEvents table is empty, your rsyslog isn't sending logs to the mysql database"
fi
if sudo ss -tulpn |grep -q 'udp.*0.0.0.0:514.*0.0.0.0:.*syslogd' ; then
  echo "rsyslog is listening to the network on 514/udp"
  ((score+=3))
else
  echo "rsyslog is not listening to 514/udp for syslog on the network"
fi
if sudo ufw status|grep ''; then
	echo "ufw allows 514/udp"
  ((score+=2))
else
  echo "UFW is not allowing syslog traffic on 514/udp"
fi

hostsinsyslog="$(sudo awk '{print $2}' /var/log/syslog|sort|uniq -c)"
hostsindb="$(sudo mysql -u root <<< 'select distinct FromHost, count(*) from Syslog.SystemEvents group by FromHost;')"
for host in loghost mailhost webhost proxyhost nmshost; do
  if echo "$(sudo grep -aicw $host /var/log/syslog)"; then 
    echo "$host found in /var/log/syslog"
    ((score++))
  else
    echo "$host not found in /var/log/syslog"
  fi
  if [ "$(sudo mysql -u root <<< 'select distinct count(*) from Syslog.SystemEvents where FromHost like $host%;')" -gt 0 ]; then
    echo "$host has records in the SystemEvents table"
    ((score+=3))
  else
        echo "$host not found in the SystemEvents table"
  fi
done

exit

echo "Score: $score"
echo Host config checks
echo ===================
echo $(hostname) has IP $(hostname -I)
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
for h in loghost webhost nmshost proxyhost mailhost pfsense; do echo "$h $(sudo grep -aicw $h /var/log/syslog)"; done
echo "distinct hostnames in SystemEvents table: "
sudo mysql -u root <<< "select distinct FromHost, count(*) from Syslog.SystemEvents group by FromHost;"
echo ===================
