#!/bin/bash
# Get current agent info
# Usage: rips-me.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.clawdbot/skills/rips/config.json"

# Check for config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE" >&2
    echo "" >&2
    echo "Please register first using rips-register.sh, then save your API key:" >&2
    echo "" >&2
    echo "mkdir -p ~/.clawdbot/skills/rips" >&2
    echo 'cat > ~/.clawdbot/skills/rips/config.json << EOF' >&2
    echo '{' >&2
    echo '  "apiKey": "rips_agent_live_YOUR_KEY_HERE",' >&2
    echo '  "apiUrl": "https://my.rips.app"' >&2
    echo '}' >&2
    echo 'EOF' >&2
    exit 1
fi

# Read config
API_KEY=$(jq -r '.apiKey' "$CONFIG_FILE")
API_URL=$(jq -r '.apiUrl // "https://my.rips.app"' "$CONFIG_FILE")

if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "Error: No API key found in config" >&2
    exit 1
fi

# Make request
RESPONSE=$(curl -s -X GET "${API_URL}/api/agent/me" \
    -H "Authorization: Bearer ${API_KEY}")

# Check for error
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    ERROR=$(echo "$RESPONSE" | jq -r '.error')
    echo "Error: $ERROR" >&2

    if [ "$ERROR" = "Unauthorized" ]; then
        echo "" >&2
        echo "Your API key may be invalid or your agent may not be active." >&2
        echo "Contact support if you believe this is an error." >&2
    fi
    exit 1
fi

# Output the response
echo "$RESPONSE"
