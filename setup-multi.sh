#!/bin/bash

# Multi-instance setup script
# This script helps setup multiple SpeedTest instances on one server

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Multi-Instance Setup Script         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Please run as root or with sudo${NC}"
    exit 1
fi

# Build binary if not exists
if [ ! -f "speedtest" ]; then
    echo "Building binary..."
    go build -ldflags="-s -w" -o speedtest main.go
fi

# Install binary
echo "Installing binary to /usr/local/bin..."
cp speedtest /usr/local/bin/
chmod +x /usr/local/bin/speedtest

# Create user
echo "Creating speedtest user..."
useradd -r -s /bin/false speedtest 2>/dev/null || echo "User already exists"

# Create config directory
mkdir -p /etc/speedtest

# Copy template service
echo "Installing systemd template..."
cp speedtest@.service /etc/systemd/system/

# Ask for number of instances
read -p "How many instances to setup? (default: 3): " NUM_INSTANCES
NUM_INSTANCES=${NUM_INSTANCES:-3}

# Setup each instance
for i in $(seq 1 $NUM_INSTANCES); do
    echo ""
    echo -e "${YELLOW}Configuring instance ${i}...${NC}"
    
    # Default values
    DEFAULT_PORT=$((8080 + i - 1))
    
    read -p "  Instance ${i} - Bind IP (default: 0.0.0.0): " BIND_IP
    BIND_IP=${BIND_IP:-0.0.0.0}
    
    read -p "  Instance ${i} - Port (default: ${DEFAULT_PORT}): " PORT
    PORT=${PORT:-$DEFAULT_PORT}
    
    read -p "  Instance ${i} - Node Name (default: SpeedTest-${i}): " NODE_NAME
    NODE_NAME=${NODE_NAME:-SpeedTest-${i}}
    
    # Create config file
    cat > /etc/speedtest/speedtest-${i}.env << EOF
PORT=${PORT}
BIND_IP=${BIND_IP}
NODE_NAME=${NODE_NAME}
BUFFER_SIZE=1048576
TIMEOUT=30s
EOF
    
    echo -e "${GREEN}  ✓ Instance ${i} configured${NC}"
done

# Reload systemd
echo ""
echo "Reloading systemd..."
systemctl daemon-reload

# Enable and start instances
echo ""
echo "Enabling and starting instances..."
for i in $(seq 1 $NUM_INSTANCES); do
    systemctl enable speedtest@${i}
    systemctl start speedtest@${i}
    echo -e "${GREEN}✓ Instance ${i} started${NC}"
done

# Show status
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║      Setup Complete!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Instance Status:"
for i in $(seq 1 $NUM_INSTANCES); do
    if systemctl is-active --quiet speedtest@${i}; then
        CONFIG=$(grep -E 'BIND_IP|PORT|NODE_NAME' /etc/speedtest/speedtest-${i}.env | tr '\n' ' ')
        echo -e "  ${GREEN}✓${NC} Instance ${i}: ${CONFIG}"
    else
        echo -e "  ${YELLOW}✗${NC} Instance ${i}: Not running"
    fi
done

echo ""
echo "Management commands:"
echo "  Check status: systemctl status speedtest@<N>"
echo "  View logs:    journalctl -u speedtest@<N> -f"
echo "  Restart:      systemctl restart speedtest@<N>"
echo "  Stop all:     systemctl stop speedtest@{1..${NUM_INSTANCES}}"
echo ""
