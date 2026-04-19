# =============================================================================
#  SpeedTest Server - Dockerfile
#  Multi-stage build: compile with Go, run in minimal scratch image
#  Supports: linux/amd64, linux/arm64, linux/arm/v7
# =============================================================================

# Stage 1: Build
FROM golang:1.26-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /build

# Cache dependency layer separately
COPY go.mod ./
RUN go mod download

# Copy source and build
COPY main.go ./

# Build with optimizations — auto-detect target arch from Docker buildx
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w -X main.version=1.1.0" \
    -o speedtest \
    main.go

# Stage 2: Minimal runtime image
FROM scratch

# CA certificates (for future HTTPS/TLS support)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# Timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy compiled binary
COPY --from=builder /build/speedtest /speedtest

# Expose default port
EXPOSE 8080

# Default environment variables (all overridable via -e or docker-compose)
ENV PORT=8080 \
    BIND_IP=0.0.0.0 \
    NODE_NAME=SpeedTest-Docker \
    LOCATION=Unknown \
    BUFFER_SIZE=4194304 \
    TIMEOUT=30s

# Run as non-root (UID 65534 = nobody)
USER 65534

ENTRYPOINT ["/speedtest"]
