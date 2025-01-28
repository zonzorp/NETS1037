# Loghost Lab
In this lab, we setup a loghost using Ubuntu server 20.04 which you can download from [ubuntu.com](https://ubuntu.com).

### Create a VM for a Windows desktop machine
1. Create a new VM in VMWare connected to the private vmware lan
1. Obtain and attach an installation iso for Windows 10 - see [microsoft.com](https://microsoft.com)
1. install the OS, default install is fine for our purposes, evaluation mode is fine, no need to purchase a license
1. Add an entry to the DNS Resolver overrides under Services->DNS Resolver on pfsense to create the name windows.home.arpa with the address of our Windows VM

### Create a VM for the loghost
1. create a new VM in VMWare connected to the private vmware lan
1. attach the iso for Ubuntu server 22.04
1. install the OS
  * use a static address of host 3 on the private vmware lan
  * use the private lan host 2 address for the gateway and dns
  * use the search domain home.arpa
  * no proxy
  * use the whole disk
  * create an account for yourself
  * name the host loghost
  * select to install ssh if it isn't already selected
  * login and do `sudo poweroff` when it finishes installing

1. When it finishes powering off, use a text editor (like textedit or notepad) on the vmx file for the VM and add the following line to the end of the file:
```bash
disk.EnableUUID = "TRUE"
```

1. Boot your VM, login to it, and verify that you can ping the router from your new VM using the router's name
6. Verify you can ping the loghost IP from a terminal, powershell or cmd window in your host laptop OS
7. Verify you can use ssh to connect to the loghost server from your host laptop OS
8. Run apt update and upgrade

### Set up some basic logging with mysql and file stores on loghost VM
1. install the **mailutils** software package and set it up for local delivery site with name loghost
1. install **mysql-server**
1. install **rsyslog-mysql**, choosing yes to configure database, leave the application password blank
```
sudo apt install mailutils
sudo apt install mysql-server
sudo apt install rsyslog-mysql
```
1. enable remote logging via tcp and udp in **/etc/rsyslog.conf** so that **loghost** can be a logging server for your private network

Uncomment the default lines:
```
module(load="imudp")
input(type="imudp" port="514")
module(load="imtcp")
input(type="imtcp" port="514")
```
1. Restart the rsyslog service to make your changes take effect
```
systemctl restart rsyslog.service
```
1. Verify your rsyslog service is listening for connections on port 514 for both udp and tcp
```
sudo ss -tulpn
```
1. Verify your mysql database is receiving and storing log messages by checking that the count of event records is greater than zero and growing - see [How to reset root MySQL password on Ubuntu 18.04](https://linuxconfig.org/how-to-reset-root-mysql-password-on-ubuntu-18-04-bionic-beaver-linux) if you cannot log into the database as root
```
sudo mysql <<< "select count(*) from Syslog.SystemEvents;"
```
1. firewall the loghost vm to only allow **ssh** (22/tcp) and **syslog** (514/tcp, 514/udp) access
```
apt install ufw
ufw allow 22/tcp
ufw allow 514
ufw enable
```
1. RELP can be install trivially using the package rsyslog-relp on Ubuntu. Review the [example of using RELP with file format template on serverfault](https://serverfault.com/questions/1106604/rsyslog-template-with-relp) to see a more sophisticated example of shipping logs with RELP.

### Modify router VM:
1. Add **loghost** to the router's dns resolver so the loghost hostname is known on the network
1. Configure the router to do remote logging to loghost under **Status->System Logs->Settings**

### On loghost VM:
1. Confirm router log messages are showing up in the text log files on loghost
```
sudo grep yourrouterhostname /var/log/syslog|head
```
1. Verify that the database of events is receiving events from your router as well as your loghost
```
sudo mysql <<< "select DeviceReportedTime,FromHost,Message from Syslog.SystemEvents;"|more
```

### Modify the Windows desktop VM to send logs to loghost using rsyslog
1. Download an agent program to send Windows eventlogs to a syslog server, such as the one from [rsyslog.com](https://www.rsyslog.com/windows-agent/windows-agent-download/) or [nxlog](https://nxlog.co)
1. Install the agent and configure it to send the logs to loghost, you can use the nxlog instructions found in the [Solarwinds Loggly instructions](https://www.loggly.com/ultimate-guide/centralizing-windows-logs/) to do the nxlog install if you wish.
1. Confirm windows log messages are showing up in the text log files **on loghost**
```
sudo grep windows /var/log/syslog|head
```

## Grading
This lab is marked. To submit it on Blackboard, download [this marking script](Lab02-loghost-checks.sh), run it on your loghost, and copy/paste the command line with your prompt plus all the output into the text submission box on Blackboard. That will show me what I need to see to mark your loghost creation and setup.
