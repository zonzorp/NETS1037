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
if [ "$mysqlrecordcount" ] && [ "$mysqlrecordcount" -gt 0 ]; then
  echo "mysql db has SystemEvents records"
  ((score+=3))
else
    echo "SystemEvents table is empty"
fi
if sudo ss -tulpn |grep -q 'udp.*0.0.0.0:514.*0.0.0.0:.*syslogd' ; then
  echo "rsyslog is listening to the network on 514/udp"
  ((score+=3))
else
  echo "rsyslog is not listening to 514/udp for syslog on the network"
fi
if sudo ufw status 2>&1 |grep '514/udp.*ALLOW'; then
	echo "ufw allows 514/udp"
  ((score+=2))
else
  echo "UFW is not allowing syslog traffic on 514/udp"
fi

hostsinsyslog="$(sudo awk '{print $2}' /var/log/syslog|sort|uniq -c)"
hostsindb="$(sudo mysql -u root <<< 'select distinct FromHost, count(*) from Syslog.SystemEvents group by FromHost;')"
for host in loghost mailhost webhost proxyhost nmshost; do
  if "$(sudo grep -aicwq $host /var/log/syslog)"; then 
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
echo "Score: $score"
