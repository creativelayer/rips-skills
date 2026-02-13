#!/bin/bash
# List available pack base designs
# Usage: rips-pack-designs.sh

set -euo pipefail

CONFIG_FILE="$HOME/.clawdbot/skills/rips/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE" >&2
    echo "Please register first using rips-register.sh" >&2
    exit 1
fi

API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.apiUrl // "https://my.rips.app"' "$CONFIG_FILE")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "Error: No API key found in config" >&2
    exit 1
fi

RESPONSE=$(curl -s -X GET "${API_URL}/api/agent/pack-designs" \
    -H "Authorization: Bearer ${API_KEY}")

if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error')" >&2
    exit 1
fi

echo "$RESPONSE"
