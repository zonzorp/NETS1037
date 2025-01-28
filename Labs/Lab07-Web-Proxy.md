# Set Up Squid web proxy

On your webhost VM:

1. Install squid3 using apt
```bash
sudo apt update
sudo apt install squid3
```
1. Configure /etc/squid/squid.conf and restart your squid service
   * add your private network to the localnet acl
   * uncomment the `http_access allow localnet` line
   * if ping6 ipv6.google.com does not succeed, add `dns_v4_first on` to your squid.conf
```bash
sudo vi /etc/squid/squid.conf
sudo squid -k reconfigure
```
1. Firewall your squid host appropriately, allowing at least your proxy port (default is 3128) and ssh
```bash
sudo ufw allow 3128/tcp
```
1. Add a host entry for proxyhost to your DNS on the pfsense router (Services->DNS Resolver)
1. Verify your squid proxy is working with wget (review the transaction details in the wget output to see if the request went through the proxy)
```bash
export http_proxy=http://proxyhost:3128
wget -O - icanhazip.com
```
1. Check your squid access.log to see what entries were made there by the wget command you used to test squid
```bash
sudo tail /var/log/squid/access.log
```
1. On **loghost** modify the mysql permissions database to allow user **rsyslog** access from **proxyhost** so we don't break our loganalyzer
```bash
sudo mysql -u root <<EOF
create user 'rsyslog'@'proxyhost.home.arpa' identified by 'rsyslogpassword';
grant select,alter,insert on Syslog.* to 'rsyslog'@'proxyhost.home.arpa';
flush privileges;
EOF
```

## Set up a reverse proxy using your existing web server
1. Enable the proxy modules on your webhost to provide http and html rewriting as needed
```bash
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_http2
sudo a2enmod proxy_html
sudo a2enmod rewrite
sudo a2enmod headers
sudo systemctl restart apache2
sudo systemctl status apache2
```
1. Add the following configuration to the virtualhost in your 000-default.conf site file in order to:
   * disable forward proxying
   * pass the resource /z/ to http://zonzorp.net/
   * remove the Accept-Encoding header from the request because the proxied site does wonky things with the response encoding
   * correct the URL for HTTP responses
   * correct embedded links which may be in the returned html documents

```bash
In your /etc/apache2/sites-available/000-default.conf file, add the following lines before the line with </VirtualHost> :

ProxyRequests Off
ProxyPass /z/ http://zonzorp.net/
<Location /z/>
      ProxyPassReverse /
      ProxyHTMLEnable On
      ProxyHTMLURLMap http://zonzorp.net/ /z/
      ProxyHTMLURLMap / /z/
      RequestHeader unset Accept-Encoding
</Location>

```
1. Reload apache2 to get it to read in the changes
```bash
sudo apachectl graceful
```
1. Verify that going to http://webhost/z/ shows the website from zonzorp.net
1. Add a reverse proxy to webhost so that the librenms application running on nmshost is accessible via webhost using http://webhost.home.arpa/librenms/

## Grading
Screenshot the following commands run on webhost and their output:
```bash
ping -c 1 proxyhost
export http_proxy=http://proxyhost:3128
wget -O - icanhazip.com
```
Screenshot using a web browser to open `http://webhost/z/` and `http://webhost/librenms/`
Submit your screenshots as a single PDF file, or as separate jpg or png image files. DO NOT SUBMIT A ZIP.
