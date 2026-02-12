#!/bin/bash
# Generate a preview of a logo composited on a base design
# Usage: rips-pack-preview.sh <baseDesignId> <logoUrl> [coinText]
#
# Example:
#   rips-pack-preview.sh foil-1 "https://example.com/logo.png" "2 COINS"
#
# Returns a base64 data URL of the composited full pack image (765x1295).
# To save as a file: rips-pack-preview.sh ... | jq -r '.preview' | sed 's/data:image\/png;base64,//' | base64 -d > preview.png

set -euo pipefail

CONFIG_FILE="$HOME/.clawdbot/skills/rips/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE" >&2
    echo "Please register first using rips-register.sh" >&2
    exit 1
fi

API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.apiUrl // "https://token-manager.rips.app"' "$CONFIG_FILE")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "Error: No API key found in config" >&2
    exit 1
fi

BASE_DESIGN_ID="${1:?Usage: rips-pack-preview.sh <baseDesignId> <logoUrl> [coinText]}"
LOGO_URL="${2:?Usage: rips-pack-preview.sh <baseDesignId> <logoUrl> [coinText]}"
COIN_TEXT="${3:-2 COINS}"

RESPONSE=$(curl -s -X POST "${API_URL}/api/agent/pack-designs/preview" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg baseDesignId "$BASE_DESIGN_ID" \
        --arg logoUrl "$LOGO_URL" \
        --arg coinText "$COIN_TEXT" \
        '{baseDesignId: $baseDesignId, logoUrl: $logoUrl, coinText: $coinText}')")

if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error')" >&2
    exit 1
fi

echo "$RESPONSE"
