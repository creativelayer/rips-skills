---
name: rips
description: AI-powered token consignment and staking for the Rips trading card platform. Use when the user wants to register as an agent, create consignment deals, deposit or withdraw tokens, check deal status, manage token listings, or stake RIPS tokens for USDC rewards. Supports token onboarding, consignment management, RIPS staking, and future sponsorship features. Operates on Base blockchain.
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

## Staking RIPS

Stake RIPS tokens to earn USDC rewards. Staking is a direct on-chain interaction — no API key required, just a wallet on Base.

### Contracts

| Contract | Address | Decimals |
|----------|---------|----------|
| RIPS Token | `0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07` | 18 |
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6 |
| Staker V2 | `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` | — |
| Rewards Pool | `0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3` | — |

Network: **Base** (chain ID `8453`)

### Step 1: Acquire RIPS

Swap USDC or ETH for RIPS on any Base DEX (Uniswap V3, Aerodrome, etc).

### Step 2: Approve Staker V2

Call `approve` on the RIPS token contract (`0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07`):

```
approve(
  spender: 0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004,  // Staker V2
  amount:  <amount in wei, or type(uint256).max>
)
```

### Step 3: Stake + Join Rewards Pool (single tx)

Call `stake` on Staker V2 (`0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004`):

```
stake(
  user:        <your wallet address>,
  token:       0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07,  // RIPS
  quantity:    <amount in wei>,
  customize:   true,
  customPools: [0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3]  // Rewards Pool
)
```

Setting `customize: true` with the Rewards Pool address auto-joins the USDC rewards pool in the same transaction.

### Step 4: Claim USDC Rewards (periodically)

Call `claimRewards` on Staker V2:

```
claimRewards(
  user:  <your wallet address>,
  token: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913  // USDC
)
```

### Read: Check Staked Balance

Call `getStake` on Staker V2 — returns amount in wei (18 decimals):

```
getStake(user: <address>, token: 0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07)
```

### Read: Check Claimable Rewards

Call `getUnpaidRewards` on the Rewards Pool (`0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3`) — returns USDC amount (6 decimals):

```
getUnpaidRewards(user: <address>)
```

**Reference**: [references/staking.md](references/staking.md)

## Pack Designs

Browse base designs, preview your logo composited on them, and generate the 3 pack assets needed for boosted packs.

### Browse Available Designs

```bash
scripts/rips-pack-designs.sh
```

Returns all active base designs with IDs, names, descriptions, and preview image URLs.

### Preview Your Logo on a Design

```bash
scripts/rips-pack-preview.sh "foil-1" "https://example.com/logo.png" "3 COINS"
```

Returns a base64 data URL of the composited full pack image. To save as a file:

```bash
scripts/rips-pack-preview.sh "foil-1" "https://example.com/logo.png" | jq -r '.preview' | sed 's/data:image\/png;base64,//' | base64 -d > preview.png
```

### Generate Final Pack Assets

```bash
scripts/rips-pack-generate.sh "foil-1" "https://example.com/logo.png" "3 COINS" "my-token-pack"
```

Generates all 3 asset variants (full, top, bottom), uploads to IPFS, and returns CDN URLs. Save these URLs — you'll need them when creating a boosted pack.

**Reference**: [references/pack-designs.md](references/pack-designs.md)

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

### RIPS Staking

- **Stake RIPS tokens** to earn USDC rewards
- **Claim rewards** periodically
- **Check balances** — staked amount and claimable USDC
- Direct on-chain interaction (no API key needed)

**Reference**: [references/staking.md](references/staking.md)

### Pack Designs (Phase 3a)

- **Browse base designs** with descriptions and preview images
- **Preview custom pack art** — composite your logo + coin text on a base design
- **Generate pack assets** — create all 3 variants (full, top, bottom) and upload to IPFS
- Returned CDN URLs are used when creating boosted packs

**Reference**: [references/pack-designs.md](references/pack-designs.md)

### Sponsorships (Phase 3b - Coming Soon)

- Create sponsored free packs with banner ads
- Create boosted packs with subsidies using generated pack assets
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

### Pack Designs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/agent/pack-designs` | List available base designs |
| POST | `/api/agent/pack-designs/preview` | Preview logo on a base design |
| POST | `/api/agent/pack-designs/generate` | Generate & upload pack assets to IPFS |

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

### Staking

- "Stake 10 million RIPS"
- "How much RIPS do I have staked?"
- "Check my claimable USDC rewards"
- "Claim my staking rewards"

### Pack Designs

- "Show me the available pack base designs"
- "Preview my logo on the purple foil design"
- "Generate pack assets with foil-1 design and my token logo"
- "Which base design would work best for a gaming token?"

### Sponsorships (Coming Soon)

- "Create a sponsored free pack campaign"
- "Set up a boosted pack with 40% subsidy"
- "Show my campaign stats"
