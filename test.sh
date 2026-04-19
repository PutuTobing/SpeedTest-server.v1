#!/bin/bash

# SpeedTest Service Testing Script
# Usage: ./test.sh [host:port]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default host
HOST="${1:-localhost:8080}"
BASE_URL="http://${HOST}"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   SpeedTest Service Testing Script    ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}Testing server: ${BASE_URL}${NC}"
echo ""

# Test 1: Root Endpoint
echo -e "${BLUE}[TEST 1]${NC} Testing Root Endpoint (GET /)..."
RESPONSE=$(curl -s -w "\n%{http_code}" "${BASE_URL}/")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" -eq 200 ] && [ "$BODY" == "Server Ready" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Response: ${BODY}"
else
    echo -e "${RED}✗ FAILED${NC} - HTTP Code: ${HTTP_CODE}, Response: ${BODY}"
fi
echo ""

# Test 2: Ping Endpoint
echo -e "${BLUE}[TEST 2]${NC} Testing Ping Endpoint (GET /ping)..."
START_TIME=$(date +%s%N)
RESPONSE=$(curl -s -w "\n%{http_code}" "${BASE_URL}/ping")
END_TIME=$(date +%s%N)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
LATENCY=$(( (END_TIME - START_TIME) / 1000000 ))

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Response: ${BODY}, Latency: ${LATENCY}ms"
else
    echo -e "${RED}✗ FAILED${NC} - HTTP Code: ${HTTP_CODE}"
fi
echo ""

# Test 3: Health Check
echo -e "${BLUE}[TEST 3]${NC} Testing Health Endpoint (GET /health)..."
RESPONSE=$(curl -s -w "\n%{http_code}" "${BASE_URL}/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Response: ${BODY}"
else
    echo -e "${RED}✗ FAILED${NC} - HTTP Code: ${HTTP_CODE}"
fi
echo ""

# Test 4: Download Speed Test (2 seconds)
echo -e "${BLUE}[TEST 4]${NC} Testing Download Endpoint (GET /download?duration=2)..."
echo -e "${YELLOW}Downloading for 2 seconds...${NC}"

START_TIME=$(date +%s)
SIZE=$(curl -s "${BASE_URL}/download?duration=2" -o /tmp/speedtest_download.bin -w "%{size_download}")
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ $DURATION -eq 0 ]; then
    DURATION=1
fi

SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc)
SPEED_MBPS=$(echo "scale=2; ($SIZE * 8) / ($DURATION * 1000000)" | bc)

if [ $SIZE -gt 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Downloaded: ${SIZE_MB} MB in ${DURATION}s (${SPEED_MBPS} Mbps)"
else
    echo -e "${RED}✗ FAILED${NC} - No data received"
fi
rm -f /tmp/speedtest_download.bin
echo ""

# Test 5: Upload Speed Test (5MB)
echo -e "${BLUE}[TEST 5]${NC} Testing Upload Endpoint (POST /upload)..."
echo -e "${YELLOW}Uploading 5MB random data...${NC}"

START_TIME=$(date +%s)
RESPONSE=$(dd if=/dev/urandom bs=1M count=5 2>/dev/null | curl -s -X POST "${BASE_URL}/upload" --data-binary @- -w "\n%{http_code}")
END_TIME=$(date +%s)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)
DURATION=$((END_TIME - START_TIME))

if [ $DURATION -eq 0 ]; then
    DURATION=1
fi

SIZE_MB=5
SPEED_MBPS=$(echo "scale=2; ($SIZE_MB * 8) / $DURATION" | bc)

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Uploaded: ${SIZE_MB} MB in ${DURATION}s (${SPEED_MBPS} Mbps)"
    echo -e "  Server Response: ${BODY}"
else
    echo -e "${RED}✗ FAILED${NC} - HTTP Code: ${HTTP_CODE}"
fi
echo ""

# Test 6: Concurrent Download Test
echo -e "${BLUE}[TEST 6]${NC} Testing Concurrent Downloads (5 parallel connections)..."
echo -e "${YELLOW}Running 5 parallel downloads for 2 seconds each...${NC}"

for i in {1..5}; do
    curl -s "${BASE_URL}/download?duration=2" -o /tmp/speedtest_concurrent_${i}.bin &
done

wait

TOTAL_SIZE=0
for i in {1..5}; do
    if [ -f /tmp/speedtest_concurrent_${i}.bin ]; then
        FILE_SIZE=$(stat -f%z /tmp/speedtest_concurrent_${i}.bin 2>/dev/null || stat -c%s /tmp/speedtest_concurrent_${i}.bin 2>/dev/null)
        TOTAL_SIZE=$((TOTAL_SIZE + FILE_SIZE))
        rm -f /tmp/speedtest_concurrent_${i}.bin
    fi
done

TOTAL_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)

if [ $TOTAL_SIZE -gt 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Total downloaded: ${TOTAL_MB} MB across 5 connections"
else
    echo -e "${RED}✗ FAILED${NC} - Concurrent test failed"
fi
echo ""

# Summary
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Testing Complete!              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}All basic functionality tests completed.${NC}"
echo -e "${YELLOW}For production load testing, use tools like:${NC}"
echo -e "  - ab (Apache Bench)"
echo -e "  - wrk"
echo -e "  - hey"
echo ""
