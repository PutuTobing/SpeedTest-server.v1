# 🚀 Deployment Guide

Panduan deploy SpeedTest Service ke multiple nodes/servers.

## 📋 Pre-requisites

Sebelum deploy, pastikan:

1. **SSH Access** ke target server dengan key-based authentication
2. **Go installed** di build machine (untuk compile binary)
3. **Root/sudo access** di target server
4. **Port 8080** available di target server
5. **DNS/subdomain** sudah di-pointing ke IP server (optional)

---

## 🎯 Deployment Scenarios

### Scenario 1: Single Node Deployment

Deploy ke satu server untuk testing atau production single node.

**Target:**
- Server: 103.254.100.1
- Domain: speedtest1.btd.co.id
- Port: 8080

**Steps:**

```bash
# 1. Setup SSH key (jika belum)
ssh-copy-id root@103.254.100.1

# 2. Build & Deploy
cd /path/to/SpeedTest
./deploy.sh 103.254.100.1 root

# 3. Configure node name (on remote server)
ssh root@103.254.100.1
nano /etc/speedtest/speedtest.env

# Edit:
NODE_NAME=Jakarta-Node-1

# Restart service
systemctl restart speedtest

# 4. Test
curl http://speedtest1.btd.co.id:8080/
curl http://speedtest1.btd.co.id:8080/health
```

---

### Scenario 2: Multi-Node Deployment

Deploy ke beberapa server untuk load balancing atau geo-distributed testing.

**Target:**
- Node 1: speedtest1.btd.co.id (Jakarta) - 103.254.100.1
- Node 2: speedtest2.btd.co.id (Lampung) - 103.254.100.2
- Node 3: speedtest3.btd.co.id (Bandung) - 103.254.100.3

**Method A: Using deploy script**

```bash
# Deploy to Node 1
./deploy.sh 103.254.100.1 root

# Configure Node 1
ssh root@103.254.100.1 "echo 'NODE_NAME=Jakarta-Node' >> /etc/speedtest/speedtest.env"
ssh root@103.254.100.1 "systemctl restart speedtest"

# Deploy to Node 2
./deploy.sh 103.254.100.2 root
ssh root@103.254.100.2 "echo 'NODE_NAME=Lampung-Node' >> /etc/speedtest/speedtest.env"
ssh root@103.254.100.2 "systemctl restart speedtest"

# Deploy to Node 3
./deploy.sh 103.254.100.3 root
ssh root@103.254.100.3 "echo 'NODE_NAME=Bandung-Node' >> /etc/speedtest/speedtest.env"
ssh root@103.254.100.3 "systemctl restart speedtest"
```

**Method B: Automated batch deployment**

Create `nodes.txt`:
```
103.254.100.1,Jakarta-Node
103.254.100.2,Lampung-Node
103.254.100.3,Bandung-Node
```

Deploy script:
```bash
#!/bin/bash
while IFS=',' read -r ip name; do
    echo "Deploying to ${ip} (${name})..."
    ./deploy.sh ${ip} root
    ssh root@${ip} "sed -i 's/NODE_NAME=.*/NODE_NAME=${name}/' /etc/speedtest/speedtest.env"
    ssh root@${ip} "systemctl restart speedtest"
    sleep 2
    echo "Testing ${ip}..."
    curl -s http://${ip}:8080/health
    echo ""
done < nodes.txt
```

---

### Scenario 3: Multi-IP Single Server

Deploy multiple instances pada server dengan multiple IP addresses.

**Target:**
- Server: vps.btd.co.id
- IP 1: 103.254.100.1
- IP 2: 103.254.100.2
- IP 3: 103.254.100.3

**Steps:**

```bash
# SSH to server
ssh root@vps.btd.co.id

# Install binary once
cd /tmp
git clone <repo> speedtest-temp
cd speedtest-temp
go build -ldflags="-s -w" -o speedtest main.go
cp speedtest /usr/local/bin/
cd .. && rm -rf speedtest-temp

# Create template service
cat > /etc/systemd/system/speedtest@.service << 'EOF'
[Unit]
Description=SpeedTest Service - Instance %i
After=network.target

[Service]
Type=simple
User=speedtest
EnvironmentFile=/etc/speedtest/speedtest-%i.env
ExecStart=/usr/local/bin/speedtest
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Create configs for each IP
mkdir -p /etc/speedtest

cat > /etc/speedtest/speedtest-1.env << 'EOF'
PORT=8080
BIND_IP=103.254.100.1
NODE_NAME=Node-IP1
BUFFER_SIZE=1048576
EOF

cat > /etc/speedtest/speedtest-2.env << 'EOF'
PORT=8080
BIND_IP=103.254.100.2
NODE_NAME=Node-IP2
BUFFER_SIZE=1048576
EOF

cat > /etc/speedtest/speedtest-3.env << 'EOF'
PORT=8080
BIND_IP=103.254.100.3
NODE_NAME=Node-IP3
BUFFER_SIZE=1048576
EOF

# Create user
useradd -r -s /bin/false speedtest

# Enable and start all instances
systemctl daemon-reload
systemctl enable speedtest@{1,2,3}
systemctl start speedtest@{1,2,3}

# Check status
systemctl status speedtest@1
systemctl status speedtest@2
systemctl status speedtest@3

# Test each IP
curl http://103.254.100.1:8080/health
curl http://103.254.100.2:8080/health
curl http://103.254.100.3:8080/health
```

---

### Scenario 4: Docker Deployment (Multiple Nodes)

Deploy menggunakan Docker untuk kemudahan management.

**Docker Image Deployment:**

```bash
# Build image once
cd /path/to/SpeedTest
docker build -t speedtest:latest .

# Save and transfer to nodes
docker save speedtest:latest | gzip > speedtest.tar.gz

# On each node:
# Transfer file
scp speedtest.tar.gz root@103.254.100.1:/tmp/

# Load and run
ssh root@103.254.100.1 << 'ENDSSH'
cd /tmp
docker load < speedtest.tar.gz

# Run container
docker run -d \
  --name speedtest \
  --restart unless-stopped \
  -p 8080:8080 \
  -e NODE_NAME=Jakarta-Node \
  speedtest:latest

# Verify
docker ps
curl http://localhost:8080/health
ENDSSH
```

**Docker Compose (per node):**

```yaml
# docker-compose.yml on each node
version: '3.8'
services:
  speedtest:
    image: speedtest:latest
    container_name: speedtest-node
    ports:
      - "8080:8080"
    environment:
      - NODE_NAME=Jakarta-Node  # Change per node
      - PORT=8080
      - BIND_IP=0.0.0.0
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
```

---

## 🔧 Post-Deployment Configuration

### DNS Setup

Point subdomain ke masing-masing IP:

```bash
# Di DNS manager (Cloudflare, Route53, dll):
A Record: speedtest1.btd.co.id -> 103.254.100.1
A Record: speedtest2.btd.co.id -> 103.254.100.2
A Record: speedtest3.btd.co.id -> 103.254.100.3
```

### Firewall Configuration

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 8080/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo netfilter-persistent save

# firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### Reverse Proxy (Optional)

**Setup Nginx as reverse proxy untuk HTTPS:**

```nginx
# /etc/nginx/sites-available/speedtest-node1
server {
    listen 80;
    server_name speedtest1.btd.co.id;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # Disable buffering for speedtest
        proxy_buffering off;
        proxy_request_buffering off;
    }
}

# Enable
ln -s /etc/nginx/sites-available/speedtest-node1 /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

# Add SSL with Let's Encrypt
certbot --nginx -d speedtest1.btd.co.id
```

---

## 🔍 Monitoring & Verification

### Health Check Script

Create `check-nodes.sh`:
```bash
#!/bin/bash

NODES=(
    "speedtest1.btd.co.id"
    "speedtest2.btd.co.id"
    "speedtest3.btd.co.id"
)

echo "Checking all nodes..."
for node in "${NODES[@]}"; do
    echo -n "Checking ${node}... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" http://${node}:8080/health)
    
    if [ "$response" -eq 200 ]; then
        echo "✓ OK"
    else
        echo "✗ FAILED (HTTP $response)"
    fi
done
```

### Monitoring with cron

```bash
# Add to crontab
*/5 * * * * /opt/speedtest/check-nodes.sh | logger -t speedtest-monitor
```

---

## 🔄 Update/Upgrade Procedure

### Rolling Update (Zero Downtime)

```bash
# Update nodes one by one
for ip in 103.254.100.1 103.254.100.2 103.254.100.3; do
    echo "Updating ${ip}..."
    
    # Deploy new version
    ./deploy.sh ${ip} root
    
    # Wait for stabilization
    sleep 5
    
    # Verify
    curl -f http://${ip}:8080/health || echo "Update failed on ${ip}"
    
    # Wait before next node
    sleep 10
done
```

### Quick Hotfix

```bash
# Build new binary
go build -ldflags="-s -w" -o speedtest main.go

# Deploy to all nodes
for ip in 103.254.100.1 103.254.100.2 103.254.100.3; do
    scp speedtest root@${ip}:/usr/local/bin/
    ssh root@${ip} "systemctl restart speedtest"
done
```

---

## 🐛 Troubleshooting

### Service won't start

```bash
# Check logs
journalctl -u speedtest -n 50 --no-pager

# Common issues:
# 1. Port already in use
sudo lsof -i :8080

# 2. Binary permission
ls -la /usr/local/bin/speedtest
chmod +x /usr/local/bin/speedtest

# 3. Config file issues
cat /etc/speedtest/speedtest.env
```

### Network issues

```bash
# Test binding
ss -tlnp | grep 8080

# Test connectivity
telnet localhost 8080

# Check firewall
sudo ufw status
sudo iptables -L -n | grep 8080
```

### Performance issues

```bash
# Check resource usage
top -p $(pgrep speedtest)

# Check connections
netstat -an | grep :8080 | wc -l

# Check system limits
ulimit -a
```

---

## 📊 Deployment Checklist

- [ ] Binary built successfully
- [ ] SSH access to all target servers
- [ ] Firewall rules configured
- [ ] DNS records created
- [ ] Service installed and running
- [ ] Health check endpoints responding
- [ ] Node names configured correctly
- [ ] Monitoring setup
- [ ] Backup/rollback plan ready
- [ ] Documentation updated

---

## ✅ Deployment Complete!

Your SpeedTest nodes are now deployed and ready to serve traffic!

Next steps:
1. Setup monitoring and alerting
2. Configure auto-scaling (if needed)
3. Setup backup and disaster recovery
4. Document node-specific configurations
5. Setup centralized logging
