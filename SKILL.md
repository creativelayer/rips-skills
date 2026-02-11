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

Once `status: active`, you can create and manage consignment deals.

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

Returns all consignment deals with on-chain contract data (balances, earnings, daily limits).

### Get Deal Details

```bash
scripts/rips-deal-detail.sh "deal-uuid-here"
```

Returns full deal stats including on-chain balances, manager status, and token allowance.

### Deposit Tokens

```bash
# Deposit 1000 tokens (18 decimals = 1000000000000000000000)
scripts/rips-deal-deposit.sh "deal-uuid" "1000000000000000000000"
```

Returns prepared transactions to sign and broadcast in order:
1. **addManager** (first time only) — authorizes your wallet on the contract
2. **approve** (if needed) — ERC20 token approval
3. **deposit** — the actual deposit call

### Withdraw Tokens or Earnings

```bash
# Withdraw deposited tokens
scripts/rips-deal-withdraw.sh "deal-uuid" tokens "500000000000000000000"

# Withdraw USDC earnings
scripts/rips-deal-withdraw.sh "deal-uuid" earnings
```

### Update Deal Preferences

```bash
# Toggle auto-withdraw
scripts/rips-deal-update.sh "deal-uuid" --auto-withdraw true

# Pause deal (prevents new purchases)
scripts/rips-deal-update.sh "deal-uuid" --pause

# Resume deal
scripts/rips-deal-update.sh "deal-uuid" --resume

# Set daily purchase limit (raw token units, 0 = unlimited)
scripts/rips-deal-update.sh "deal-uuid" --daily-limit "5000000000000000000"
```

## Capabilities Overview

### Agent Onboarding (Phase 1)

- **Self-Registration**: Register with wallet signature
- **Status Check**: View agent status and info
- **API Key Management**: Secure key generation

**Reference**: [references/agent-onboarding.md](references/agent-onboarding.md)

### Consignment Deals (Phase 2)

- **Create deals** for your tokens
- **View deals** with on-chain balances and earnings
- **Deposit tokens** with multi-step transaction preparation
- **Withdraw tokens** or accumulated USDC earnings
- **Manage deals** — pause/resume, set daily limits, toggle auto-withdraw

**Reference**: [references/consignment-deals.md](references/consignment-deals.md)

### Sponsorships (Phase 3 - Coming Soon)

- Create sponsored free packs with banner ads
- Create boosted packs with subsidies
- Track impressions and clicks
- Monitor campaign performance

## API Endpoints

### Onboarding

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agent/nonce` | Request nonce for signing |
| POST | `/api/agent/register` | Complete registration |
| GET | `/api/agent/me` | Get agent info |

### Deals

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/deals` | Create consignment deal |
| GET | `/api/agent/deals` | List deals (with contract data) |
| GET | `/api/agent/deals/:id` | Deal details + on-chain status |
| PATCH | `/api/agent/deals/:id` | Update preferences / prepare on-chain ops |
| POST | `/api/agent/deals/:id/deposit` | Prepare deposit transactions |
| POST | `/api/agent/deals/:id/withdraw` | Prepare withdraw transactions |

## Transaction Preparation

The deposit, withdraw, and on-chain preference endpoints return **prepared transaction calldata** rather than executing transactions directly. Your agent signs and broadcasts these transactions using its own wallet.

Response format:
```json
{
  "transactions": [
    {
      "step": 1,
      "description": "Approve token transfer to the ConsignmentManager contract",
      "to": "0x...",
      "data": "0x...",
      "value": "0"
    }
  ]
}
```

Execute transactions in step order. Each `to`/`data`/`value` triplet is a standard Ethereum transaction. **When multiple transactions are returned, wait for at least 2 block confirmations before sending the next transaction.** Later steps often depend on state changes from earlier steps (e.g., setting a beneficiary before withdrawing earnings).

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
- **403 Forbidden** → You don't own this deal, or agent status is pending/suspended
- **404 Not Found** → Resource doesn't exist
- **409 Conflict** → Deal already exists for this token
- **503 Service Unavailable** → Contract not configured (on-chain features unavailable)

## Prompt Examples

### Onboarding

- "Register my wallet 0x... as an agent on Rips"
- "What's my agent status?"
- "Show my agent info"

### Deal Management

- "Create a consignment deal for my token at 0x..."
- "List my active deals"
- "Show details for deal abc-123"
- "Deposit 1000 tokens to my deal"
- "Withdraw my USDC earnings from deal abc-123"
- "Pause my deal"
- "Set a daily limit of 5000 tokens on my deal"

### Sponsorships (Coming Soon)

- "Create a sponsored free pack campaign"
- "Set up a boosted pack with 40% subsidy"
- "Show my campaign stats"
