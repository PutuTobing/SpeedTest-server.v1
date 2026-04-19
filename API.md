# 📡 API Documentation

Complete API reference untuk SpeedTest Service.

## Base URL

```
http://<server-ip>:8080
```

---

## Endpoints

### 1. Root / Health Check

**Endpoint:** `GET /`

**Description:** Basic health check endpoint untuk verifikasi server berjalan.

**Request:**
```bash
curl http://localhost:8080/
```

**Response:**
```
Server Ready
```

**Headers:**
```
X-Node-Name: SpeedTest-Jakarta
Server: SpeedTest-Go
```

**Status Codes:**
- `200 OK` - Service running normally

---

### 2. Ping Test

**Endpoint:** `GET /ping`

**Description:** Minimal latency endpoint untuk mengukur ping time / network latency.

**Request:**
```bash
curl http://localhost:8080/ping
```

**Response:**
```
pong
```

**Headers:**
```
X-Node-Name: SpeedTest-Jakarta
Cache-Control: no-cache, no-store, must-revalidate
Content-Type: text/plain
```

**Status Codes:**
- `200 OK` - Success

**Example with timing:**
```bash
curl -w "\nTime: %{time_total}s\n" http://localhost:8080/ping
```

---

### 3. Download Speed Test

**Endpoint:** `GET /download`

**Description:** Download speed test endpoint yang mengirim random data stream.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `duration` | integer | No | 10 | Test duration in seconds (max: 60) |
| `size` | integer | No | - | Data size in MB (if set, overrides duration) |

**Request Examples:**

```bash
# Default (10 seconds)
curl http://localhost:8080/download -o /dev/null

# Custom duration (5 seconds)
curl http://localhost:8080/download?duration=5 -o /dev/null

# Fixed size (100 MB)
curl http://localhost:8080/download?size=100 -o /dev/null

# With speed measurement
curl http://localhost:8080/download?duration=10 -o /dev/null -w "Speed: %{speed_download} bytes/sec\n"
```

**Response:**
- Binary data stream (application/octet-stream)
- Data generated in-memory (not from disk)
- Continuously sent until duration/size limit reached

**Headers:**
```
X-Node-Name: SpeedTest-Jakarta
Content-Type: application/octet-stream
Cache-Control: no-cache, no-store, must-revalidate
Connection: keep-alive
```

**Status Codes:**
- `200 OK` - Data streaming

**Performance Tips:**
- Use multiple parallel connections for higher throughput
- Adjust duration based on network speed
- Use `size` parameter for consistent test size

---

### 4. Upload Speed Test

**Endpoint:** `POST /upload`

**Description:** Upload speed test endpoint yang menerima data dari client.

**Request:**

```bash
# Upload random data (10 MB)
dd if=/dev/urandom bs=1M count=10 | curl -X POST http://localhost:8080/upload --data-binary @-

# Upload from file
curl -X POST http://localhost:8080/upload --data-binary @largefile.bin

# Upload with size measurement
curl -X POST http://localhost:8080/upload --data-binary @- -w "Uploaded: %{size_upload} bytes\n" < /dev/zero
```

**Request Body:**
- Binary data (any format)
- No size limit enforced by application (limited by server timeout only)

**Response:**
```json
{
  "received": 10485760,
  "status": "ok"
}
```

**Response Fields:**
- `received` (integer): Total bytes received
- `status` (string): "ok" if successful

**Headers:**
```
X-Node-Name: SpeedTest-Jakarta
Content-Type: application/json
Cache-Control: no-cache, no-store, must-revalidate
```

**Status Codes:**
- `200 OK` - Upload successful
- `405 Method Not Allowed` - Wrong HTTP method (must be POST)
- `500 Internal Server Error` - Server error

---

### 5. Health Check (Detailed)

**Endpoint:** `GET /health`

**Description:** Detailed health check dengan informasi node.

**Request:**
```bash
curl http://localhost:8080/health
```

**Response:**
```json
{
  "status": "healthy",
  "node": "SpeedTest-Jakarta",
  "timestamp": "2026-04-16T10:30:45Z"
}
```

**Response Fields:**
- `status` (string): "healthy" if service is running
- `node` (string): Node name/identifier
- `timestamp` (string): Current server time (RFC3339 format)

**Status Codes:**
- `200 OK` - Service healthy

**Use Cases:**
- Load balancer health checks
- Monitoring systems
- Uptime monitoring

---

## Response Headers

All endpoints include these standard headers:

```
X-Node-Name: <configured-node-name>
Server: SpeedTest-Go
```

---

## Rate Limiting

**Current Implementation:**
- No rate limiting implemented
- Suitable for internal networks or controlled access

**Recommendation:**
- Use reverse proxy (Nginx) for rate limiting in public deployments
- Use firewall rules to limit connections per IP

---

## CORS

**Current Implementation:**
- CORS not configured
- Same-origin policy applies

**To Enable CORS:**
Not currently supported in the application. Use reverse proxy if needed.

---

## Authentication

**Current Implementation:**
- No authentication implemented
- Suitable for internal networks

**Security Recommendations:**
- Use network-level security (firewall, IP whitelisting)
- Deploy behind reverse proxy with authentication
- Use VPN for access control

---

## Usage Examples

### Basic Speed Test

```bash
#!/bin/bash

# Test download speed
echo "Testing download speed..."
DOWNLOAD_SIZE=$(curl -s http://localhost:8080/download?duration=10 -o /tmp/test.bin -w "%{size_download}")
DOWNLOAD_SPEED=$(echo "scale=2; $DOWNLOAD_SIZE * 8 / 10 / 1000000" | bc)
echo "Download: ${DOWNLOAD_SPEED} Mbps"
rm /tmp/test.bin

# Test upload speed
echo "Testing upload speed..."
START=$(date +%s)
UPLOAD_RESPONSE=$(dd if=/dev/zero bs=1M count=50 2>/dev/null | curl -s -X POST http://localhost:8080/upload --data-binary @-)
END=$(date +%s)
DURATION=$((END - START))
UPLOAD_SIZE=$(echo $UPLOAD_RESPONSE | jq -r '.received')
UPLOAD_SPEED=$(echo "scale=2; $UPLOAD_SIZE * 8 / $DURATION / 1000000" | bc)
echo "Upload: ${UPLOAD_SPEED} Mbps"

# Test latency
echo "Testing latency..."
for i in {1..5}; do
    curl -o /dev/null -s -w "Ping $i: %{time_total}s\n" http://localhost:8080/ping
done
```

### Multi-Server Test

```bash
#!/bin/bash

SERVERS=(
    "speedtest1.btd.co.id"
    "speedtest2.btd.co.id"
    "speedtest3.btd.co.id"
)

echo "Testing all servers..."
for server in "${SERVERS[@]}"; do
    echo ""
    echo "Server: $server"
    
    # Get node info
    NODE_INFO=$(curl -s http://${server}:8080/health)
    echo "Node: $NODE_INFO"
    
    # Test latency
    LATENCY=$(curl -o /dev/null -s -w "%{time_total}" http://${server}:8080/ping)
    echo "Latency: ${LATENCY}s"
    
    # Quick download test (2 seconds)
    SIZE=$(curl -s http://${server}:8080/download?duration=2 -o /dev/null -w "%{size_download}")
    SPEED=$(echo "scale=2; $SIZE * 8 / 2 / 1000000" | bc)
    echo "Speed: ${SPEED} Mbps"
done
```

### Monitoring Script

```bash
#!/bin/bash

# Continuous monitoring
while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check health
    HEALTH=$(curl -s http://localhost:8080/health)
    STATUS=$(echo $HEALTH | jq -r '.status')
    
    # Check latency
    LATENCY=$(curl -o /dev/null -s -w "%{time_total}" http://localhost:8080/ping)
    
    echo "[$TIMESTAMP] Status: $STATUS, Latency: ${LATENCY}s"
    
    sleep 60
done
```

---

## Error Handling

### Common Errors

**Connection Refused:**
```bash
curl: (7) Failed to connect to localhost port 8080: Connection refused
```
- **Cause:** Service not running
- **Solution:** Start the service: `systemctl start speedtest`

**Timeout:**
```bash
curl: (28) Operation timed out after 30000 milliseconds
```
- **Cause:** Network issue or server overloaded
- **Solution:** Check network connectivity and server load

**Empty Response:**
```bash
curl: (52) Empty reply from server
```
- **Cause:** Service crashed or restarting
- **Solution:** Check logs: `journalctl -u speedtest -n 50`

---

## Client Libraries

### cURL (Bash)
```bash
# Download test
curl -o /dev/null http://localhost:8080/download?duration=10

# Upload test
dd if=/dev/zero bs=1M count=100 | curl -X POST http://localhost:8080/upload --data-binary @-
```

### Python
```python
import requests
import time

# Download test
start = time.time()
r = requests.get('http://localhost:8080/download?duration=10', stream=True)
size = 0
for chunk in r.iter_content(chunk_size=8192):
    size += len(chunk)
duration = time.time() - start
speed = (size * 8) / duration / 1000000
print(f"Download: {speed:.2f} Mbps")

# Upload test
import io
data = io.BytesIO(b'0' * 10485760)  # 10 MB
start = time.time()
r = requests.post('http://localhost:8080/upload', data=data)
duration = time.time() - start
speed = (10 * 8) / duration
print(f"Upload: {speed:.2f} Mbps")
```

### JavaScript (Node.js)
```javascript
const http = require('http');

// Ping test
http.get('http://localhost:8080/ping', (res) => {
  console.log('Ping:', res.statusCode);
  res.on('data', (chunk) => {
    console.log('Response:', chunk.toString());
  });
});

// Download test
const start = Date.now();
let size = 0;
http.get('http://localhost:8080/download?duration=5', (res) => {
  res.on('data', (chunk) => {
    size += chunk.length;
  });
  res.on('end', () => {
    const duration = (Date.now() - start) / 1000;
    const speed = (size * 8) / duration / 1000000;
    console.log(`Download: ${speed.toFixed(2)} Mbps`);
  });
});
```

---

## Best Practices

1. **Use Keep-Alive:** Enable HTTP keep-alive for better performance
2. **Parallel Connections:** Use 4-8 parallel connections for accurate throughput
3. **Buffer Size:** Use large read/write buffers (128KB+) in client
4. **Test Duration:** Minimum 5-10 seconds for accurate results
5. **Server Selection:** Test to multiple servers and pick the best
6. **Error Handling:** Always implement timeout and retry logic

---

## API Versioning

**Current Version:** v1 (implicit)

No version prefix in URLs. Future versions may introduce `/v2/` prefix.

---

## Changelog

- **v1.0.0** - Initial release
  - Basic endpoints (/, /ping, /download, /upload)
  - Health check endpoint
  - Node identification

---

Need help? Check the [README.md](README.md) or create an issue! 🚀
