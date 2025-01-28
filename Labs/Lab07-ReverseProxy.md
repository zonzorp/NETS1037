Setting up Squid as a reverse proxy on Ubuntu 22.04 involves a different configuration compared to a forward or transparent proxy. A reverse proxy forwards client requests to backend servers and serves the responses back to the clients. Below is a detailed guide to configure Squid as a reverse proxy.

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

## Step 3: Configure Squid for Reverse Proxy
Edit the Squid configuration file:

```bash
sudo nano /etc/squid/squid.conf
```

Add or modify the following lines:

### Basic Configuration

```bash
# Define the port Squid will listen on
http_port 80 accel vhost vport

# Define the backend servers
cache_peer your_backend_server.com parent 80 0 no-query originserver name=myAccel

# Define access control list (ACL)
acl our_sites dstdomain your_proxy_domain.com

# Allow access to the defined sites
http_access allow our_sites
http_access deny all

# Set up cache rules
cache_peer_access myAccel allow our_sites
cache_peer_access myAccel deny all

# Add forwarding rules
never_direct allow our_sites
```

Replace `your_backend_server.com` with the address of your backend server and `your_proxy_domain.com` with the domain that will point to your Squid proxy.

### Optional: Configure HTTPS Reverse Proxy
To set up Squid as a reverse proxy for HTTPS, add:

```bash
# Define the port Squid will listen on for HTTPS
https_port 443 cert=/etc/squid/ssl_cert/myCA.pem key=/etc/squid/ssl_cert/myCA.pem accel vhost vport

# Define the backend servers for HTTPS
cache_peer your_backend_server.com parent 443 0 no-query originserver ssl sslflags=DONT_VERIFY_PEER name=myAccelSSL

# Configure SSL Bump for reverse proxy
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl CONNECT method CONNECT

# Allow Safe Ports
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

# SSL Bump configuration
ssl_bump server-first all
sslproxy_cert_error allow all
sslproxy_flags DONT_VERIFY_PEER
```

Generate SSL certificates if you haven't done so:

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

## Step 4: Restart Squid
After configuring Squid, restart the service to apply changes:

```bash
sudo systemctl restart squid
```

## Step 5: Verify Configuration
Check Squid’s status to ensure it is running correctly:

```bash
sudo systemctl status squid
```

## Step 6: DNS Configuration
Make sure that your domain (`your_proxy_domain.com`) points to the IP address of your Squid server. This typically involves setting up an A record in your DNS settings.

## Step 7: Backend Server Configuration
Ensure your backend server is properly configured to handle requests forwarded by Squid. This usually involves configuring your web server (e.g., Apache, Nginx) to serve content for the domain that Squid is handling.

## Step 8: Testing
Test your reverse proxy setup by accessing your domain (`your_proxy_domain.com`). Squid should forward the requests to the backend server and serve the responses back to the clients.

## Additional Steps (Optional)
### Logging and Monitoring
To monitor Squid activity, you can check the log files located in:

```bash
/var/log/squid/access.log
/var/log/squid/cache.log
```

### Advanced Configuration
For more advanced configurations like caching, load balancing, and authentication, you can further edit the `/etc/squid/squid.conf` file based on your needs.

With these steps, you should have a functioning Squid reverse proxy server on Ubuntu 22.04 that can handle both HTTP and HTTPS traffic.
