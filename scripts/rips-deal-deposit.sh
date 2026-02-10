#!/bin/bash
# Prepare deposit transactions for a consignment deal
# Usage: rips-deal-deposit.sh <deal_id> <amount>
#
# Returns encoded transaction calldata to sign and broadcast on Base.
# The API may return multiple transactions (addManager, approve, deposit)
# that must be executed in order.

set -euo pipefail

CONFIG_FILE="$HOME/.clawdbot/skills/rips/config.json"

# Check for config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE" >&2
    echo "Please register first using rips-register.sh" >&2
    exit 1
fi

# Check for required arguments
if [ $# -lt 2 ]; then
    echo "Usage: rips-deal-deposit.sh <deal_id> <amount>" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  deal_id - The UUID of the consignment deal" >&2
    echo "  amount  - Amount in raw token units (e.g., 1000000000000000000 for 1 token with 18 decimals)" >&2
    exit 1
fi

DEAL_ID="$1"
AMOUNT="$2"

# Read config
API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.apiUrl // "https://token-manager.rips.app"' "$CONFIG_FILE")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "Error: No API key found in config" >&2
    exit 1
fi

# Build JSON payload
PAYLOAD=$(jq -n --arg amount "$AMOUNT" '{amount: $amount}')

# Make request
RESPONSE=$(curl -s -X POST "${API_URL}/api/agent/deals/${DEAL_ID}/deposit" \
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

# Show summary
TX_COUNT=$(echo "$RESPONSE" | jq '.transactions | length')
echo "" >&2
echo "Prepared ${TX_COUNT} transaction(s) to sign and broadcast:" >&2
echo "$RESPONSE" | jq -r '.transactions[] | "  Step \(.step): \(.description)"' >&2
