Setting up open source monitoring for a Squid proxy server can help you track its performance, usage, and health. One popular combination of tools for monitoring is Prometheus and Grafana. Below is a detailed guide on how to set up monitoring for Squid using these tools on Ubuntu 22.04.

### Step 1: Install Squid

First, ensure your Squid proxy server is installed and running:

```bash
sudo apt update
sudo apt install squid -y
sudo systemctl start squid
sudo systemctl enable squid
```

### Step 2: Install Prometheus

Prometheus is an open-source systems monitoring and alerting toolkit.

1. **Download Prometheus:**

```bash
cd /opt
sudo wget https://github.com/prometheus/prometheus/releases/download/v2.41.0/prometheus-2.41.0.linux-amd64.tar.gz
```

2. **Extract the downloaded archive:**

```bash
sudo tar -xvzf prometheus-2.41.0.linux-amd64.tar.gz
sudo mv prometheus-2.41.0.linux-amd64 prometheus
```

3. **Create a Prometheus user and set permissions:**

```bash
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo chown -R prometheus:prometheus /opt/prometheus
```

4. **Create Prometheus configuration file:**

```bash
sudo nano /etc/prometheus/prometheus.yml
```

Add the following configuration:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'squid'
    static_configs:
      - targets: ['localhost:9301']
```

5. **Create systemd service for Prometheus:**

```bash
sudo nano /etc/systemd/system/prometheus.service
```

Add the following configuration:

```ini
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/prometheus/prometheus --config.file /etc/prometheus/prometheus.yml --storage.tsdb.path /var/lib/prometheus/

[Install]
WantedBy=multi-user.target
```

6. **Start and enable Prometheus:**

```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

### Step 3: Install node_exporter

node_exporter is a Prometheus exporter for hardware and OS metrics.

1. **Download node_exporter:**

```bash
cd /opt
sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
```

2. **Extract the downloaded archive:**

```bash
sudo tar -xvzf node_exporter-1.6.1.linux-amd64.tar.gz
sudo mv node_exporter-1.6.1.linux-amd64 node_exporter
```

3. **Create systemd service for node_exporter:**

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

Add the following configuration:

```ini
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
```

4. **Start and enable node_exporter:**

```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

### Step 4: Install squid_exporter

`squid_exporter` is a Prometheus exporter specifically for Squid proxy metrics.

1. **Download squid_exporter:**

```bash
cd /opt
sudo wget https://github.com/boynux/squid-exporter/releases/download/v1.8.1/squid_exporter-1.8.1.linux-amd64.tar.gz
```

2. **Extract the downloaded archive:**

```bash
sudo tar -xvzf squid_exporter-1.8.1.linux-amd64.tar.gz
sudo mv squid_exporter-1.8.1.linux-amd64 squid_exporter
```

3. **Create systemd service for squid_exporter:**

```bash
sudo nano /etc/systemd/system/squid_exporter.service
```

Add the following configuration:

```ini
[Unit]
Description=Squid Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/opt/squid_exporter/squid_exporter --squid-hostname=localhost --squid-port=3128 --web.listen-address=":9301"

[Install]
WantedBy=multi-user.target
```

4. **Start and enable squid_exporter:**

```bash
sudo systemctl daemon-reload
sudo systemctl start squid_exporter
sudo systemctl enable squid_exporter
```

### Step 5: Install Grafana

Grafana is a powerful dashboard tool for visualizing Prometheus metrics.

1. **Add Grafana APT repository:**

```bash
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
```

2. **Install Grafana:**

```bash
sudo apt update
sudo apt install grafana -y
```

3. **Start and enable Grafana:**

```bash
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```

### Step 6: Configure Grafana

1. **Access Grafana Web UI:**

Open a web browser and navigate to `http://<your_server_ip>:3000`. The default login is `admin`/`admin`.

2. **Add Prometheus Data Source:**

- Go to **Configuration > Data Sources > Add data source**.
- Select **Prometheus**.
- Set the URL to `http://localhost:9090`.
- Click **Save & Test**.

3. **Import Dashboards:**

- Go to **Create > Import**.
- Import the following dashboards or create custom ones:
  - Node Exporter Full (ID: 1860)
  - Squid Exporter (ID: 11028) (or create a custom one for Squid metrics)

### Step 7: Verify Monitoring

Ensure that Prometheus, node_exporter, and squid_exporter are collecting metrics and Grafana is displaying them correctly. Check the logs if any service fails to start.

With these steps, you should have a fully functioning monitoring setup for your Squid proxy server using Prometheus and Grafana on Ubuntu 22.04.
