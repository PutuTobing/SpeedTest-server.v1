# Makefile for SpeedTest Service

BINARY_NAME=speedtest
INSTALL_PATH=/usr/local/bin
CONFIG_PATH=/etc/speedtest
SERVICE_PATH=/etc/systemd/system

.PHONY: all build run clean install uninstall test help

# Default target
all: build

# Build the binary
build:
	@echo "Building ${BINARY_NAME}..."
	@go build -ldflags="-s -w" -o ${BINARY_NAME} main.go
	@echo "Build complete: ${BINARY_NAME}"

# Build with race detector (for development)
build-race:
	@echo "Building ${BINARY_NAME} with race detector..."
	@go build -race -o ${BINARY_NAME} main.go
	@echo "Build complete: ${BINARY_NAME}"

# Run the service
run: build
	@echo "Starting ${BINARY_NAME}..."
	@./${BINARY_NAME}

# Run with custom config
run-dev:
	@echo "Starting ${BINARY_NAME} in development mode..."
	@PORT=8080 NODE_NAME=Dev-Node ./${BINARY_NAME}

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -f ${BINARY_NAME}
	@echo "Clean complete"

# Install to system
install: build
	@echo "Installing ${BINARY_NAME}..."
	@sudo cp ${BINARY_NAME} ${INSTALL_PATH}/
	@sudo chmod +x ${INSTALL_PATH}/${BINARY_NAME}
	@sudo mkdir -p ${CONFIG_PATH}
	@sudo cp .env.example ${CONFIG_PATH}/speedtest.env
	@sudo cp speedtest.service ${SERVICE_PATH}/
	@echo "Creating speedtest user..."
	@sudo useradd -r -s /bin/false speedtest 2>/dev/null || true
	@sudo systemctl daemon-reload
	@echo ""
	@echo "Installation complete!"
	@echo "Edit config: sudo nano ${CONFIG_PATH}/speedtest.env"
	@echo "Enable service: sudo systemctl enable speedtest"
	@echo "Start service: sudo systemctl start speedtest"

# Uninstall from system
uninstall:
	@echo "Uninstalling ${BINARY_NAME}..."
	@sudo systemctl stop speedtest 2>/dev/null || true
	@sudo systemctl disable speedtest 2>/dev/null || true
	@sudo rm -f ${INSTALL_PATH}/${BINARY_NAME}
	@sudo rm -f ${SERVICE_PATH}/speedtest.service
	@sudo rm -rf ${CONFIG_PATH}
	@sudo systemctl daemon-reload
	@echo "Uninstall complete"

# Run tests
test:
	@echo "Running tests..."
	@chmod +x test.sh
	@./test.sh

# Format code
fmt:
	@echo "Formatting code..."
	@go fmt ./...

# Run linter
lint:
	@echo "Running linter..."
	@golint ./... || echo "golint not installed, run: go install golang.org/x/lint/golint@latest"

# Cross-compile for Linux AMD64
build-linux:
	@echo "Building for Linux AMD64..."
	@GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o ${BINARY_NAME}-linux-amd64 main.go
	@echo "Build complete: ${BINARY_NAME}-linux-amd64"

# Cross-compile for Linux ARM64
build-arm64:
	@echo "Building for Linux ARM64..."
	@GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o ${BINARY_NAME}-linux-arm64 main.go
	@echo "Build complete: ${BINARY_NAME}-linux-arm64"

# Build all platforms
build-all: build-linux build-arm64
	@echo "All builds complete"

# Display help
help:
	@echo "SpeedTest Service Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build        - Build the binary"
	@echo "  make run          - Build and run the service"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make install      - Install to system (/usr/local/bin)"
	@echo "  make uninstall    - Remove from system"
	@echo "  make test         - Run tests"
	@echo "  make fmt          - Format code"
	@echo "  make build-linux  - Build for Linux AMD64"
	@echo "  make build-arm64  - Build for Linux ARM64"
	@echo "  make build-all    - Build all platforms"
	@echo "  make help         - Show this help"
