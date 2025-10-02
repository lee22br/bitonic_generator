#!/bin/bash

# Simple k6 Load Test Runner with Dashboard
# Installs xk6-dashboard if needed and runs load test

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo -e "${BLUE}k6 Load Test with Dashboard${NC}"
echo -e "Target: ${YELLOW}$BASE_URL${NC}"
echo ""

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo -e "${RED}k6 not found. Install it first:${NC}"
    echo "macOS: brew install k6"
    echo "Ubuntu: sudo apt-get install k6"
    exit 1
fi

# Check if xk6-dashboard k6 is available
if ! k6 version | grep -q "xk6-dashboard" 2>/dev/null; then
    echo -e "${YELLOW}xk6-dashboard not found. Installing...${NC}"
    
    # Check if Go is installed (required for xk6)
    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}Go is required to build xk6-dashboard${NC}"
        echo "Install Go from: https://golang.org/dl/"
        echo ""
        echo "Or install xk6-dashboard manually:"
        echo "1. Install Go"
        echo "2. go install go.k6.io/xk6/cmd/xk6@latest"
        echo "3. xk6 build --with github.com/szkiba/xk6-dashboard@latest"
        echo ""
        echo -e "${BLUE}Running without dashboard...${NC}"
        k6 run -e BASE_URL="$BASE_URL" simple-load-test.js
        exit 0
    fi
    
    # Install xk6 if not present
    if ! command -v xk6 &> /dev/null; then
        echo "Installing xk6..."
        go install go.k6.io/xk6/cmd/xk6@latest
    fi
    
    # Build k6 with dashboard
    echo "Building k6 with dashboard extension..."
    xk6 build --with github.com/szkiba/xk6-dashboard@latest
    
    # Move to a location in PATH
    if [[ -f "./k6" ]]; then
        sudo mv ./k6 /usr/local/bin/k6-dashboard
        echo -e "${GREEN}xk6-dashboard installed as k6-dashboard${NC}"
    fi
fi

# Check API availability
echo -e "${BLUE}Testing API connection...${NC}"
if curl -s -f -X POST "$BASE_URL/bitonic" \
    -H "Content-Type: application/json" \
    -d '{"length":3,"start":1,"end":3}' \
    --connect-timeout 5 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API is responding${NC}"
else
    echo -e "${YELLOW}⚠️  API might not be running at $BASE_URL${NC}"
    echo "Make sure your Bitonic API server is started"
fi

echo ""
echo -e "${BLUE}Starting load test with dashboard...${NC}"
echo -e "${YELLOW}Dashboard will be available at: http://localhost:5665${NC}"
echo ""

# Try to run with dashboard, fallback to regular k6
if command -v k6-dashboard &> /dev/null; then
    k6-dashboard run --out dashboard simple-load-test.js -e BASE_URL="$BASE_URL"
elif k6 version | grep -q "xk6-dashboard"; then
    k6 run --out dashboard simple-load-test.js -e BASE_URL="$BASE_URL"
else
    echo -e "${YELLOW}Running without dashboard (xk6-dashboard not available)${NC}"
    k6 run simple-load-test.js -e BASE_URL="$BASE_URL"
fi