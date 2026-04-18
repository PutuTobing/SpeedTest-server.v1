package main

import (
"crypto/rand"
"fmt"
"io"
"log"
"net/http"
"os"
"runtime"
"strconv"
"sync"
"time"
)

// Config holds the application configuration
type Config struct {
Port       string
BindIP     string
NodeName   string
BufferSize int
Timeout    time.Duration
}

var (
config     Config
bufferPool sync.Pool
)

func init() {
// Set GOMAXPROCS to use all available CPU cores
runtime.GOMAXPROCS(runtime.NumCPU())

// Initialize buffer pool for memory efficiency
bufferPool = sync.Pool{
New: func() interface{} {
buffer := make([]byte, config.BufferSize)
// Pre-fill with random data
rand.Read(buffer)
return &buffer
},
}
}

// loadConfig loads configuration from environment variables
func loadConfig() Config {
port := getEnv("PORT", "8080")
bindIP := getEnv("BIND_IP", "0.0.0.0")
nodeName := getEnv("NODE_NAME", "SpeedTest Node")
bufferSize, _ := strconv.Atoi(getEnv("BUFFER_SIZE", "1048576")) // 1MB default
timeout, _ := time.ParseDuration(getEnv("TIMEOUT", "30s"))

return Config{
Port:       port,
BindIP:     bindIP,
NodeName:   nodeName,
BufferSize: bufferSize,
Timeout:    timeout,
}
}

func getEnv(key, defaultValue string) string {
if value := os.Getenv(key); value != "" {
return value
}
return defaultValue
}

// rootHandler handles the root endpoint - API only
func rootHandler(w http.ResponseWriter, r *http.Request) {
w.Header().Set("X-Node-Name", config.NodeName)
w.Header().Set("Server", "SpeedTest-Go-API")
w.Header().Set("Content-Type", "application/json")
w.WriteHeader(http.StatusOK)
fmt.Fprintf(w, `{"status":"ready","node":"%s","message":"SpeedTest API Server"}`, config.NodeName)
}

// corsMiddleware adds CORS headers for cross-origin requests
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
return func(w http.ResponseWriter, r *http.Request) {
w.Header().Set("Access-Control-Allow-Origin", "*")
w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

if r.Method == "OPTIONS" {
w.WriteHeader(http.StatusOK)
return
}

next(w, r)
}
}

// pingHandler handles ping requests for latency measurement
func pingHandler(w http.ResponseWriter, r *http.Request) {
w.Header().Set("X-Node-Name", config.NodeName)
w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
w.Header().Set("Content-Type", "text/plain")
w.WriteHeader(http.StatusOK)
fmt.Fprint(w, "pong")
}

// downloadHandler streams random data to client for download speed test
func downloadHandler(w http.ResponseWriter, r *http.Request) {
w.Header().Set("X-Node-Name", config.NodeName)
w.Header().Set("Content-Type", "application/octet-stream")
w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
w.Header().Set("Connection", "keep-alive")

// Parse duration from query parameter (default 10 seconds)
durationStr := r.URL.Query().Get("duration")
duration := 10 * time.Second
if durationStr != "" {
if d, err := strconv.Atoi(durationStr); err == nil && d > 0 && d <= 60 {
duration = time.Duration(d) * time.Second
}
}

// Parse size from query parameter (in MB)
sizeStr := r.URL.Query().Get("size")
var totalSize int64 = 0
if sizeStr != "" {
if s, err := strconv.ParseInt(sizeStr, 10, 64); err == nil && s > 0 {
totalSize = s * 1024 * 1024 // Convert MB to bytes
}
}

// Create a timeout context
timeout := time.After(duration)

// Get buffer from pool
bufferPtr := bufferPool.Get().(*[]byte)
defer bufferPool.Put(bufferPtr)
buffer := *bufferPtr

var written int64

for {
select {
case <-timeout:
return
case <-r.Context().Done():
return
default:
// If size is specified, stop when reached
if totalSize > 0 && written >= totalSize {
return
}

// Write buffer to response
n, err := w.Write(buffer)
if err != nil {
return
}
written += int64(n)

// Flush to ensure data is sent immediately
if f, ok := w.(http.Flusher); ok {
f.Flush()
}

// Small sleep to prevent CPU spinning
time.Sleep(1 * time.Millisecond)
}
}
}

// uploadHandler receives data from client for upload speed test
func uploadHandler(w http.ResponseWriter, r *http.Request) {
if r.Method != http.MethodPost {
http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
return
}

w.Header().Set("X-Node-Name", config.NodeName)
w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")

// Read and discard the body efficiently
bufferPtr := bufferPool.Get().(*[]byte)
defer bufferPool.Put(bufferPtr)
buffer := *bufferPtr

totalBytes, err := io.CopyBuffer(io.Discard, r.Body, buffer)
if err != nil && err != io.EOF {
http.Error(w, "Error reading body", http.StatusInternalServerError)
return
}

w.Header().Set("Content-Type", "application/json")
w.WriteHeader(http.StatusOK)
fmt.Fprintf(w, `{"received":%d,"status":"ok"}`, totalBytes)
}

// healthHandler returns server health status
func healthHandler(w http.ResponseWriter, r *http.Request) {
w.Header().Set("Content-Type", "application/json")
w.WriteHeader(http.StatusOK)
fmt.Fprintf(w, `{"status":"healthy","node":"%s","timestamp":"%s"}`, 
config.NodeName, time.Now().Format(time.RFC3339))
}

func main() {
// Load configuration
config = loadConfig()

// Setup routes with CORS
mux := http.NewServeMux()
mux.HandleFunc("/", corsMiddleware(rootHandler))
mux.HandleFunc("/ping", corsMiddleware(pingHandler))
mux.HandleFunc("/download", corsMiddleware(downloadHandler))
mux.HandleFunc("/upload", corsMiddleware(uploadHandler))
mux.HandleFunc("/health", corsMiddleware(healthHandler))

// Configure server
addr := fmt.Sprintf("%s:%s", config.BindIP, config.Port)
server := &http.Server{
Addr:         addr,
Handler:      mux,
ReadTimeout:  config.Timeout,
WriteTimeout: config.Timeout,
IdleTimeout:  120 * time.Second,
MaxHeaderBytes: 1 << 20,
}

// Log startup information
log.Printf("===========================================")
log.Printf("SpeedTest API Service Starting...")
log.Printf("Node Name    : %s", config.NodeName)
log.Printf("Bind Address : %s", addr)
log.Printf("Buffer Size  : %d bytes (%.2f MB)", config.BufferSize, float64(config.BufferSize)/1024/1024)
log.Printf("CPU Cores    : %d", runtime.NumCPU())
log.Printf("GOMAXPROCS   : %d", runtime.GOMAXPROCS(0))
log.Printf("===========================================")
log.Printf("Server ready on http://%s", addr)
log.Printf("Endpoints:")
log.Printf("  GET  /          - Root endpoint (API info)")
log.Printf("  GET  /ping      - Ping test")
log.Printf("  GET  /download  - Download speed test")
log.Printf("  POST /upload    - Upload speed test")
log.Printf("  GET  /health    - Health check")
log.Printf("===========================================")

// Start server
if err := server.ListenAndServe(); err != nil {
log.Fatalf("Server failed to start: %v", err)
}
}
