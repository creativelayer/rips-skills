#!/bin/bash
# Register as an agent on the Rips platform
# Usage: rips-register.sh <address> <signature> <nonce> [name] [description] [email]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.clawdbot/skills/rips/config.json"

# Get API URL from config or use default
if [ -f "$CONFIG_FILE" ]; then
    API_URL=$(jq -r '.apiUrl // "https://my.rips.app"' "$CONFIG_FILE")
else
    API_URL="https://my.rips.app"
fi

# Check for required arguments
if [ $# -lt 3 ]; then
    echo "Usage: rips-register.sh <address> <signature> <nonce> [name] [description] [email]" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  address     - Your wallet address (0x...)" >&2
    echo "  signature   - Signed nonce message (0x...)" >&2
    echo "  nonce       - Nonce from rips-nonce.sh" >&2
    echo "  name        - Optional: Agent display name" >&2
    echo "  description - Optional: Agent description" >&2
    echo "  email       - Optional: Contact email" >&2
    exit 1
fi

ADDRESS="$1"
SIGNATURE="$2"
NONCE="$3"
NAME="${4:-}"
DESCRIPTION="${5:-}"
EMAIL="${6:-}"

# Build JSON payload
PAYLOAD=$(jq -n \
    --arg address "$ADDRESS" \
    --arg signature "$SIGNATURE" \
    --arg nonce "$NONCE" \
    --arg name "$NAME" \
    --arg description "$DESCRIPTION" \
    --arg email "$EMAIL" \
    '{
        address: $address,
        signature: $signature,
        nonce: $nonce
    } + (if $name != "" then {name: $name} else {} end)
      + (if $description != "" then {description: $description} else {} end)
      + (if $email != "" then {contactEmail: $email} else {} end)')

# Submit registration
RESPONSE=$(curl -s -X POST "${API_URL}/api/agent/register" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

# Check for error
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error')" >&2
    exit 1
fi

# Output the response
echo "$RESPONSE"

# Remind user to save the API key
if echo "$RESPONSE" | jq -e '.apiKey' >/dev/null 2>&1; then
    echo "" >&2
    echo "IMPORTANT: Save your API key now! It will not be shown again." >&2
    echo "Run the following to configure:" >&2
    echo "" >&2
    API_KEY=$(echo "$RESPONSE" | jq -r '.apiKey')
    echo "mkdir -p ~/.clawdbot/skills/rips" >&2
    echo "cat > ~/.clawdbot/skills/rips/config.json << 'EOF'" >&2
    echo "{" >&2
    echo "  \"apiKey\": \"${API_KEY}\"," >&2
    echo "  \"apiUrl\": \"${API_URL}\"" >&2
    echo "}" >&2
    echo "EOF" >&2
fi
