#!/bin/bash
# Prepare withdraw transaction for a consignment deal
# Usage: rips-deal-withdraw.sh <deal_id> tokens <amount>
#        rips-deal-withdraw.sh <deal_id> earnings
#
# Returns encoded transaction calldata to sign and broadcast on Base.

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
    echo "Usage: rips-deal-withdraw.sh <deal_id> <type> [amount]" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  deal_id - The UUID of the consignment deal" >&2
    echo "  type    - 'tokens' or 'earnings'" >&2
    echo "  amount  - Required for 'tokens': amount in raw token units" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  rips-deal-withdraw.sh abc-123 tokens 1000000000000000000" >&2
    echo "  rips-deal-withdraw.sh abc-123 earnings" >&2
    exit 1
fi

DEAL_ID="$1"
WITHDRAW_TYPE="$2"
AMOUNT="${3:-}"

# Validate type
if [ "$WITHDRAW_TYPE" != "tokens" ] && [ "$WITHDRAW_TYPE" != "earnings" ]; then
    echo "Error: type must be 'tokens' or 'earnings'" >&2
    exit 1
fi

# Validate amount for token withdrawals
if [ "$WITHDRAW_TYPE" = "tokens" ] && [ -z "$AMOUNT" ]; then
    echo "Error: amount is required for token withdrawals" >&2
    exit 1
fi

# Read config
API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.apiUrl // "https://token-manager.rips.app"' "$CONFIG_FILE")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "Error: No API key found in config" >&2
    exit 1
fi

# Build JSON payload
if [ "$WITHDRAW_TYPE" = "tokens" ]; then
    PAYLOAD=$(jq -n --arg type "$WITHDRAW_TYPE" --arg amount "$AMOUNT" '{type: $type, amount: $amount}')
else
    PAYLOAD=$(jq -n --arg type "$WITHDRAW_TYPE" '{type: $type}')
fi

# Make request
RESPONSE=$(curl -s -X POST "${API_URL}/api/agent/deals/${DEAL_ID}/withdraw" \
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
echo "" >&2
echo "$RESPONSE" | jq -r '.transactions[] | "Transaction: \(.description)"' >&2
