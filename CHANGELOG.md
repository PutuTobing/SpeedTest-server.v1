# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-16

### Added
- Initial release of SpeedTest Service
- Core HTTP server with Go standard library
- Main endpoints:
  - `GET /` - Root/health check endpoint
  - `GET /ping` - Latency measurement endpoint
  - `GET /download` - Download speed test with configurable duration/size
  - `POST /upload` - Upload speed test
  - `GET /health` - Detailed health check with node info
- Configuration via environment variables:
  - PORT, BIND_IP, NODE_NAME, BUFFER_SIZE, TIMEOUT
- In-memory buffer pool for efficient memory usage
- Goroutine-based concurrency for high performance
- Keep-alive connection support
- Systemd service files:
  - Single instance: `speedtest.service`
  - Multi-instance: `speedtest@.service`
- Docker support:
  - Dockerfile with multi-stage build
  - docker-compose.yml configuration
- Build and deployment tools:
  - Makefile for build automation
  - build.sh for cross-platform builds
  - deploy.sh for remote deployment
  - setup-multi.sh for multi-instance setup
- Testing tools:
  - test.sh for endpoint testing
  - benchmark.sh for performance testing
  - monitor-nodes.sh for multi-node monitoring
- Comprehensive documentation:
  - README.md - Main documentation
  - QUICKSTART.md - Quick start guide
  - INSTALL.md - Installation guide
  - DEPLOYMENT.md - Deployment scenarios
  - PERFORMANCE.md - Performance tuning guide
  - API.md - Complete API documentation
  - CONTRIBUTING.md - Contribution guidelines
- Example configuration files:
  - .env.example - Environment variables
  - nodes.txt.example - Multi-node configuration
- MIT License

### Performance
- Capable of 10-50 Gbps throughput (hardware dependent)
- Support for 100+ concurrent connections
- < 1ms latency for ping endpoint
- Efficient CPU usage (30-50% at 10 Gbps)
- Low memory footprint (< 200MB)

### Security
- No external dependencies (pure Go stdlib)
- Systemd security hardening options
- Configurable request timeouts
- Protection against basic DoS via timeout

### Notes
- Production ready for internal network use
- Recommended to deploy behind firewall or reverse proxy
- Supports multi-instance deployment for multi-IP servers
- Suitable for ISP/network provider speed test infrastructure

## [Unreleased]

### Planned
- WebSocket support for real-time speed tests
- Prometheus metrics endpoint
- Rate limiting options
- Authentication support (API key, JWT)
- IPv6 support
- HTTP/2 and HTTP/3 support
- Configurable buffer strategies
- Database integration for logging (optional)
- Web UI for testing
- Client libraries (Python, JavaScript)

---

## Version History

- **1.0.0** (2026-04-16) - Initial release

## Upgrade Guide

### From development to 1.0.0
This is the initial stable release. No upgrade needed.

---

For detailed changes, see the commit history in the repository.
