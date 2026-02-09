#!/bin/bash
# Create a new consignment deal
# Usage: rips-deal-create.sh <token_address> [symbol] [name] [decimals] [logo_url]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.clawdbot/skills/rips/config.json"

# Check for config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE" >&2
    echo "Please register first using rips-register.sh" >&2
    exit 1
fi

# Check for required argument
if [ $# -lt 1 ]; then
    echo "Usage: rips-deal-create.sh <token_address> [symbol] [name] [decimals] [logo_url]" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  token_address - Token contract address (0x...)" >&2
    echo "  symbol        - Optional: Token symbol (e.g., PEPE)" >&2
    echo "  name          - Optional: Token name" >&2
    echo "  decimals      - Optional: Token decimals (default: 18)" >&2
    echo "  logo_url      - Optional: Token logo URL" >&2
    exit 1
fi

TOKEN_ADDRESS="$1"
TOKEN_SYMBOL="${2:-}"
TOKEN_NAME="${3:-}"
TOKEN_DECIMALS="${4:-18}"
TOKEN_LOGO="${5:-}"

# Read config
API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.apiUrl // "https://token-manager.rips.app"' "$CONFIG_FILE")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "Error: No API key found in config" >&2
    exit 1
fi

# Build JSON payload
PAYLOAD=$(jq -n \
    --arg tokenAddress "$TOKEN_ADDRESS" \
    --arg tokenSymbol "$TOKEN_SYMBOL" \
    --arg tokenName "$TOKEN_NAME" \
    --argjson tokenDecimals "$TOKEN_DECIMALS" \
    --arg tokenLogo "$TOKEN_LOGO" \
    '{
        tokenAddress: $tokenAddress
    } + (if $tokenSymbol != "" then {tokenSymbol: $tokenSymbol} else {} end)
      + (if $tokenName != "" then {tokenName: $tokenName} else {} end)
      + {tokenDecimals: $tokenDecimals}
      + (if $tokenLogo != "" then {tokenLogo: $tokenLogo} else {} end)')

# Make request
RESPONSE=$(curl -s -X POST "${API_URL}/api/deals" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

# Check for error
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error')" >&2
    exit 1
fi

# Output the response
echo "$RESPONSE"

echo "" >&2
echo "Deal created successfully! Status: pending" >&2
echo "An admin will review and activate your deal." >&2
