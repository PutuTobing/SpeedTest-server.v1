#!/bin/bash
# =============================================================================
#  SpeedTest Server - Docker Auto Installer
#  SKY BASE TECHNOLOGY DIGITAL (BTD)
#  Version: 1.1.0
#
#  Cara pakai / Usage:
#    curl -fsSL https://raw.githubusercontent.com/PutuTobing/SpeedTest-server.v1/main/install-docker.sh | sudo bash
#
#  atau / or:
#    sudo bash install-docker.sh
# =============================================================================

set -euo pipefail

# ── Konstanta ─────────────────────────────────────────────────────────────────
DOCKER_IMAGE="pututobing/speedtest-server"
IMAGE_TAG="latest"
CONTAINER_NAME="speedtest-server"
DEFAULT_PORT="8080"

# ── Warna Terminal ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║       SKY TECH - SpeedTest Server (Docker)           ║"
    echo "  ║       PT SKY BASE TECHNOLOGY DIGITAL (BTD)           ║"
    echo "  ║              Docker Installer v1.1.0                 ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step()  { echo -e "\n${BLUE}${BOLD}[STEP]${NC} ${WHITE}$1${NC}"; }
print_ok()    { echo -e "  ${GREEN}✔${NC}  $1"; }
print_warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
print_error() { echo -e "  ${RED}✘${NC}  $1" >&2; }
print_info()  { echo -e "  ${CYAN}ℹ${NC}  $1"; }

# ── Cek Root ──────────────────────────────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini harus dijalankan sebagai root."
        echo -e "  Gunakan: ${YELLOW}sudo bash install-docker.sh${NC}"
        exit 1
    fi
}

# ── Deteksi Distro ────────────────────────────────────────────────────────────
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${ID:-unknown}"
    else
        DISTRO="unknown"
    fi
}

# ── Install Docker ────────────────────────────────────────────────────────────
install_docker() {
    print_step "Memeriksa instalasi Docker..."

    if command -v docker &>/dev/null; then
        DOCKER_VER=$(docker --version | grep -oP '\d+\.\d+' | head -1)
        print_ok "Docker sudah terinstal: $(docker --version | awk '{print $3}' | tr -d ',')"
        return 0
    fi

    print_info "Docker tidak ditemukan. Menginstal Docker secara otomatis..."

    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop|raspbian)
            print_info "Menggunakan metode install resmi Docker untuk Debian/Ubuntu..."
            apt-get update -qq
            apt-get install -y -qq ca-certificates curl gnupg lsb-release

            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/${DISTRO}/gpg \
                | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
            chmod a+r /etc/apt/keyrings/docker.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/${DISTRO} $(lsb_release -cs) stable" \
                | tee /etc/apt/sources.list.d/docker.list > /dev/null

            apt-get update -qq
            apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        centos|rhel|fedora|rocky|almalinux)
            print_info "Menggunakan metode install resmi Docker untuk RHEL/CentOS..."
            if command -v dnf &>/dev/null; then
                dnf install -y -q dnf-plugins-core
                dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                dnf install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            else
                yum install -y -q yum-utils
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                yum install -y -q docker-ce docker-ce-cli containerd.io
            fi
            ;;

        arch|manjaro)
            pacman -Sy --noconfirm docker
            ;;

        *)
            print_info "Menggunakan convenience script dari get.docker.com..."
            curl -fsSL https://get.docker.com | sh
            ;;
    esac

    # Aktifkan dan start Docker
    systemctl enable docker --quiet
    systemctl start docker

    # Tunggu Docker daemon siap
    local retry=0
    while ! docker info &>/dev/null; do
        sleep 1
        retry=$((retry + 1))
        if [ $retry -ge 15 ]; then
            print_error "Docker daemon tidak bisa start. Periksa log: journalctl -u docker"
            exit 1
        fi
    done

    print_ok "Docker berhasil diinstal: $(docker --version | awk '{print $3}' | tr -d ',')"
}

# ── Input Konfigurasi ─────────────────────────────────────────────────────────
get_config() {
    print_step "Konfigurasi SpeedTest Server"
    echo ""

    # Port
    echo -e "  ${WHITE}🔌 Port Server${NC}"
    echo -e "  ${YELLOW}Default: 8080${NC}"
    read -rp "  Port [Enter untuk 8080]: " INPUT_PORT
    SERVER_PORT="${INPUT_PORT:-8080}"

    if ! [[ "$SERVER_PORT" =~ ^[0-9]+$ ]] || [ "$SERVER_PORT" -lt 1 ] || [ "$SERVER_PORT" -gt 65535 ]; then
        print_warn "Port tidak valid, menggunakan 8080"
        SERVER_PORT="8080"
    fi
    echo ""

    # Lokasi
    echo -e "  ${WHITE}📍 Lokasi Server${NC}"
    echo -e "  ${YELLOW}Contoh: Lampung, Jakarta, Bandung${NC}"
    read -rp "  Lokasi: " INPUT_LOCATION
    SERVER_LOCATION="${INPUT_LOCATION:-Server Tidak Diketahui}"
    echo ""

    # Nama Node
    echo -e "  ${WHITE}🏷️  Nama Node${NC}"
    echo -e "  ${YELLOW}Contoh: SpeedTest-Lampung-BTD${NC}"
    read -rp "  Nama Node [Enter untuk SpeedTest-${SERVER_LOCATION}]: " INPUT_NODE
    NODE_NAME="${INPUT_NODE:-SpeedTest-${SERVER_LOCATION}}"
    echo ""

    # Konfirmasi
    echo -e "  ┌─────────────────────────────────────────────────┐"
    echo -e "  │  ${BOLD}Ringkasan Konfigurasi${NC}                           │"
    echo -e "  ├─────────────────────────────────────────────────┤"
    echo -e "  │  Image      : ${CYAN}${DOCKER_IMAGE}:${IMAGE_TAG}${NC}"
    echo -e "  │  Container  : ${CYAN}${CONTAINER_NAME}${NC}"
    echo -e "  │  Port       : ${CYAN}${SERVER_PORT}${NC}"
    echo -e "  │  Lokasi     : ${CYAN}${SERVER_LOCATION}${NC}"
    echo -e "  │  Node Name  : ${CYAN}${NODE_NAME}${NC}"
    echo -e "  └─────────────────────────────────────────────────┘"
    echo ""
    read -rp "  Lanjutkan instalasi? [Y/n]: " CONFIRM
    CONFIRM="${CONFIRM:-Y}"

    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "\n  ${YELLOW}Instalasi dibatalkan.${NC}"
        exit 0
    fi
}

# ── Cek Port Tersedia ─────────────────────────────────────────────────────────
check_port() {
    if command -v ss &>/dev/null && ss -tlnp 2>/dev/null | grep -q ":${SERVER_PORT} "; then
        print_warn "Port ${SERVER_PORT} sedang digunakan oleh proses lain!"
        ss -tlnp | grep ":${SERVER_PORT} " || true
        echo ""
        read -rp "  Lanjutkan? [y/N]: " CONT
        if [[ ! "${CONT:-N}" =~ ^[Yy]$ ]]; then
            echo -e "\n  ${YELLOW}Dibatalkan. Ubah port dan coba lagi.${NC}"
            exit 1
        fi
    fi
}

# ── Hapus Container Lama ──────────────────────────────────────────────────────
remove_old_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_info "Menghapus container lama: ${CONTAINER_NAME}..."
        docker stop "${CONTAINER_NAME}" &>/dev/null || true
        docker rm "${CONTAINER_NAME}" &>/dev/null || true
        print_ok "Container lama dihapus"
    fi
}

# ── Pull Image ────────────────────────────────────────────────────────────────
pull_image() {
    print_step "Mengunduh image Docker..."
    echo -e "  ${CYAN}↓${NC}  ${DOCKER_IMAGE}:${IMAGE_TAG}"
    echo ""

    if docker pull "${DOCKER_IMAGE}:${IMAGE_TAG}"; then
        print_ok "Image berhasil diunduh"
    else
        print_error "Gagal mengunduh image. Periksa koneksi internet atau nama image."
        exit 1
    fi
}

# ── Jalankan Container ────────────────────────────────────────────────────────
run_container() {
    print_step "Menjalankan container SpeedTest Server..."

    docker run -d \
        --name "${CONTAINER_NAME}" \
        --restart unless-stopped \
        -p "${SERVER_PORT}:8080" \
        -e NODE_NAME="${NODE_NAME}" \
        -e LOCATION="${SERVER_LOCATION}" \
        -e PORT=8080 \
        -e BIND_IP=0.0.0.0 \
        -e BUFFER_SIZE=4194304 \
        -e TIMEOUT=30s \
        "${DOCKER_IMAGE}:${IMAGE_TAG}" > /dev/null

    print_ok "Container berjalan: ${CONTAINER_NAME}"
}

# ── Setup Firewall ────────────────────────────────────────────────────────────
setup_firewall() {
    print_step "Mengonfigurasi firewall untuk port ${SERVER_PORT}..."

    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
        ufw allow "${SERVER_PORT}/tcp" > /dev/null 2>&1
        print_ok "UFW: allow ${SERVER_PORT}/tcp"

    elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        firewall-cmd --permanent --add-port="${SERVER_PORT}/tcp" > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
        print_ok "firewalld: allow ${SERVER_PORT}/tcp"

    else
        print_warn "Firewall tidak terdeteksi. Pastikan port ${SERVER_PORT} terbuka secara manual."
    fi
}

# ── Verifikasi ────────────────────────────────────────────────────────────────
verify_server() {
    print_step "Memverifikasi server berjalan..."

    echo -ne "  ${CYAN}⌛${NC}  Menunggu server siap"
    local retry=0

    while [ $retry -lt 20 ]; do
        if curl -s --max-time 2 "http://127.0.0.1:${SERVER_PORT}/" > /tmp/st_check.json 2>/dev/null; then
            echo -e " ${GREEN}✔${NC}"
            print_ok "Response: $(cat /tmp/st_check.json)"
            return 0
        fi
        echo -ne "."
        sleep 1
        retry=$((retry + 1))
    done

    echo -e " ${YELLOW}timeout${NC}"
    print_warn "Server belum merespons. Cek log: docker logs ${CONTAINER_NAME}"
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
    local LOCAL_IP
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    local PUBLIC_IP
    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "")

    echo ""
    echo -e "${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║                                                          ║"
    echo "  ║   ✅  INSTALASI BERHASIL! SERVER RUNNING               ║"
    echo "  ║                                                          ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${BOLD}📦 Docker Info:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  Image      : ${CYAN}${DOCKER_IMAGE}:${IMAGE_TAG}${NC}"
    echo -e "  Container  : ${CYAN}${CONTAINER_NAME}${NC}"
    echo ""
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
    [[ -n "$PUBLIC_IP" ]] && echo -e "  Public     : ${GREEN}http://${PUBLIC_IP}:${SERVER_PORT}${NC}"
    echo ""
    echo -e "  ${BOLD}🔬 Endpoint API:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  Status     : ${CYAN}GET  http://localhost:${SERVER_PORT}/${NC}"
    echo -e "  Download   : ${CYAN}GET  http://localhost:${SERVER_PORT}/download${NC}"
    echo -e "  Upload     : ${CYAN}POST http://localhost:${SERVER_PORT}/upload${NC}"
    echo -e "  Ping       : ${CYAN}GET  http://localhost:${SERVER_PORT}/ping${NC}"
    echo ""
    echo -e "  ${BOLD}🛠️  Manajemen Container:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  Status  : ${YELLOW}docker ps | grep ${CONTAINER_NAME}${NC}"
    echo -e "  Stop    : ${YELLOW}docker stop ${CONTAINER_NAME}${NC}"
    echo -e "  Restart : ${YELLOW}docker restart ${CONTAINER_NAME}${NC}"
    echo -e "  Log     : ${YELLOW}docker logs -f ${CONTAINER_NAME}${NC}"
    echo -e "  Update  : ${YELLOW}docker pull ${DOCKER_IMAGE}:${IMAGE_TAG} && docker restart ${CONTAINER_NAME}${NC}"
    echo ""
    echo -e "  ${BOLD}✨ Test Server:${NC}"
    echo -e "  ─────────────────────────────────────────────────────────"
    echo -e "  ${YELLOW}curl http://localhost:${SERVER_PORT}/${NC}"
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
    install_docker
    get_config
    check_port
    remove_old_container
    pull_image
    run_container
    setup_firewall
    verify_server
    print_summary
}

main "$@"
