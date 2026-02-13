#!/bin/bash
# Generate and upload all 3 pack asset variants (full, top, bottom) to IPFS
# Usage: rips-pack-generate.sh <baseDesignId> <logoUrl> [coinText] [packName]
#
# Example:
#   rips-pack-generate.sh foil-1 "https://example.com/logo.png" "3 COINS" "my-token-pack"
#
# Returns CDN URLs for fullImage, topImage, and bottomImage.

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

BASE_DESIGN_ID="${1:?Usage: rips-pack-generate.sh <baseDesignId> <logoUrl> [coinText] [packName]}"
LOGO_URL="${2:?Usage: rips-pack-generate.sh <baseDesignId> <logoUrl> [coinText] [packName]}"
COIN_TEXT="${3:-2 COINS}"
PACK_NAME="${4:-custom-pack}"

RESPONSE=$(curl -s -X POST "${API_URL}/api/agent/pack-designs/generate" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg baseDesignId "$BASE_DESIGN_ID" \
        --arg logoUrl "$LOGO_URL" \
        --arg coinText "$COIN_TEXT" \
        --arg packName "$PACK_NAME" \
        '{baseDesignId: $baseDesignId, logoUrl: $logoUrl, coinText: $coinText, packName: $packName}')")

if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error')" >&2
    exit 1
fi

echo "$RESPONSE"
