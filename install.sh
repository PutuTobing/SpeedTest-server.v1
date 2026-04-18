#!/bin/bash
# =============================================================================
#  SpeedTest Server - Auto Install Script
#  SKY BASE TECHNOLOGY DIGITAL (BTD)
#  Version: 1.0.0
# =============================================================================

set -e

# ── Warna Terminal ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Helper Functions ─────────────────────────────────────────────────────────
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║          SKY TECH - SpeedTest Server Installer       ║"
    echo "  ║       PT SKY BASE TECHNOLOGY DIGITAL (BTD)           ║"
    echo "  ║                   Version 1.0.0                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}${BOLD}[STEP]${NC} ${WHITE}$1${NC}"
}

print_ok() {
    echo -e "  ${GREEN}✔${NC}  $1"
}

print_warn() {
    echo -e "  ${YELLOW}⚠${NC}  $1"
}

print_error() {
    echo -e "  ${RED}✘${NC}  $1"
}

print_info() {
    echo -e "  ${CYAN}ℹ${NC}  $1"
}

# ── Periksa User Root ────────────────────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}${BOLD}Error:${NC} Script ini harus dijalankan sebagai root."
        echo -e "       Gunakan: ${YELLOW}sudo bash install.sh${NC}"
        exit 1
    fi
}

# ── Deteksi Distro Linux ─────────────────────────────────────────────────────
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif command -v lsb_release &>/dev/null; then
        DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    else
        DISTRO="unknown"
    fi
}

# ── Install Dependensi ───────────────────────────────────────────────────────
install_dependencies() {
    print_step "Menginstal dependensi sistem..."

    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop)
            print_info "Terdeteksi: Debian/Ubuntu based"
            apt-get update -qq 2>/dev/null
            apt-get install -y -qq curl wget git build-essential 2>/dev/null
            print_ok "Dependensi dasar terinstal"
            ;;
        centos|rhel|fedora|rocky|almalinux)
            print_info "Terdeteksi: RHEL/CentOS based"
            if command -v dnf &>/dev/null; then
                dnf install -y -q curl wget git gcc 2>/dev/null
            else
                yum install -y -q curl wget git gcc 2>/dev/null
            fi
            print_ok "Dependensi dasar terinstal"
            ;;
        arch|manjaro)
            print_info "Terdeteksi: Arch Linux based"
            pacman -Sy --noconfirm --quiet curl wget git base-devel 2>/dev/null
            print_ok "Dependensi dasar terinstal"
            ;;
        *)
            print_warn "Distro tidak dikenal ($DISTRO). Mencoba dengan apt..."
            apt-get update -qq 2>/dev/null && apt-get install -y -qq curl wget git 2>/dev/null || true
            ;;
    esac
}

# ── Install Go ───────────────────────────────────────────────────────────────
install_go() {
    print_step "Memeriksa instalasi Go..."

    GO_VERSION="1.21.8"
    GO_MIN_VERSION="1.21"

    if command -v go &>/dev/null; then
        CURRENT_GO=$(go version | grep -oP '\d+\.\d+' | head -1)
        print_ok "Go sudah terinstal: $(go version | awk '{print $3}')"
        return 0
    fi

    print_info "Go tidak ditemukan. Menginstal Go ${GO_VERSION}..."

    # Deteksi arsitektur
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  GO_ARCH="amd64" ;;
        aarch64) GO_ARCH="arm64" ;;
        armv7l)  GO_ARCH="armv6l" ;;
        *)
            print_error "Arsitektur tidak didukung: $ARCH"
            exit 1
            ;;
    esac

    GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    GO_TAR="/tmp/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"

    echo -ne "  ${CYAN}↓${NC}  Mengunduh Go ${GO_VERSION} (${GO_ARCH})... "
    if wget -q --show-progress "$GO_URL" -O "$GO_TAR" 2>&1 | tail -1; then
        echo -e "${GREEN}selesai${NC}"
    else
        # Fallback dengan curl
        curl -L -s -o "$GO_TAR" "$GO_URL"
        echo -e "${GREEN}selesai${NC}"
    fi

    # Hapus instalasi lama jika ada
    rm -rf /usr/local/go 2>/dev/null || true

    echo -ne "  ${CYAN}⚙${NC}  Mengekstrak Go... "
    tar -C /usr/local -xzf "$GO_TAR"
    rm -f "$GO_TAR"
    echo -e "${GREEN}selesai${NC}"

    # Setup PATH
    export PATH=$PATH:/usr/local/go/bin

    # Tambahkan PATH permanen
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi

    if ! grep -q "/usr/local/go/bin" /etc/environment 2>/dev/null; then
        echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin"' > /etc/environment
    fi

    # Tambahkan ke .bashrc dan .profile untuk user
    for PROFILE_FILE in /root/.bashrc /root/.profile; do
        if [ -f "$PROFILE_FILE" ] && ! grep -q "/usr/local/go/bin" "$PROFILE_FILE"; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> "$PROFILE_FILE"
        fi
    done

    if command -v go &>/dev/null; then
        print_ok "Go berhasil diinstal: $(go version | awk '{print $3}')"
    else
        print_error "Gagal menginstal Go. Periksa koneksi internet Anda."
        exit 1
    fi
}

# ── Input Konfigurasi Server ─────────────────────────────────────────────────
get_server_config() {
    print_step "Konfigurasi SpeedTest Server"
    echo ""

    # ── IP Server ──
    echo -e "  ${WHITE}📡 IP Address / Host Server${NC}"
    echo -e "  ${YELLOW}Saran: Gunakan 0.0.0.0 agar bisa diakses dari mana saja${NC}"
    echo -e "  ${YELLOW}       atau masukkan IP spesifik server Anda${NC}"
    echo ""
    read -p "  Masukkan IP [tekan Enter untuk 0.0.0.0]: " INPUT_IP
    SERVER_IP="${INPUT_IP:-0.0.0.0}"

    # Jika input localhost, mapping ke 0.0.0.0 agar bisa bind
    if [[ "$SERVER_IP" == "localhost" ]]; then
        SERVER_IP="0.0.0.0"
        print_info "localhost dikonversi ke 0.0.0.0 untuk binding"
    fi
    echo ""

    # ── Port ──
    echo -e "  ${WHITE}🔌 Port Server${NC}"
    echo -e "  ${YELLOW}Saran: Gunakan port 8080 (default)${NC}"
    echo ""
    read -p "  Masukkan Port [tekan Enter untuk 8080]: " INPUT_PORT
    SERVER_PORT="${INPUT_PORT:-8080}"

    # Validasi port
    if ! [[ "$SERVER_PORT" =~ ^[0-9]+$ ]] || [ "$SERVER_PORT" -lt 1 ] || [ "$SERVER_PORT" -gt 65535 ]; then
        print_warn "Port tidak valid, menggunakan 8080"
        SERVER_PORT="8080"
    fi
    echo ""

    # ── Lokasi Server ──
    echo -e "  ${WHITE}📍 Lokasi Server (Kota/Daerah)${NC}"
    echo -e "  ${YELLOW}Contoh: Lampung, Jakarta, Bandung, Surabaya, dll${NC}"
    echo ""
    read -p "  Masukkan lokasi server: " INPUT_LOCATION
    SERVER_LOCATION="${INPUT_LOCATION:-Server Tidak Diketahui}"
    echo ""

    # ── Nama Node ──
    echo -e "  ${WHITE}🏷️  Nama Node / Identitas Server${NC}"
    echo -e "  ${YELLOW}Contoh: SpeedTest-Lampung-BTD, Node-Jakarta-1, dll${NC}"
    echo ""
    read -p "  Masukkan nama node [tekan Enter untuk SpeedTest-${SERVER_LOCATION}]: " INPUT_NODE
    NODE_NAME="${INPUT_NODE:-SpeedTest-${SERVER_LOCATION}}"
    echo ""

    # ── Konfirmasi ──
    echo -e "  ┌─────────────────────────────────────────────────┐"
    echo -e "  │  ${BOLD}Ringkasan Konfigurasi${NC}                           │"
    echo -e "  ├─────────────────────────────────────────────────┤"
    echo -e "  │  Bind IP    : ${CYAN}${SERVER_IP}${NC}"
    echo -e "  │  Port       : ${CYAN}${SERVER_PORT}${NC}"
    echo -e "  │  Lokasi     : ${CYAN}${SERVER_LOCATION}${NC}"
    echo -e "  │  Node Name  : ${CYAN}${NODE_NAME}${NC}"
    echo -e "  └─────────────────────────────────────────────────┘"
    echo ""
    read -p "  Lanjutkan instalasi? [Y/n]: " CONFIRM
    CONFIRM="${CONFIRM:-Y}"

    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Instalasi dibatalkan.${NC}"
        exit 0
    fi
}

# ── Build Binary SpeedTest ───────────────────────────────────────────────────
build_binary() {
    print_step "Kompilasi SpeedTest Server..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Pastikan go.mod ada
    if [ ! -f "$SCRIPT_DIR/go.mod" ]; then
        print_info "Menginisialisasi Go module..."
        cd "$SCRIPT_DIR" && /usr/local/go/bin/go mod init speedtest 2>/dev/null || true
    fi

    echo -ne "  ${CYAN}⚙${NC}  Mengompilasi binary... "
    cd "$SCRIPT_DIR"

    if /usr/local/go/bin/go build -ldflags="-s -w" -o speedtest-bin main.go 2>/tmp/go_build_error.log; then
        echo -e "${GREEN}selesai${NC}"
        print_ok "Binary berhasil dikompilasi: $(du -sh speedtest-bin | cut -f1)"
    else
        echo -e "${RED}gagal${NC}"
        print_error "Build error:"
        cat /tmp/go_build_error.log
        exit 1
    fi
}

# ── Install Service Systemd ──────────────────────────────────────────────────
install_service() {
    print_step "Menginstal SpeedTest sebagai system service..."

    # Buat env file
    mkdir -p /etc/speedtest
    cat > /etc/speedtest/speedtest.env <<EOF
# SpeedTest Server Configuration
# Generated by install.sh on $(date '+%Y-%m-%d %H:%M:%S')

PORT=${SERVER_PORT}
BIND_IP=${SERVER_IP}
NODE_NAME=${NODE_NAME}
LOCATION=${SERVER_LOCATION}
BUFFER_SIZE=1048576
TIMEOUT=30s
EOF
    print_ok "File konfigurasi dibuat: /etc/speedtest/speedtest.env"

    # Salin binary ke /usr/local/bin
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "$SCRIPT_DIR/speedtest-bin" /usr/local/bin/speedtest-server
    chmod +x /usr/local/bin/speedtest-server
    print_ok "Binary diinstal ke: /usr/local/bin/speedtest-server"

    # Buat user system jika belum ada
    if ! id -u speedtest &>/dev/null; then
        useradd --system --no-create-home --shell /bin/false speedtest 2>/dev/null || true
        print_ok "User system 'speedtest' dibuat"
    fi

    # Buat working directory
    mkdir -p /opt/speedtest
    chown speedtest:speedtest /opt/speedtest 2>/dev/null || true

    # Buat systemd service file
    cat > /etc/systemd/system/speedtest-server.service <<EOF
[Unit]
Description=SpeedTest HTTP Server - ${NODE_NAME}
Documentation=https://btd.co.id
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=speedtest
Group=speedtest

ExecStart=/usr/local/bin/speedtest-server
EnvironmentFile=/etc/speedtest/speedtest.env

WorkingDirectory=/opt/speedtest
Restart=always
RestartSec=5s

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/speedtest

# Performance
LimitNOFILE=65536
LimitNPROC=4096

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=speedtest-server

[Install]
WantedBy=multi-user.target
EOF
    print_ok "Systemd service file dibuat"

    # Reload dan enable service
    systemctl daemon-reload
    systemctl enable speedtest-server
    systemctl start speedtest-server
    print_ok "Service diaktifkan dan dijalankan"

    # Tunggu service start
    sleep 2

    # Cek status service
    if systemctl is-active --quiet speedtest-server; then
        print_ok "Service berjalan dengan baik"
    else
        print_warn "Service gagal start, mencoba tanpa systemd..."
        install_without_systemd
    fi
}

# ── Fallback: Install Tanpa Systemd ─────────────────────────────────────────
install_without_systemd() {
    print_info "Menjalankan server langsung (tanpa systemd)..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Buat startup script
    cat > "$SCRIPT_DIR/start-server.sh" <<EOF
#!/bin/bash
export PORT=${SERVER_PORT}
export BIND_IP=${SERVER_IP}
export NODE_NAME="${NODE_NAME}"
export LOCATION="${SERVER_LOCATION}"
export BUFFER_SIZE=1048576
export TIMEOUT=30s

echo "Starting SpeedTest Server..."
echo "  IP      : \${BIND_IP}:\${PORT}"
echo "  Lokasi  : \${LOCATION}"
exec /usr/local/bin/speedtest-server
EOF
    chmod +x "$SCRIPT_DIR/start-server.sh"

    # Jalankan dengan nohup
    export PORT=${SERVER_PORT}
    export BIND_IP=${SERVER_IP}
    export NODE_NAME="${NODE_NAME}"
    export LOCATION="${SERVER_LOCATION}"

    nohup /usr/local/bin/speedtest-server > /var/log/speedtest-server.log 2>&1 &
    SPEEDTEST_PID=$!
    echo "$SPEEDTEST_PID" > /var/run/speedtest-server.pid

    print_ok "Server berjalan dengan PID: $SPEEDTEST_PID"
    print_info "Log tersedia di: /var/log/speedtest-server.log"
}

# ── Setup Firewall ───────────────────────────────────────────────────────────
setup_firewall() {
    print_step "Mengonfigurasi firewall untuk port ${SERVER_PORT}..."

    # UFW (Ubuntu/Debian)
    if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
        ufw allow "${SERVER_PORT}/tcp" > /dev/null 2>&1
        print_ok "Rule UFW ditambahkan: allow ${SERVER_PORT}/tcp"

    # firewalld (CentOS/RHEL/Fedora)
    elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --add-port="${SERVER_PORT}/tcp" > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
        print_ok "Rule firewalld ditambahkan: ${SERVER_PORT}/tcp"

    # iptables langsung
    elif command -v iptables &>/dev/null; then
        iptables -I INPUT -p tcp --dport "${SERVER_PORT}" -j ACCEPT 2>/dev/null || true
        print_ok "iptables rule ditambahkan: ${SERVER_PORT}/tcp"

    else
        print_warn "Firewall tidak terdeteksi. Pastikan port ${SERVER_PORT} terbuka secara manual."
    fi
}

# ── Verifikasi Server Berjalan ───────────────────────────────────────────────
verify_server() {
    print_step "Memverifikasi server..."

    # Tunggu server siap
    echo -ne "  ${CYAN}⌛${NC}  Menunggu server siap"
    RETRY=0
    MAX_RETRY=15

    while [ $RETRY -lt $MAX_RETRY ]; do
        if curl -s --max-time 2 "http://127.0.0.1:${SERVER_PORT}/" > /tmp/speedtest_check.json 2>/dev/null; then
            echo -e " ${GREEN}✔${NC}"
            break
        fi
        echo -ne "."
        sleep 1
        RETRY=$((RETRY + 1))
    done

    if [ $RETRY -eq $MAX_RETRY ]; then
        echo -e " ${YELLOW}timeout${NC}"
        print_warn "Server mungkin belum siap. Coba cek manual."
        return
    fi

    # Tampilkan response server
    SERVER_STATUS=$(cat /tmp/speedtest_check.json 2>/dev/null)
    print_ok "Response dari server: ${CYAN}${SERVER_STATUS}${NC}"
}

# ── Cek Port Tersedia ────────────────────────────────────────────────────────
check_port() {
    if command -v ss &>/dev/null; then
        if ss -tlnp | grep -q ":${SERVER_PORT} "; then
            print_warn "Port ${SERVER_PORT} sudah digunakan oleh proses lain!"
            echo ""
            ss -tlnp | grep ":${SERVER_PORT} "
            echo ""
            read -p "  Lanjutkan? Port mungkin konflik. [y/N]: " CONTINUE_PORT
            if [[ ! "$CONTINUE_PORT" =~ ^[Yy]$ ]]; then
                echo -e "\n  ${YELLOW}Instalasi dibatalkan. Ubah port di konfigurasi.${NC}"
                exit 1
            fi
        fi
    fi
}

# ── Dapatkan IP Publik ───────────────────────────────────────────────────────
get_public_ip() {
    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || \
                curl -s --max-time 5 https://ifconfig.me 2>/dev/null || \
                hostname -I | awk '{print $1}' 2>/dev/null || \
                echo "tidak_tersedia")
}

# ── Tampilkan Summary Akhir ──────────────────────────────────────────────────
print_summary() {
    get_public_ip

    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

    echo ""
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║                                                          ║"
    echo "  ║   ✅  INSTALASI BERHASIL! SERVER READY                  ║"
    echo "  ║                                                          ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}📡 Informasi Server:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  Node Name  : ${CYAN}${NODE_NAME}${NC}"
    echo -e "  Lokasi     : ${CYAN}${SERVER_LOCATION}${NC}"
    echo -e "  Port       : ${CYAN}${SERVER_PORT}${NC}"
    echo ""
    echo -e "  ${BOLD}🌐 Akses Server:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  Lokal      : ${GREEN}http://localhost:${SERVER_PORT}${NC}"
    echo -e "  LAN        : ${GREEN}http://${LOCAL_IP}:${SERVER_PORT}${NC}"
    if [[ "$PUBLIC_IP" != "tidak_tersedia" && "$PUBLIC_IP" != "" ]]; then
    echo -e "  Public     : ${GREEN}http://${PUBLIC_IP}:${SERVER_PORT}${NC}"
    fi
    echo ""
    echo -e "  ${BOLD}🔬 Endpoint API:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  Status     : ${CYAN}GET  http://localhost:${SERVER_PORT}/${NC}"
    echo -e "  Download   : ${CYAN}GET  http://localhost:${SERVER_PORT}/download${NC}"
    echo -e "  Upload     : ${CYAN}POST http://localhost:${SERVER_PORT}/upload${NC}"
    echo -e "  Ping       : ${CYAN}GET  http://localhost:${SERVER_PORT}/ping${NC}"
    echo ""
    echo -e "  ${BOLD}🛠️  Manajemen Service:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  Status  : ${YELLOW}systemctl status speedtest-server${NC}"
    echo -e "  Stop    : ${YELLOW}systemctl stop speedtest-server${NC}"
    echo -e "  Restart : ${YELLOW}systemctl restart speedtest-server${NC}"
    echo -e "  Log     : ${YELLOW}journalctl -u speedtest-server -f${NC}"
    echo ""
    echo -e "  ${BOLD}📋 Config File:${NC}  ${CYAN}/etc/speedtest/speedtest.env${NC}"
    echo ""
    echo -e "  ${BOLD}✨ Test Server:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  ${YELLOW}curl http://localhost:${SERVER_PORT}/${NC}"
    echo -e "  Output: ${GREEN}{\"status\":\"ready\",\"node\":\"${NODE_NAME}\",\"message\":\"SpeedTest API Server\"}${NC}"
    echo ""
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}Developed by BTD System - noc@btd.co.id - btd.co.id${NC}"
    echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ── MAIN ──────────────────────────────────────────────────────────────────────
main() {
    print_banner
    check_root
    detect_distro
    install_dependencies
    install_go
    get_server_config
    check_port
    build_binary
    install_service
    setup_firewall
    verify_server
    print_summary
}

main "$@"
