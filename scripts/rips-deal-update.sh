#!/bin/bash
# Update deal preferences or prepare on-chain management transactions
# Usage: rips-deal-update.sh <deal_id> [options]
#
# Options:
#   --auto-withdraw true|false    Toggle auto-withdraw of earnings
#   --pause                       Prepare pause transaction
#   --resume                      Prepare resume transaction
#   --daily-limit <amount>        Prepare daily limit transaction (raw token units, 0 = unlimited)

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
    echo "Usage: rips-deal-update.sh <deal_id> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --auto-withdraw true|false  Toggle auto-withdraw of earnings" >&2
    echo "  --pause                     Prepare pause transaction" >&2
    echo "  --resume                    Prepare resume transaction" >&2
    echo "  --daily-limit <amount>      Set daily limit (raw token units, 0 = unlimited)" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  rips-deal-update.sh abc-123 --auto-withdraw true" >&2
    echo "  rips-deal-update.sh abc-123 --pause" >&2
    echo "  rips-deal-update.sh abc-123 --daily-limit 5000000000000000000" >&2
    exit 1
fi

DEAL_ID="$1"
shift

# Parse options into JSON payload
AUTO_WITHDRAW=""
PAUSE=""
RESUME=""
DAILY_LIMIT=""

while [ $# -gt 0 ]; do
    case "$1" in
        --auto-withdraw)
            AUTO_WITHDRAW="$2"
            shift 2
            ;;
        --pause)
            PAUSE="true"
            shift
            ;;
        --resume)
            RESUME="true"
            shift
            ;;
        --daily-limit)
            DAILY_LIMIT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Read config
API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.apiUrl // "https://token-manager.rips.app"' "$CONFIG_FILE")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "Error: No API key found in config" >&2
    exit 1
fi

# Build JSON payload
PAYLOAD="{}"

if [ -n "$AUTO_WITHDRAW" ]; then
    if [ "$AUTO_WITHDRAW" = "true" ]; then
        PAYLOAD=$(echo "$PAYLOAD" | jq '. + {autoWithdraw: true}')
    else
        PAYLOAD=$(echo "$PAYLOAD" | jq '. + {autoWithdraw: false}')
    fi
fi

if [ "$PAUSE" = "true" ]; then
    PAYLOAD=$(echo "$PAYLOAD" | jq '. + {pause: true}')
fi

if [ "$RESUME" = "true" ]; then
    PAYLOAD=$(echo "$PAYLOAD" | jq '. + {resume: true}')
fi

if [ -n "$DAILY_LIMIT" ]; then
    PAYLOAD=$(echo "$PAYLOAD" | jq --arg limit "$DAILY_LIMIT" '. + {dailyLimit: $limit}')
fi

# Make request
RESPONSE=$(curl -s -X PATCH "${API_URL}/api/agent/deals/${DEAL_ID}" \
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

# Show transaction summary if any
if echo "$RESPONSE" | jq -e '.transactions' >/dev/null 2>&1; then
    TX_COUNT=$(echo "$RESPONSE" | jq '.transactions | length')
    echo "" >&2
    echo "Prepared ${TX_COUNT} transaction(s) to sign and broadcast:" >&2
    echo "$RESPONSE" | jq -r '.transactions[] | "  Step \(.step): \(.description)"' >&2
fi
