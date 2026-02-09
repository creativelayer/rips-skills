---
name: rips
description: AI-powered token consignment for the Rips trading card platform. Use when the user wants to register as an agent, create consignment deals, deposit or withdraw tokens, check deal status, or manage token listings on the Rips platform. Supports token onboarding, consignment management, and future sponsorship features. Operates on Base blockchain.
metadata:
  {
    "clawdbot":
      {
        "emoji": "🃏",
        "homepage": "https://rips.app",
        "requires": { "bins": ["curl", "jq"] },
      },
  }
---

# Rips Agent API

Manage token consignment deals on the Rips trading card platform using natural language.

## Quick Start

### First-Time Setup

#### Step 1: Register as an Agent

Agents self-register using wallet signature verification:

```bash
# Get a nonce to sign
NONCE_RESPONSE=$(scripts/rips-nonce.sh "0xYourWalletAddress")
MESSAGE=$(echo "$NONCE_RESPONSE" | jq -r '.message')

# Sign the message with your wallet (outside this script)
# Then register with the signature
scripts/rips-register.sh "0xYourWalletAddress" "0xYourSignature" "$NONCE"
```

The registration response includes your API key (shown only once - save it!):

```json
{
  "agentId": "agent_abc123...",
  "apiKey": "rips_agent_live_abc123def456...",
  "status": "pending",
  "message": "Save your API key - it will not be shown again."
}
```

#### Step 2: Configure

Save your API key to the config file:

```bash
mkdir -p ~/.clawdbot/skills/rips
cat > ~/.clawdbot/skills/rips/config.json << 'EOF'
{
  "apiKey": "rips_agent_live_YOUR_KEY_HERE",
  "apiUrl": "https://token-manager.rips.app"
}
EOF
```

#### Step 3: Wait for Approval

New agents start with `status: pending`. An admin will review and activate your account. Check your status:

```bash
scripts/rips-me.sh
```

Once `status: active`, you can create consignment deals.

### Verify Setup

```bash
scripts/rips-me.sh
```

## Core Usage

### Check Agent Status

```bash
scripts/rips-me.sh
```

Returns your agent info including wallet address, status, and creation date.

### Create a Consignment Deal

```bash
# With just the token address (metadata fetched from chain)
scripts/rips-deal-create.sh "0xTokenAddress"

# With full metadata
scripts/rips-deal-create.sh "0xTokenAddress" "TOKEN" "Token Name" 18 "https://example.com/logo.png"
```

Creates a new consignment deal for your token. The deal will be reviewed before tokens can be deposited.

### List Your Deals

```bash
scripts/rips-deals.sh
```

Returns all consignment deals associated with your agent account.

Example response:
```json
{
  "deals": [
    {
      "id": "uuid",
      "tokenAddress": "0x...",
      "tokenSymbol": "MTK",
      "status": "active",
      "createdAt": "2026-02-09T12:00:00Z"
    }
  ]
}
```

## Capabilities Overview

### Agent Onboarding (Phase 1)

- **Self-Registration**: Register with wallet signature
- **Status Check**: View agent status and info
- **API Key Management**: Secure key generation

**Reference**: [references/agent-onboarding.md](references/agent-onboarding.md)

### Consignment Deals (Phase 2 - Coming Soon)

- Create consignment deals for your tokens
- Deposit tokens to deals
- Withdraw tokens or earnings
- Set preferences and limits

**Reference**: [references/consignment-deals.md](references/consignment-deals.md)

### Sponsorships (Phase 3 - Coming Soon)

- Create sponsored free packs with banner ads
- Create boosted packs with subsidies
- Track impressions and clicks
- Monitor campaign performance

**Reference**: [references/sponsorships.md](references/sponsorships.md)

## API Endpoints

### Onboarding

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agent/nonce` | Request nonce for signing |
| POST | `/api/agent/register` | Complete registration |
| GET | `/api/agent/me` | Get agent info |

### Deals (Coming Soon)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/agent/deals` | Create consignment deal |
| GET | `/api/agent/deals` | List agent's deals |
| GET | `/api/agent/deals/:id` | Deal details |
| POST | `/api/agent/deals/:id/deposit` | Deposit tokens |
| POST | `/api/agent/deals/:id/withdraw` | Withdraw tokens |

## Best Practices

### Security

1. Never share your API key
2. Store keys securely (environment variables or encrypted config)
3. Your wallet controls your agent - keep private keys safe
4. Start with test amounts when depositing

### Token Management

1. Ensure your token has sufficient liquidity before listing
2. Check token acceptance status before large deposits
3. Monitor deal performance regularly
4. Set appropriate payout thresholds

## Error Handling

Common issues and fixes:

- **401 Unauthorized** → Check API key is correct and agent is active
- **403 Forbidden** → Agent status may be pending or suspended
- **404 Not Found** → Resource doesn't exist or you don't have access
- **409 Conflict** → Deal already exists for this token

For comprehensive error troubleshooting:

**Reference**: [references/error-handling.md](references/error-handling.md)

## Prompt Examples

### Onboarding

- "Register my wallet 0x... as an agent on Rips"
- "What's my agent status?"
- "Show my agent info"

### Deal Management (Coming Soon)

- "Create a consignment deal for my token"
- "List my active deals"
- "Check the status of deal xyz"
- "Deposit 1000 tokens to my deal"
- "Withdraw my earnings"

### Sponsorships (Coming Soon)

- "Create a sponsored free pack campaign"
- "Set up a boosted pack with 40% subsidy"
- "Show my campaign stats"
