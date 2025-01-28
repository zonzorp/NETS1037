# Lab 03 - SNMP and Monitoring
The purpose of this lab is to create an SNMP monitoring station and use it to monitor the loghost, webhost, and pfsense router already installed on our virtual networks. 

## Create a VM on your private network to be your monitoring host
1. Install a desktop Linux OS, just use **Ubuntu** unless you want to figure out how to make another OS do the same job
1. Assign the host number **5** to the new vm as a static address and name it **nmshost** during the install, with the pfsense router as gateway and dns server, dns search domain is **home.arpa**
1. Create the user account using your first name as the username
1. Run `sudo poweroff` when it finishes installing
1. When it finishes powering off, use a text editor on the vmx file for the VM and add the following line to the end of the file:
```bash
disk.EnableUUID = "TRUE"
```

1. Boot your VM and login to it
1. In a terminal window, verify that you can ping your pfsense router from your new VM using the router's hostname
1. If you did not set the dns search domain during the install, you can set it in a terminal window using the **nmcli** command:
```bash
sudo nmcli c m "Wired connection 1" ipv4.dns-search home.arpa
sudo nmcli c d "Wired connection 1"
sudo nmcli c u "Wired connection 1"
```

 1. Add the name **nmshost** to your pfsense Services->DNS Resolver with the domain home.arpa and the address set to **.5** on the private network
 1. Verify you can `ping nmshost` from loghost
   
## Set up pfsense to allow snmp monitoring
1. Install the snmp software on the **nmshost** VM
   * in a terminal window on **nmshost**, install the snmp client-side tools
 ```bash
 sudo apt update
 sudo apt install snmp
 ```

1. Enable **SNMP** on pfsense for the **LAN** interface, community string **public**
1. Verify you can access the snmp tree from **nmshost** using version 1 community **public**
   * in a terminal window on **nmshost**, try viewing the snmp data tree from pfsense
```bash
snmpstatus -v 1 -c public pfsense
snmpwalk -v 1 -c public pfsense | more
snmpwalk -v 1 -c public pfsense | wc -l
```
   
## Set up loghost to allow snmp monitoring
1. Install the snmpd daemon software on **loghost**
1. Allow snmp access through your ufw firewall
1. Modify `/etc/snmp/snmpd.conf` to allow access by changing the **agentAddress** to look this way: `agentAddress udp:161,udp6:[::1]:161`
```bash
ssh loghost
sudo apt install snmpd
sudo ufw allow 161/udp
sudo vi /etc/snmp/snmpd.conf
sudo systemctl restart snmpd
```
1. Verify you can access the snmp tree from **nmshost** using version 1 community **public**
   * in a terminal window on **nmshost**, test using snmp to access **loghost**
```bash
snmpstatus -v 1 -c public loghost
snmpwalk -v 1 -c public loghost | wc -l
```
1. Enable full snmp tree access for community **public** by changing the **rocommunity** setting in `/etc/snmp/snmpd.conf` to look this way: **rocommunity public 172.16.168.0/24** (use your lan network number)
```bash
sudo vi /etc/snmp/snmpd.conf
sudo systemctl restart snmpd
```

1. Run **snmpstatus** again to verify you can now retrieve more oids than you could before
   * in a terminal window on **nmshost**, test using snmp to access **loghost**
```bash
snmpstatus -v 1 -c public loghost
snmpwalk -v 1 -c public loghost | wc -l
```

## Set up webhost for snmp monitoring
1. Install the snmpd daemon software on **webhost**
1. Allow snmp access through your ufw firewall
1. Modify `/etc/snmp/snmpd.conf` to allow access and enable full snmp tree access like you did on **loghost**
```bash
ssh webhost
sudo apt install snmpd
sudo ufw allow 161/udp
sudo vi /etc/snmp/snmpd.conf
sudo systemctl restart snmpd
```
1. Verify you can access the snmp tree from **nmshost** using **v1** community **public**
   * in a terminal window on **nmshost**, test using snmp to access **webhost**
```bash
snmpstatus -v 1 -c public webhost
snmpwalk -v 1 -c public webhost | wc -l
```
   
## Add MIBs to **nmshost** so that we have descriptive OIDs
1. Install the mib downloader on **nmshost** (you may need to add the non-free repo to your `/etc/apt/sources.list`)
```bash
apt install snmp-mibs-downloader
```
1. Configure **nmshost** to use the mibs when running snmp commands
```bash
sudo sed -i -e 's/(^mibs)/#\\1/' /etc/snmp/snmp.conf
```
1. Retest using **snmpwalk** to verify you now see and can use descriptive oids on **nmshost**
   * in a terminal window on **nmshost**
```bash
snmpwalk -v 1 -c public pfsense | more
```

## Add an SNMPv3 user to secure SNMP access and transport
You can use [SNMPv3 Options](http://www.net-snmp.org/wiki/index.php/TUT:SNMPv3_Options) or [Configuring SNMPv3 section of O'Reilly book](https://nnc3.com/mags/Networking2/snmp/appf_02.htm) as a reference guide to adding users for snmpv3 connections.

1. Add an snmpv3 user to **/etc/snmp/snmpd.conf** on the **loghost** and **webhost** machines which has authentication (using SHA) and encryption (using AES) enabled
```bash
echo "createUser authPrivUser SHA password123 AES password456" >>/etc/snmp/snmpd.conf
sudo systemctl restart snmpd
grep usmUser /var/lib/snmp/snmpd.conf
```
1. Test that you can use authentication and encryption with snmp command line tools from **nmshost** to **loghost** (this example has username *authPrivUser* with password *password123* for SHA login and secret *password456* for AES encryption) *Screenshot this command and its results including your command prompt*
```bash
snmpstatus -u authPrivUser -a SHA -A password123 -x AES -X password456 -v 3 -l authPriv loghost
```
1. Test that you can use authentication and encryption with snmp command line tools from **nmshost** to **webhost** (this example has username *authPrivUser* with password *password123* for SHA login and secret *password456* for AES encryption) *Screenshot this command and its results including your command prompt*
```bash
snmpstatus -u authPrivUser -a SHA -A password123 -x AES -X password456 -v 3 -l authPriv webhost
```

## Turn on the firewall on **nmshost**
1. Use ufw on **nmshost** to only allow ssh connections.
```bash
ufw allow 22/tcp
ufw enable
```

### Modify the Windows desktop VM to allow snmp monitoring from nmshost
1. Download an agent program or configure Windows (depends on your version) to provide SNMP service from Windows
1. Install the agent and/or configure the Windows VM to allow SNMP access from nmshost
1. Test retrieving SNMP data from the Windows VM from nmshost
```bash
snmpstatus -v 1 -c public windows-vm-name
```

# Basic Monitoring with LibreNMS
**LibreNMS** is a pre-configured fork of [Observium](https://www.observium.org) for common system and network monitoring tasks. It is a webapp, which can be installed on apache2 or nginx running on Linux. We will use it to demonstrate gathering data with SNMP for graphical presentation on a network monitoring station. We will use **librenms** because it is pre-configured.

## Install librenms on nmshost
1. On your **nmshost**, install **librenms** following the instructions at [librenms install docs](https://docs.librenms.org)
1. Add your **pfsense** router, your **loghost**, your **webhost**, your Windows VM, and your **nmshost** to the **librenms** device list
1. When the devices overview page has updated to show data from the monitored hosts (may take 5 or 10 minutes depnding on how slow your host PC/mac is), *screenshot the devices list showing all your machines added and their data*
