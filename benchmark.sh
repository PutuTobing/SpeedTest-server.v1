#!/bin/bash

# Benchmark script to test SpeedTest service performance
# Usage: ./benchmark.sh [host:port] [duration]

HOST="${1:-localhost:8080}"
DURATION="${2:-10}"
BASE_URL="http://${HOST}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   SpeedTest Benchmark Tool             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}Target: ${BASE_URL}${NC}"
echo -e "${YELLOW}Duration: ${DURATION}s${NC}"
echo ""

# Check if server is reachable
if ! curl -s --connect-timeout 5 "${BASE_URL}/" > /dev/null; then
    echo -e "${RED}Error: Cannot connect to ${BASE_URL}${NC}"
    exit 1
fi

# Test 1: Ping Latency
echo -e "${BLUE}[1/5] Testing Latency...${NC}"
LATENCY_SUM=0
LATENCY_COUNT=10

for i in $(seq 1 $LATENCY_COUNT); do
    LATENCY=$(curl -o /dev/null -s -w "%{time_total}" "${BASE_URL}/ping")
    LATENCY_SUM=$(echo "$LATENCY_SUM + $LATENCY" | bc)
done

AVG_LATENCY=$(echo "scale=4; $LATENCY_SUM / $LATENCY_COUNT" | bc)
AVG_LATENCY_MS=$(echo "scale=2; $AVG_LATENCY * 1000" | bc)
echo -e "${GREEN}✓ Average Latency: ${AVG_LATENCY_MS}ms${NC}"
echo ""

# Test 2: Single Connection Download Speed
echo -e "${BLUE}[2/5] Testing Single Connection Download...${NC}"
START=$(date +%s)
SIZE=$(curl -s "${BASE_URL}/download?duration=${DURATION}" -o /tmp/bench_single.bin -w "%{size_download}")
END=$(date +%s)
ACTUAL_DURATION=$((END - START))
if [ $ACTUAL_DURATION -eq 0 ]; then ACTUAL_DURATION=1; fi

SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
SPEED_MBPS=$(echo "scale=2; ($SIZE * 8) / ($ACTUAL_DURATION * 1000000)" | bc)
echo -e "${GREEN}✓ Single Connection: ${SPEED_MBPS} Mbps (${SIZE_MB} MB in ${ACTUAL_DURATION}s)${NC}"
rm -f /tmp/bench_single.bin
echo ""

# Test 3: Multiple Connections (4 streams)
echo -e "${BLUE}[3/5] Testing 4 Parallel Connections...${NC}"
START=$(date +%s)
for i in {1..4}; do
    curl -s "${BASE_URL}/download?duration=${DURATION}" -o /tmp/bench_multi_${i}.bin &
done
wait
END=$(date +%s)
ACTUAL_DURATION=$((END - START))
if [ $ACTUAL_DURATION -eq 0 ]; then ACTUAL_DURATION=1; fi

TOTAL_SIZE=$(du -sb /tmp/bench_multi_*.bin | awk '{sum+=$1} END {print sum}')
TOTAL_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)
TOTAL_SPEED=$(echo "scale=2; ($TOTAL_SIZE * 8) / ($ACTUAL_DURATION * 1000000)" | bc)
echo -e "${GREEN}✓ 4 Connections: ${TOTAL_SPEED} Mbps (${TOTAL_MB} MB in ${ACTUAL_DURATION}s)${NC}"
rm -f /tmp/bench_multi_*.bin
echo ""

# Test 4: Upload Speed
echo -e "${BLUE}[4/5] Testing Upload Speed (50MB)...${NC}"
UPLOAD_SIZE=50
START=$(date +%s)
RESPONSE=$(dd if=/dev/zero bs=1M count=${UPLOAD_SIZE} 2>/dev/null | curl -s -X POST "${BASE_URL}/upload" --data-binary @-)
END=$(date +%s)
ACTUAL_DURATION=$((END - START))
if [ $ACTUAL_DURATION -eq 0 ]; then ACTUAL_DURATION=1; fi

RECEIVED_SIZE=$(echo "$RESPONSE" | grep -o '"received":[0-9]*' | cut -d':' -f2)

if [ -n "$RECEIVED_SIZE" ] && [ "$RECEIVED_SIZE" -gt 0 ]; then
    RECEIVED_MB=$(echo "scale=2; $RECEIVED_SIZE / 1024 / 1024" | bc)
    UPLOAD_SPEED=$(echo "scale=2; ($RECEIVED_SIZE * 8) / ($ACTUAL_DURATION * 1000000)" | bc)
    echo -e "${GREEN}✓ Upload: ${UPLOAD_SPEED} Mbps (${RECEIVED_MB} MB in ${ACTUAL_DURATION}s)${NC}"
else
    echo -e "${YELLOW}⚠ Upload test failed or returned empty response${NC}"
fi
echo ""

# Test 5: Concurrent Requests (using ab if available)
echo -e "${BLUE}[5/5] Testing Request Handling...${NC}"

if command -v ab > /dev/null 2>&1; then
    AB_RESULT=$(ab -n 1000 -c 50 -q "${BASE_URL}/ping" 2>&1)
    REQUESTS_PER_SEC=$(echo "$AB_RESULT" | grep "Requests per second" | awk '{print $4}')
    
    if [ -n "$REQUESTS_PER_SEC" ]; then
        echo -e "${GREEN}✓ Requests/sec: ${REQUESTS_PER_SEC}${NC}"
    else
        echo -e "${YELLOW}⚠ Could not parse ab results${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Apache Bench (ab) not installed, skipping test${NC}"
    echo "  Install: sudo apt install apache2-utils"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Benchmark Summary              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo -e "Host:              ${HOST}"
echo -e "Avg Latency:       ${AVG_LATENCY_MS}ms"
echo -e "Single Download:   ${SPEED_MBPS} Mbps"
echo -e "4x Download:       ${TOTAL_SPEED} Mbps"
if [ -n "$UPLOAD_SPEED" ]; then
    echo -e "Upload:            ${UPLOAD_SPEED} Mbps"
fi
if [ -n "$REQUESTS_PER_SEC" ]; then
    echo -e "Requests/sec:      ${REQUESTS_PER_SEC}"
fi
echo ""

# Cleanup
rm -f /tmp/bench_*.bin

echo -e "${GREEN}Benchmark complete!${NC}"
