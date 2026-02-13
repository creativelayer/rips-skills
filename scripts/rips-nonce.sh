#!/bin/bash
# Request a nonce for agent registration
# Usage: rips-nonce.sh <wallet_address>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.clawdbot/skills/rips/config.json"

# Get API URL from config or use default
if [ -f "$CONFIG_FILE" ]; then
    API_URL=$(jq -r '.apiUrl // "https://my.rips.app"' "$CONFIG_FILE")
else
    API_URL="https://my.rips.app"
fi

# Check for address argument
if [ $# -lt 1 ]; then
    echo "Usage: rips-nonce.sh <wallet_address>" >&2
    echo "Example: rips-nonce.sh 0x1234567890abcdef1234567890abcdef12345678" >&2
    exit 1
fi

ADDRESS="$1"

# Validate address format
if [[ ! "$ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "Error: Invalid wallet address format" >&2
    echo "Address must be a 42-character hex string starting with 0x" >&2
    exit 1
fi

# Request nonce
RESPONSE=$(curl -s -X GET "${API_URL}/api/agent/nonce?address=${ADDRESS}")

# Check for error
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error')" >&2
    exit 1
fi

# Output the response
echo "$RESPONSE"
