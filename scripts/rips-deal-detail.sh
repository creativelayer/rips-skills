#!/bin/bash
# Get details for a single consignment deal (with on-chain status)
# Usage: rips-deal-detail.sh <deal_id>

set -euo pipefail

CONFIG_FILE="$HOME/.clawdbot/skills/rips/config.json"

# Check for config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE" >&2
    echo "Please register first using rips-register.sh" >&2
    exit 1
fi

# Check for required argument
if [ $# -lt 1 ]; then
    echo "Usage: rips-deal-detail.sh <deal_id>" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  deal_id - The UUID of the consignment deal" >&2
    exit 1
fi

DEAL_ID="$1"

# Read config
API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.apiUrl // "https://my.rips.app"' "$CONFIG_FILE")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "Error: No API key found in config" >&2
    exit 1
fi

# Make request
RESPONSE=$(curl -s -X GET "${API_URL}/api/agent/deals/${DEAL_ID}" \
    -H "Authorization: Bearer ${API_KEY}")

# Check for error
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error')" >&2
    exit 1
fi

# Output the response
echo "$RESPONSE"
