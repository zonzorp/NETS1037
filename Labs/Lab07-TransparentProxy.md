Setting up a Squid proxy server on Ubuntu 22.04 to provide HTTP and HTTPS proxy services involves several steps. Below is a detailed guide to achieve this:

## Step 1: Update and Upgrade System
First, ensure your system is up to date:

```bash
sudo apt update
sudo apt upgrade -y
```

## Step 2: Install Squid
Install Squid using the package manager:

```bash
sudo apt install squid -y
```

## Step 3: Configure Squid for Transparent Proxy
Edit the Squid configuration file:

```bash
sudo nano /etc/squid/squid.conf
```

Add or modify the following lines:

### Basic Configuration

```bash
# Define the port Squid will listen on
http_port 3128

# Allow traffic from your local network (adjust according to your network)
acl localnet src 192.168.16.0/24

# Only allow the defined local network to access the proxy
http_access allow localnet
http_access deny all
```

### Transparent Proxy Configuration
To set up Squid as a transparent proxy, add:

```bash
# Transparent mode
http_port 3129 intercept

# HTTPS/SSL Bump Configuration
http_port 3130 ssl-bump intercept cert=/etc/squid/ssl_cert/myCA.pem key=/etc/squid/ssl_cert/myCA.pem
acl step1 at_step SslBump1
ssl_bump peek step1
ssl_bump bump all

# Configure SSL Bump
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl CONNECT method CONNECT

# Allow Safe Ports
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

# SSL Bump configuration
sslproxy_cert_error allow all
sslproxy_flags DONT_VERIFY_PEER
```

## Step 4: Generate SSL Certificates
Squid needs a certificate to handle HTTPS traffic. Generate a CA certificate:

```bash
sudo mkdir /etc/squid/ssl_cert
cd /etc/squid/ssl_cert
sudo openssl genrsa -out myCA.key 2048
sudo openssl req -new -x509 -key myCA.key -out myCA.pem -days 3650
```

### Configure Permissions

```bash
sudo chown -R proxy:proxy /etc/squid/ssl_cert
sudo chmod -R 755 /etc/squid/ssl_cert
```

## Step 5: Configure IP Tables for Transparent Proxy
To route HTTP and HTTPS traffic to the Squid server, set up IP tables:

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo nano /etc/sysctl.conf
# Add or uncomment the following line
net.ipv4.ip_forward=1

# Save and exit, then reload sysctl
sudo sysctl -p

# Configure IP tables
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3129
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 3130

# Make the changes persistent
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

## Step 6: Restart Squid
After configuring Squid, restart the service to apply changes:

```bash
sudo systemctl restart squid
```

## Step 7: Verify Configuration
Check Squid’s status to ensure it is running correctly:

```bash
sudo systemctl status squid
```

## Step 8: Client Configuration
Finally, configure your client machines to use the Squid proxy server. This typically involves setting the proxy server's IP address and port (3128) in the client's network settings.

## Additional Steps (Optional)
### Logging and Monitoring
To monitor Squid activity, you can check the log files located in:

```bash
/var/log/squid/access.log
/var/log/squid/cache.log
```

### Advanced Configuration
For more advanced configurations like caching, authentication, and ACLs, you can further edit the `/etc/squid/squid.conf` file based on your needs.

With these steps, you should have a functioning transparent Squid proxy server on Ubuntu 22.04 that can handle both HTTP and HTTPS traffic.
