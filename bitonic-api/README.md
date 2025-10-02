# Bitonic Sequence Generator API

A fast and lightweight HTTP API built in Zig that generates bitonic sequences within specified ranges.

## 🚀 Features

- **High Performance**: Built with Zig for maximum speed and minimal memory footprint
- **Simple REST API**: Single endpoint for generating bitonic sequences
- **Docker Support**: Containerized deployment with AlmaLinux
- **JSON Interface**: Clean JSON request/response format

## 📋 Requirements

- **Zig**: `0.16.0-dev.452+1f7ee99b3`
- **Dependencies**: 
  - [zap](https://github.com/zigzap/zap) `v0.11.0` - HTTP server framework
- **Docker** (optional but recommended for easy deployment)

## 🏗️ Building and Running

### Option 1: Docker (Recommended)

```bash
# Build and run with Docker Compose
docker-compose up --build

# Or build and run manually
docker build -t bitonic-api .
docker run -p 8080:8080 bitonic-api
```

### Option 2: Local Build

```bash
# Install dependencies
zig fetch --save "git+https://github.com/zigzap/zap#v0.11.0"

# Build the project
zig build

# Run the application
zig build run
```

## 🔌 API Reference

The API runs on port `8080` by default.

### Generate Bitonic Sequence

**Endpoint**: `POST /bitonic`

**Request Body**:
```json
{
  "length": 5,
  "start": 1,
  "end": 10
}
```

**Parameters**:
- `length` (integer): Desired length of the bitonic sequence
- `start` (integer): Start of the range (inclusive)
- `end` (integer): End of the range (inclusive)

**Success Response** (200):
```json
{
  "sequence": [9, 10, 8, 7, 6]
}
```

**Error Response** (400):
```json
{
  "error": "It's not possible to generate sequence of length 10 in range [1, 5]"
}
```

### Example Usage

```bash
# Using curl
curl -X POST http://localhost:8080/bitonic \
  -H "Content-Type: application/json" \
  -d '{"length": 7, "start": 1, "end": 15}'

# Expected response
{"sequence": [14, 15, 13, 12, 11, 10, 9]}
```

## 🧮 About Bitonic Sequences

A bitonic sequence is an array that first increases and then decreases (or vice versa). This implementation generates sequences that:

1. Start near the upper bound of the range
2. Include values in a specific pattern optimized for the given constraints
3. Ensure the sequence length fits within the possible combinations of the range

**Maximum possible length**: `(end - start) * 2 + 1`

## 📁 Project Structure

```
bitonic-api/
├── src/
│   ├── main.zig          # HTTP server and API handlers
│   └── bitonic.zig       # Bitonic sequence generation logic
├── build.zig             # Build configuration
├── docker-compose.yml    # Docker Compose setup
├── Dockerfile            # Docker image definition
└── README.md            # This file
```

## 🐳 Docker Details

- **Base Image**: AlmaLinux 9
- **Zig Version**: Downloaded and installed from official builds
- **Port**: 8080 (exposed and mapped)
- **Environment**: Optimized cache directories for container performance

## 🔧 Development

### Local Development Setup

1. **Install Zig**: Download the exact version `0.16.0-dev.452+1f7ee99b3` from [ziglang.org/builds](https://ziglang.org/builds/)

2. **Clone and setup**:
   ```bash
   git clone <your-repo-url>
   cd bitonic-api
   zig fetch --save "git+https://github.com/zigzap/zap#v0.11.0"
   ```

3. **Build and test**:
   ```bash
   zig build
   zig build run
   ```

## 🧪 Testing

The project includes unit tests for the bitonic sequence generation function.

#### Local Testing
```bash
# Run tests locally (requires Zig installation)
zig build test
```

### Test Coverage

The test suite includes:
- **Specific case validation**: Tests the exact output for `length=7, start=2, end=5`
- **Expected output**: `[2, 3, 4, 5, 4, 3, 2]`
- **Sequence properties**: Validates bitonic sequence characteristics
- **Memory management**: Ensures proper allocation/deallocation

### Example Test Output
```
=== Running bitonic test ===
Generated sequence: 2 3 4 5 4 3 2 
Expected sequence:  2 3 4 5 4 3 2 
Test PASSED!
```

### Testing the API

```bash
# Valid request
curl -X POST http://localhost:8080/bitonic \
  -H "Content-Type: application/json" \
  -d '{"length": 3, "start": 5, "end": 8}'

# Invalid request (length too large)
curl -X POST http://localhost:8080/bitonic \
  -H "Content-Type: application/json" \
  -d '{"length": 20, "start": 1, "end": 5}'

# Missing fields
curl -X POST http://localhost:8080/bitonic \
  -H "Content-Type: application/json" \
  -d '{"length": 5}'
```

Built with ❤️ using Zig and zap framework.
