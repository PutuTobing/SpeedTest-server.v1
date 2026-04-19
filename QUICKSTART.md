# ⚡ Quick Start Guide

Panduan cepat untuk setup SpeedTest Service dalam 5 menit.

## 🚀 Fastest Setup (Ubuntu/Debian)

```bash
# 1. Install Go (if not installed)
sudo apt update
sudo apt install golang-go -y

# 2. Clone & Build
cd /opt
sudo git clone <your-repo-url> speedtest
cd speedtest
make build

# 3. Install
sudo make install

# 4. Configure
sudo nano /etc/speedtest/speedtest.env
# Edit NODE_NAME jika perlu

# 5. Start
sudo systemctl start speedtest
sudo systemctl enable speedtest

# 6. Test
curl http://localhost:8080/
# Should return: "Server Ready"
```

**Done! 🎉**

---

## 🐳 Quick Start with Docker

```bash
# 1. Clone
git clone <your-repo-url> speedtest
cd speedtest

# 2. Build & Run
docker-compose up -d

# 3. Test
curl http://localhost:8080/
```

**Done! 🎉**

---

## 🧪 Quick Test

```bash
# Make test script executable
chmod +x test.sh

# Run tests
./test.sh
```

---

## 🔧 Quick Configuration

### Change Port
```bash
# Edit config
sudo nano /etc/speedtest/speedtest.env
# Change: PORT=9090

# Restart
sudo systemctl restart speedtest
```

### Change Node Name
```bash
# Edit config
sudo nano /etc/speedtest/speedtest.env
# Change: NODE_NAME=My-Custom-Name

# Restart
sudo systemctl restart speedtest
```

### Bind to Specific IP
```bash
# Edit config
sudo nano /etc/speedtest/speedtest.env
# Add: BIND_IP=103.254.100.1

# Restart
sudo systemctl restart speedtest
```

---

## 📊 Quick Commands

```bash
# Check status
sudo systemctl status speedtest

# View logs
sudo journalctl -u speedtest -f

# Restart service
sudo systemctl restart speedtest

# Stop service
sudo systemctl stop speedtest

# Test endpoints
curl http://localhost:8080/           # Root
curl http://localhost:8080/ping       # Ping
curl http://localhost:8080/health     # Health
```

---

## 🌐 Remote Deployment (One Line)

```bash
# Deploy to remote server
./deploy.sh 103.254.100.1 root
```

---

## ❓ Troubleshooting Quick Fixes

### Port already in use
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
sudo systemctl start speedtest
```

### Service won't start
```bash
# Check logs
sudo journalctl -u speedtest -n 20

# Try manual run
sudo -u speedtest /usr/local/bin/speedtest
```

### Can't access remotely
```bash
# Open firewall
sudo ufw allow 8080/tcp

# Or iptables
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

---

## 📚 More Information

- Full documentation: [README.md](README.md)
- Installation guide: [INSTALL.md](INSTALL.md)
- Deployment guide: [DEPLOYMENT.md](DEPLOYMENT.md)
- Performance tuning: [PERFORMANCE.md](PERFORMANCE.md)

---

## ✅ That's it!

Your SpeedTest service is now running. Enjoy! 🚀
