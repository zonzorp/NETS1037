#!/bin/bash

username="$(id -un)"
mid="$(hostnamectl |grep -i machine)"

echo "
Report for $mid by $username
$(date)
================
"

score=0

if ping -c 1 pfsense >/dev/null; then
    echo "pfsense answers ping"
    ((score++))
    if ssh admin@pfsense true >/dev/null; then
	echo " and responds to ssh"
        ((score+=3))
    else
        echo " but does not respond to ssh"
    fi
    if ssh admin@pfsense -- ping -c 1 google.com >/dev/null; then
	echo " and can ping google"
        ((score+=2))
    else
        echo " but cannot ping google"
    fi
else
    echo "pfsense does not respond to ping"
fi

for host in loghost mailhost webhost proxyhost nmshost; do
    if ping -c 1 pfsense >/dev/null; then 
    echo "$host answers ping"
    ((score++))
    if ssh $host true >/dev/null; then
        echo " and responds to ssh"
        ((score+=3))
    else
        echo " but does not respond to ssh"
    fi
    if ssh $host -- ping -c 1 google.com >/dev/null; then 
        echo " and can ping google"
        ((score+=2))
    else 
        echo " but cannot ping google"
    fi
else
    echo "$host does not respond to ping"
fi
done

echo "Score: $score"
