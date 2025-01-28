# Network Traffic Monitoring with ntopng

## NtopNG - community version on pfsense
ntopng can be installed as a package on a pfsense router. This allows you to view ntopng analytics on the router.

1. System->Packages->Available, install ntopng - will appear under Diagnostics
1. Visit the ntopng settings page first, then you can use the ntopng link to view traffic
1. When you have the traffic view showing, in another window try doing an apt update and upgrade to generate some traffic. *Screenshot the ntopng web page on pfsense showing traffic flows*

## NtopNG - current commercial version *will start and run in trial mode for several hours, then stop working*
Install ntopng on your nmshost. The instructions may have changed since this was written. If the instructions below are not working for you, visit the [ntopng ubuntu packages website](https://packages.ntop.org/apt-stable/) and follow the instructions for installing ntopng current version.

1. Add the ntopng package repository to your apt source list, and the ntop key to your trusted keys
1. Update your apt repo cache
1. Install the ntopng commercial package
1. Open the tcp port for accessing the ntopng web interface in your firewall

```
ssh nmshost
sudo bash
apt-get install software-properties-common wget
add-apt-repository universe
wget https://packages.ntop.org/apt/20.04/all/apt-ntop.deb
apt install ./apt-ntop.deb
apt update
apt install ntopng
ufw allow 3000/tcp
```
1. In a web browser go to http://nmshost:3000
1. Create some network traffic any way you like, such as by using the firefox browser on nmshost to view google image or something like that. *Screenshot the ntopng web page on nmshost showing traffic flows*
