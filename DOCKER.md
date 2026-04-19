# 🐳 Instalasi Docker - SpeedTest Server

Panduan lengkap instalasi SpeedTest Server menggunakan Docker.

---

## 📋 Prasyarat

| Kebutuhan | Minimum | Rekomendasi |
|-----------|---------|-------------|
| OS | Linux (Ubuntu 20.04+, Debian 11+, CentOS 7+) | Ubuntu 22.04 LTS |
| RAM | 128 MB | 512 MB |
| CPU | 1 core | 2 core |
| Disk | 50 MB | 100 MB |
| Port | 8080 (dapat diubah) | 8080 |
| Docker | 20.10+ | 24.x+ |

---

## 🚀 Metode 1: Auto Installer (Paling Mudah)

Satu perintah untuk install semuanya (Docker + SpeedTest Server):

```bash
curl -fsSL https://raw.githubusercontent.com/PutuTobing/SpeedTest-server.v1/main/install-docker.sh | sudo bash
```

Script ini akan:
- Install Docker jika belum ada
- Tanya konfigurasi (PORT, NODE_NAME, LOCATION)
- Pull image dari Docker Hub
- Jalankan container secara otomatis
- Buka firewall (jika ufw/firewalld terdeteksi)
- Verifikasi server berjalan

---

## 🐳 Metode 2: Docker Run

Pull dan jalankan langsung tanpa Compose:

```bash
docker pull ipututobing/speedtest-server:latest

docker run -d \
  --name speedtest-server \
  --restart unless-stopped \
  -p 8080:8080 \
  -e NODE_NAME="SpeedTest-Jakarta" \
  -e LOCATION="Jakarta, Indonesia" \
  -e BUFFER_SIZE="4194304" \
  ipututobing/speedtest-server:latest
```

**Ganti nilai environment sesuai server Anda:**

| Variable | Default | Keterangan |
|----------|---------|------------|
| `NODE_NAME` | `SpeedTest-Docker` | Nama node tampil di frontend |
| `LOCATION` | `Unknown` | Lokasi geografis node |
| `PORT` | `8080` | Port server (dalam container) |
| `BIND_IP` | `0.0.0.0` | IP binding (jangan diubah kecuali perlu) |
| `BUFFER_SIZE` | `4194304` | Buffer size 4MB (bytes) |
| `TIMEOUT` | `30s` | Timeout koneksi |

---

## 📦 Metode 3: Docker Compose (Rekomendasi Production)

### 3a. Download dan jalankan

```bash
# Download docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/PutuTobing/SpeedTest-server.v1/main/docker-compose.yml -o docker-compose.yml

# Jalankan
NODE_NAME="SpeedTest-Lampung" LOCATION="Lampung, Indonesia" docker compose up -d
```

### 3b. Clone repo lalu jalankan

```bash
git clone https://github.com/PutuTobing/SpeedTest-server.v1.git
cd SpeedTest-server.v1

# Jalankan dengan variabel env
NODE_NAME="SpeedTest-Node1" LOCATION="Jakarta" SERVER_PORT=8080 docker compose up -d
```

### 3c. Menggunakan file .env

Buat file `.env` di direktori yang sama dengan `docker-compose.yml`:

```bash
cat > .env << 'EOF'
NODE_NAME=SpeedTest-Node1
LOCATION=Jakarta, Indonesia
SERVER_PORT=8080
EOF

docker compose up -d
```

---

## 🏗️ Metode 4: Build dari Source

Jika ingin memodifikasi source code:

```bash
git clone https://github.com/PutuTobing/SpeedTest-server.v1.git
cd SpeedTest-server.v1

# Build image lokal
docker build -t speedtest-server:local .

# Jalankan image lokal
docker run -d \
  --name speedtest-server \
  --restart unless-stopped \
  -p 8080:8080 \
  -e NODE_NAME="SpeedTest-Custom" \
  speedtest-server:local
```

Atau edit `docker-compose.yml`, uncomment bagian `build:`:

```yaml
services:
  speedtest:
    # image: ipututobing/speedtest-server:latest
    build:
      context: .
      dockerfile: Dockerfile
```

Lalu:

```bash
docker compose up -d --build
```

---

## 🔧 Manajemen Container

### Cek status

```bash
docker ps | grep speedtest
docker logs speedtest-server
docker logs -f speedtest-server   # tail live
```

### Restart / Stop / Hapus

```bash
docker restart speedtest-server
docker stop speedtest-server
docker rm speedtest-server
```

### Update ke versi terbaru

```bash
docker pull ipututobing/speedtest-server:latest
docker stop speedtest-server && docker rm speedtest-server

# Jalankan ulang dengan perintah docker run yang sama
docker run -d \
  --name speedtest-server \
  --restart unless-stopped \
  -p 8080:8080 \
  -e NODE_NAME="SpeedTest-Node" \
  -e LOCATION="Indonesia" \
  ipututobing/speedtest-server:latest
```

Atau jika pakai Compose:

```bash
docker compose pull
docker compose up -d
```

---

## ✅ Verifikasi Instalasi

Setelah container berjalan, test endpoint berikut:

```bash
# Status server
curl http://localhost:8080/

# Health check
curl http://localhost:8080/health

# Ping test
curl -X POST http://localhost:8080/ping -d "0000" -H "Content-Type: application/octet-stream"

# Download test (1MB)
curl -o /dev/null -w "%{speed_download}" http://localhost:8080/download?size=1048576

# Upload test (1MB)
dd if=/dev/urandom bs=1M count=1 | curl -X POST http://localhost:8080/upload \
  -H "Content-Type: application/octet-stream" --data-binary @- -o /dev/null -w "\nUpload: %{speed_upload} B/s\n"
```

Contoh respons `/health` yang berhasil:

```json
{
  "status": "ok",
  "version": "1.1.0",
  "node": "SpeedTest-Node1",
  "location": "Jakarta, Indonesia"
}
```

---

## 🌐 Konfigurasi Port Kustom

Untuk menggunakan port selain 8080:

```bash
# Port 9090
docker run -d \
  --name speedtest-server \
  --restart unless-stopped \
  -p 9090:8080 \
  -e NODE_NAME="SpeedTest-Node" \
  ipututobing/speedtest-server:latest
```

Atau via Compose:

```bash
SERVER_PORT=9090 NODE_NAME="SpeedTest-Node" docker compose up -d
```

---

## 🔒 Firewall

### UFW (Ubuntu/Debian)

```bash
sudo ufw allow 8080/tcp
sudo ufw reload
sudo ufw status
```

### Firewalld (CentOS/RHEL/AlmaLinux)

```bash
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

### iptables (Manual)

```bash
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
```

---

## 🖥️ Deploy Multi-Node

Untuk deploy ke banyak server sekaligus:

```bash
# nodes.txt - daftar server
cat > nodes.txt << 'EOF'
103.254.100.1 speedtest1.btd.co.id Jakarta
103.254.100.2 speedtest2.btd.co.id Lampung
103.254.100.3 speedtest3.btd.co.id Bandung
EOF

# Deploy ke semua node
while IFS=' ' read -r IP DOMAIN LOCATION; do
  echo "Deploying to $IP ($LOCATION)..."
  ssh root@$IP "docker pull ipututobing/speedtest-server:latest && \
    docker stop speedtest-server 2>/dev/null || true && \
    docker rm speedtest-server 2>/dev/null || true && \
    docker run -d --name speedtest-server --restart unless-stopped \
      -p 8080:8080 \
      -e NODE_NAME=\"SpeedTest-${LOCATION}\" \
      -e LOCATION=\"${LOCATION}, Indonesia\" \
      ipututobing/speedtest-server:latest"
done < nodes.txt
```

---

## 🐛 Troubleshooting

### Container tidak mau start

```bash
docker logs speedtest-server
```

### Port sudah dipakai

```bash
sudo ss -tlnp | grep 8080
# Ganti port dengan -p 9090:8080
```

### Permission denied saat docker run

```bash
# Tambahkan user ke group docker (tanpa sudo)
sudo usermod -aG docker $USER
newgrp docker
```

### Container restart terus (crashloop)

```bash
docker logs --tail=50 speedtest-server
# Biasanya ada konflik port atau error env variable
```

---

## 📊 Image Info

| | |
|--|--|
| **Image** | `ipututobing/speedtest-server` |
| **Tags** | `latest`, `v1.1.0` |
| **Base** | `scratch` (minimal, tanpa OS) |
| **Size** | ~2.6 MB |
| **Architecture** | `amd64`, `arm64` |
| **Docker Hub** | https://hub.docker.com/r/ipututobing/speedtest-server |

---

## 📚 Lihat Juga

- [README.md](README.md) — Gambaran umum project
- [QUICKSTART.md](QUICKSTART.md) — Instalasi non-Docker (Go binary)
- [DEPLOYMENT.md](DEPLOYMENT.md) — Deploy multi-node lanjutan
- [API.md](API.md) — Dokumentasi endpoint API
