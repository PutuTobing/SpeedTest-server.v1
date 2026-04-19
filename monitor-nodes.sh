#!/bin/bash

# Monitor multiple SpeedTest nodes
# Usage: ./monitor-nodes.sh [nodes-file]

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default nodes file
NODES_FILE="${1:-nodes.txt}"

# Check if nodes file exists
if [ ! -f "$NODES_FILE" ]; then
    echo -e "${RED}Error: Nodes file '$NODES_FILE' not found${NC}"
    echo ""
    echo "Create a nodes.txt file with format:"
    echo "  hostname_or_ip:port,node_name"
    echo ""
    echo "Example:"
    echo "  103.254.100.1:8080,Jakarta-Node"
    echo "  103.254.100.2:8080,Lampung-Node"
    echo "  speedtest3.btd.co.id:8080,Bandung-Node"
    exit 1
fi

# Function to check node
check_node() {
    local node=$1
    local name=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if reachable
    if ! curl -s --connect-timeout 5 "http://${node}/" > /dev/null 2>&1; then
        echo -e "${RED}[${timestamp}] ${name} (${node}) - OFFLINE${NC}"
        return 1
    fi
    
    # Get health info
    HEALTH=$(curl -s --max-time 5 "http://${node}/health" 2>/dev/null)
    
    if [ -z "$HEALTH" ]; then
        echo -e "${YELLOW}[${timestamp}] ${name} (${node}) - DEGRADED (no health data)${NC}"
        return 1
    fi
    
    # Parse health info
    STATUS=$(echo "$HEALTH" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    NODE_NAME=$(echo "$HEALTH" | grep -o '"node":"[^"]*"' | cut -d'"' -f4)
    
    # Check ping latency
    LATENCY=$(curl -o /dev/null -s -w "%{time_total}" --max-time 5 "http://${node}/ping" 2>/dev/null)
    
    if [ "$STATUS" == "healthy" ]; then
        echo -e "${GREEN}[${timestamp}] ${name} (${node}) - OK${NC} | Latency: ${LATENCY}s | Node: ${NODE_NAME}"
        return 0
    else
        echo -e "${YELLOW}[${timestamp}] ${name} (${node}) - UNHEALTHY${NC}"
        return 1
    fi
}

# Function to run monitoring loop
monitor_loop() {
    local interval=${1:-60}
    
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   SpeedTest Nodes Monitor             ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -e "${YELLOW}Monitoring interval: ${interval} seconds${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""
    
    while true; do
        echo -e "${BLUE}--- Checking all nodes ---${NC}"
        
        total=0
        online=0
        
        while IFS=',' read -r node name; do
            # Skip empty lines and comments
            [[ -z "$node" || "$node" =~ ^# ]] && continue
            
            total=$((total + 1))
            
            if check_node "$node" "$name"; then
                online=$((online + 1))
            fi
        done < "$NODES_FILE"
        
        echo ""
        echo -e "${BLUE}Summary: ${online}/${total} nodes online${NC}"
        echo ""
        
        sleep "$interval"
    done
}

# Function for one-time check
check_once() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   SpeedTest Nodes Status Check        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    total=0
    online=0
    
    while IFS=',' read -r node name; do
        # Skip empty lines and comments
        [[ -z "$node" || "$node" =~ ^# ]] && continue
        
        total=$((total + 1))
        
        if check_node "$node" "$name"; then
            online=$((online + 1))
        fi
    done < "$NODES_FILE"
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    if [ $online -eq $total ]; then
        echo -e "${GREEN}✓ All nodes online (${online}/${total})${NC}"
        exit 0
    elif [ $online -eq 0 ]; then
        echo -e "${RED}✗ All nodes offline (0/${total})${NC}"
        exit 2
    else
        echo -e "${YELLOW}⚠ Some nodes offline (${online}/${total})${NC}"
        exit 1
    fi
}

# Main
case "${2}" in
    "loop"|"monitor")
        INTERVAL="${3:-60}"
        monitor_loop "$INTERVAL"
        ;;
    "once"|"check"|"")
        check_once
        ;;
    *)
        echo "Usage: $0 [nodes-file] [mode] [interval]"
        echo ""
        echo "Modes:"
        echo "  once    - Check all nodes once (default)"
        echo "  loop    - Continuous monitoring"
        echo ""
        echo "Examples:"
        echo "  $0 nodes.txt once         # Check once"
        echo "  $0 nodes.txt loop 30      # Monitor every 30 seconds"
        exit 1
        ;;
esac
