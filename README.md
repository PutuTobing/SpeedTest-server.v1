<img width="733" height="320" alt="image" src="https://github.com/user-attachments/assets/bad07d63-0315-4bfc-b047-43b78c10e3cf" /># 🚀 SpeedTest Server v1.0

**SKY BASE TECHNOLOGY DIGITAL (BTD)**  
Server speedtest berbasis Go untuk pengujian kecepatan internet jaringan lokal ISP.

---

## ⚡ Instalasi Cepat (1 Perintah)

```bash
git clone https://github.com/PutuTobing/SpeedTest-server.v1.git
cd SpeedTest-server.v1
sudo bash install.sh
```

Script akan otomatis:
- ✅ Install semua dependensi (curl, wget, git, dll)
- ✅ Install Go jika belum ada
- ✅ Kompilasi binary speedtest
- ✅ Meminta konfigurasi IP, port, dan lokasi server
- ✅ Install sebagai systemd service (auto-start)
- ✅ Konfigurasi firewall
- ✅ Verifikasi server berjalan

---

## 🖥️ Persyaratan Sistem

| Komponen | Minimum |
|----------|---------|
| OS       | Ubuntu 20.04 / Debian 10 / CentOS 7+ / Rocky Linux |
| RAM      | 4 Gbps |
| CPU      | 2 Core |
| Disk     | 32 Gb |
| Port     | 8080 (tidak dapat diganti) |

---

## 📋 Langkah Installasi Detail

### 1. Clone Repository
```bash
git clone https://github.com/PutuTobing/SpeedTest-server.v1.git
cd SpeedTest-server.v1
```

### 2. Jalankan Installer
```bash
sudo bash install.sh
```

### 3. Isi Konfigurasi
Script akan menanyakan:
- **IP Address**: Tekan Enter untuk `0.0.0.0` (direkomendasikan)
- **Port**: Tekan Enter untuk `8080` (direkomendasikan)  
- **Lokasi**: Masukkan nama kota/daerah (contoh: `Lampung`)
- **Nama Node**: Nama identitas server (contoh: `SpeedTest-Lampung-BTD`)

### 4. Verifikasi Instalasi
```bash
curl http://localhost:8080/
```

Output yang diharapkan:
```json
{"status":"ready","node":"SpeedTest-Lampung-BTD","message":"SpeedTest API Server"}
```

---


## ⚙️ Konfigurasi

File konfigurasi tersimpan di `/etc/speedtest/speedtest.env`:

```env
PORT=8080
BIND_IP=0.0.0.0
NODE_NAME=SpeedTest-Lampung-BTD
LOCATION=Lampung
BUFFER_SIZE=1048576
TIMEOUT=30s
```

Setelah ubah konfigurasi, restart service:
```bash
sudo systemctl restart speedtest-server
```

---

## 🛠️ Manajemen Service

```bash
# Cek status
sudo systemctl status speedtest-server

# Start / Stop / Restart
sudo systemctl start speedtest-server
sudo systemctl stop speedtest-server
sudo systemctl restart speedtest-server

# Lihat log realtime
sudo journalctl -u speedtest-server -f
```

---

## 🔌 Port & Firewall

Secara default server berjalan di port **8080**. Script installer otomatis
membuka port di firewall (UFW / firewalld / iptables).

Manual buka port (jika perlu):
```bash
# UFW
sudo ufw allow 8080/tcp

# firewalld
sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --reload
```
## Alur Speedtest 
Contoh :
<img width="637" height="236" alt="image" src="https://github.com/user-attachments/assets/a6342ad5-ef3f-440b-b0f5-3c3ebb752445" />

--
## Daftarkan Server
1. setelah anda selesai melakukan instalasi dan setelah melakukan pengecekan pada http://ipserveranda:8080 muncul hasil speedtest ready maka anda bisa mendaftarkan server speedtest ke web kami di https://speedtest.btd.co.id/
2. ataupun anda bisa menghubungi kami melalui informasi kontak dibawah ini.

## 📞 Support

- Email: noc@btd.co.id  
- Website: https://btd.co.id

---

**Developed by BTD System** | MIT License | © 2026
