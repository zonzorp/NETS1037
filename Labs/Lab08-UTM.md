# Web Filtering Lab
This lab will give you hands-on practive installing and setting up canned UTM functionality on your proxyhost. Note that we are installing the repo versions of software to keep the lab simple. If you are feeling ambitious, visit the github site for the software and install a current version following the instructions that are on the github site for the software. For the purposes of our lab, the repo versions are fine.

## Set up simple content and virus management
1. On your proxyhost already running squid, download and install e2guardian and clamav-daemon
```bash
sudo apt update
sudo apt-get install e2guardian clamav-daemon
```
1. Edit `/etc/e2guardian/e2guardian.conf`:
   * Uncomment the clamdscan contentscanner
   * Set the daemongroup to clamav
   * check that the `maxcontentramcachescansize` is set to at least the same as the `maxcontentfiltersize` but not bigger then `maxcontentfilecachescansize`
1. Edit `/etc/e2guardian/contentscanners/clamdscan.conf`:
  * Ensure **clamdudsfile** in`clamdscan.conf` is set the same as the filename specified in `/etc/clamav/clamd.conf` for the **LocalSocket** - they should be by default because /run and /var/un are the same thing in ubuntu
1. Restart the e2guardian service, and start the clamav-daemon which may not be running
1. Open the e2guardian proxy port 8080 in your firewall
```bash
sudo vi /etc/e2guardian/e2guardian.conf
sudo systemctl restart e2guardian
sudo systemctl start clamav-daemon
sudo ufw allow 8080/tcp
```
1. Set the http_proxy variable to your proxyhost port 8080 so that e2guardian+clamav can intercept and inspect your web requests
1. Run apt-get update to verify you can retrieve valid web sites using the e2guardian+clamav proxy
1. Try using wget to retrieve the 4 different eicar virus test files to verify you are blocking them properly
```bash
export http_proxy=http://proxyhost:8080
sudo apt update
wget -O - http://www.eicar.org/download/eicar.com
wget -O - http://www.eicar.org/download/eicar.com.txt
wget -O - http://www.eicar.org/download/eicar_com.zip
wget -O - http://www.eicar.org/download/eicarcom2.zip
```
1. Try a web browser configured to use your e2guardian proxy on proxyhost port 8080 to retrieve the eicar test virus file

## Email Filtering Lab
If you want to try setting up email filtering for virii and spam, you can do it using instructions like those found at:

https://www.linuxbabe.com/mail-server/postfix-amavis-spamassassin-clamav-ubuntu

There are no marks for setting up email filtering, but you can use this as a starting point if you want to try working with email filtering.

## Grading
There are two things which are assessed to assign marks for this lab. The first is that your e2guardian is running and passing valid traffic. The second is that the e2guardian is blocking bad traffic. Run the following commands on nmshost and screenshot the results to show both of these.
```bash
export http_proxy=http://proxyhost.home.arpa:8080
wget -O - icanhazip.com
wget -O - http://www.eicar.org/download/eicar.com.txt
```
