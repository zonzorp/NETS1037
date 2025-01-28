#!/bin/bash

ping -c 1 webhost
ping -c 1 webhost.home.arpa
ping -c 1 nmshost
ping -c 1 nmshost.home.arpa
ping -c 1 pfsense
ping -c 1 pfsense.home.arpa

sudo mysql -u root  <<< "select count(*) from Syslog.SystemEvents;"
sudo mysql -u root <<< "select distinct FromHost from Syslog.SystemEvents;"

logwatch --range today

export http_proxy=http://proxyhost:3128
wget -O - icanhazip.com
wget -O - webhost/z/

export http_proxy=http://proxyhost:8080
wget -O - icanhazip.com
wget -O - http://www.eicar.org/download/eicar.com.txt | grep content

radtest testuser radiuspassword localhost 1 testing123
radtest testuser badpassword localhost 1 testing123
radtest testuser radiuspassword localhost 1 badsecret
