# SNMP Traps

## Configure your nmshost to both send and accept traps and then handle them
1. Ensure **snmpd** is installed, install **snmptrapd**, and update your mibs, including commenting out the mibs line in `/etc/snmp.conf`
1. Configure `/etc/snmp/snmpd.conf` to allow connections by modifying **agentAddress** if it doesn't already from the librenms lab.
1. Configure `/etc/snmp/snmpd.conf` to send the default set of traps to **nmshost**, creating **internalUser** for querying the data sources and specifying the default traps
1. Change the Ubuntu default package settings for snmpd service startup to not exclude mteTrigger stuff needed for traps in `/lib/systemd/system/snmpd.service` by removing those options from the startup command in the service definition file, and reload the systemd daemon

```bash
ssh nmshost
sudo apt update
sudo apt install snmpd snmptrapd snmp-mibs-downloader
sudo sed -i -e 's/(^mibs :.*)/#\\1/' /etc/snmp/snmp.conf
sudo grep -i internaluser /etc/snmp/snmpd.conf || cat <<< "

#internal use user for querying trap data
createUser internalUser SHA fubar2snafu AES
rouser        trapguy
iquerySecName trapguy

# Activate the standard monitoring entries
defaultMonitors         yes
linkUpDownNotifications yes

# send traps to nmshost using community public
trap2sink nmshost public

# add an example custom trap to watch for high cpu usage
monitor -r 5 machineTooBusy hrProcessorLoad > 75

"| sudo tee -a /etc/snmp/snmpd.conf
sudo sed -i 's/-I -smux,mteTrigger,mteTriggerConf //' /lib/systemd/system/snmpd.service
sudo systemctl daemon-reload
```

1. Install **postfix** and **mailutils** so we can test sending emails when traps are received. Install it as a Local Only site, with hostname for the mailserver being **nmshost.home.arpa**. This step is not needed if you already set up nmshost to do email.

```bash
sudo apt install postfix mailutils
```

1. For diagnostic purposes, start a terminal window or ssh session on nmshost and run tcpdump to watch the incoming trap packets. Leave this running to see the incoming traps throughout the remainder of this lab.

```bash
ssh nmshost sudo tcpdump -v port 162
```

1. Add the public authCommunity with log and execute in `/etc/snmp/snmptrapd.conf` so that traps get logged and set up a traphandler to send email to yourself (*make sure you change the email address in the example commands to be your email, not the professor's*)when you get a trap and restart the snmptrapd.
1. Modify the default Ubuntu package settings for service startup to send logs to syslog in `/lib/systemd/system/snmptrapd.service` and reload the systemd daemon
1. Enable **snmptrapd** and start it so that **nmshost** will receive and process traps
1. Allow traps through the **nmshost** firewall on port 162/udp

```bash
sudo sed -i '$aauthCommunity log,execute public\ntraphandle default /usr/bin/traptoemail -s localhost dennis@nmshost.home.arpa' /etc/snmp/snmptrapd.conf
sudo sed -i 's/-LOw/-Lsd/' /lib/systemd/system/snmptrapd.service
sudo systemctl daemon-reload
sudo systemctl start snmptrapd
sudo ufw allow 162/udp
```

1. Verify that your **nmshost** is listening for connections on udp port 162

```bash
sudo ss -ulpn
```

1. Test your **snmptrapd** by using the `snmptrap` command to send a trap message to **nmshost**

```bash
sudo snmptrap -v 1 -c public nmshost '' '' 3 0 ''
```

1. Check syslog and email to see if the trap arrived and was handled correctly, then restart snmpd so the daemon sends the configured traps automatically. *screenshot syslog entries and mail showing traps received*

```bash
sudo grep -i snmptrap /var/log/syslog |tail
mail
sudo systemctl restart snmpd
```

## Send traps from your monitored systems to nmshost
1. On **loghost** and **webhost**, configure snmpd to send traps like you did on nmshost.

```bash
sudo grep -i internaluser /etc/snmp/snmpd.conf || cat <<< "

#internal use user for querying trap data
createUser internalUser SHA fubar2snafu AES
rouser        trapguy
iquerySecName trapguy

# Activate the standard monitoring entries
defaultMonitors         yes
linkUpDownNotifications yes

# send traps to nmshost using community public
trap2sink nmshost public

# add an example custom trap to watch for high cpu usage
monitor -r 5 machineTooBusy hrProcessorLoad > 75

"| sudo tee -a /etc/snmp/snmpd.conf
sudo sed -i 's/-I -smux,mteTrigger,mteTriggerConf //' /lib/systemd/system/snmpd.service
sudo systemctl daemon-reload
sudo systemctl restart snmpd
```

1. Verify the traps for shutdown and coldstart arrive on **nmshost** by checking the logs on **nmshost**. *screenshot showing traps from both loghost and webhost*

```
sudo grep -i snmptrap /var/log/syslog |tail
```

1. Configure **pfsense** to send traps to **nmshost** on the `Services->SNMP` config page of the web interface, then check the end of `/var/log/syslog` on **nmshost** which should show a **cold start** trap from **pfsense**.
1. Use `snmptrap` to test sending traps from **loghost** and **webhost** and verify you see them in the **nmshost** syslog file. Instead of trap 3, try using different trap codes to see what kinds of traps they can send.

## Configure Librenms to show alerts
Librenms has an alerting capability that can use rules to match events that get recorded and then raise their visibility by putting them into an alert widget or by sending those alerts to a distribution mechanism. To demonstrate alerts, we will set up some simple ones to show in the standard alerts widget.

1. Verify that the librenms trap handler script is in your snmptrapd.conf file on **nmshost**
```bash
sudo grep -i librenms /etc/snmp/snmptrapd.conf || cat <<< "
traphandle default /opt/librenms/snmptrap.php
" | sudo tee -a /etc/snmp/snmptrapd.conf
```
1. Use the Alerts->Alert Rules page to add the default rules.
1. Add an Alerts widget to the dashboard.
1. Try viewing and acknowledging any alerts you may see (there may not be any) from the Librenms dashboard.
