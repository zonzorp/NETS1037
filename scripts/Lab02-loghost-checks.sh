#!/bin/bash

username="$(id -un)"
mid="$(hostnamectl |grep -i machine)"

if ! mysql -V 2>/dev/null; then
    echo "MySQL not installed, not checking lab"
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  echo "do not run this script as root"
  exit 1
else
  sudo echo "
Report for $mid by $username
$(date)
================
" || exit 1
fi

writingscore=0
listeningscore=0
receivingscore=0

mysqlrecordcount=$(sudo mysql -u root  <<< 'select count(*) from Syslog.SystemEvents;'|tail -1)
if [ "$mysqlrecordcount" ] && [ "$mysqlrecordcount" -gt 0 ]; then
  echo "mysql db has SystemEvents records"
  ((writingscore+=15))
else
    echo "SystemEvents table is empty"
fi
if sudo ss -tulpn |grep -q 'udp.*0.0.0.0:514.*0.0.0.0:.*syslogd' ; then
  echo "rsyslog is listening to the network on 514/udp"
  ((listeningscore+=15))
else
  echo "rsyslog is not listening to 514/udp for syslog on the network"
fi
if sudo ufw status 2>&1 |grep '514/udp.*ALLOW'; then
	echo "ufw allows 514/udp"
  ((listeningscore+=15))
else
  echo "UFW is not allowing syslog traffic on 514/udp"
fi

hostsinsyslog="$(sudo awk '{print $2}' /var/log/syslog|sort|uniq -c)"
hostsindb="$(sudo mysql -u root <<< 'select distinct FromHost, count(*) from Syslog.SystemEvents group by FromHost;')"
for host in loghost mailhost webhost proxyhost nmshost; do
  if grep -aicwq $host <<< "$hostsinsyslog"; then
    echo "$host found in /var/log/syslog"
    ((receivingscore+=4))
    [ $receivingscore -eq 4 ] && ((writingscore+=15))
  else
    echo "$host not found in /var/log/syslog"
  fi
#  if [ $(sudo mysql -u root <<< 'select count(*) from Syslog.SystemEvents where FromHost like ${host}%;'|tail -1) -gt 0 ]; then
  if echo "$hostsindb" |grep -qw $host ; then
    echo "$host has records in the SystemEvents table"
    ((receivingscore+=4))
  else
        echo "$host not found in the SystemEvents table"
  fi
done
echo "Scores: writing: $writingscore, listening: $listeningscore, receiving: $receivingscore"
