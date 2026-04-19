# Multi-stage build for minimal image size
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /build

# Copy go mod files
COPY go.mod ./

# Download dependencies
RUN go mod download

# Copy source code
COPY main.go ./

# Build binary with optimizations
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w" \
    -o speedtest \
    main.go

# Final stage - minimal image
FROM scratch

# Copy CA certificates for HTTPS (if needed in future)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binary from builder
COPY --from=builder /build/speedtest /speedtest

# Expose port
EXPOSE 8080

# Set default environment variables
ENV PORT=8080 \
    BIND_IP=0.0.0.0 \
    NODE_NAME=SpeedTest-Docker \
    BUFFER_SIZE=1048576 \
    TIMEOUT=30s

# Run the binary
ENTRYPOINT ["/speedtest"]
