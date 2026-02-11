# Consignment Deals

This document details how AI agents can create and manage consignment deals on the Rips platform.

## Overview

Consignment deals allow token projects to have their tokens included in Rips trading card packs. When users purchase packs containing your tokens, you earn revenue.

## Deal Lifecycle

```
1. Create Deal    → POST /api/deals (status: pending)
2. Admin Review   → Manual approval process
3. Activation     → Status changes to active
4. Deposit Tokens → POST /api/agent/deals/:id/deposit → sign & broadcast
5. Earn Revenue   → Tokens purchased for packs, USDC accumulates
6. Withdraw       → POST /api/agent/deals/:id/withdraw → sign & broadcast
```

## Endpoints

All deal management endpoints require authentication:
```
Authorization: Bearer rips_agent_live_xxx
```

### POST /api/deals — Create a Deal

**Request Body:**
```json
{
  "tokenAddress": "0x1234567890abcdef...",
  "tokenName": "My Token",
  "tokenSymbol": "MTK",
  "tokenDecimals": 18,
  "tokenLogo": "https://example.com/logo.png",
  "minPayoutUsd": 10.0
}
```

| Field | Required | Description |
|-------|----------|-------------|
| tokenAddress | Yes | Token contract address on Base |
| tokenName | No | Display name (fetched from chain if omitted) |
| tokenSymbol | No | Symbol (fetched from chain if omitted) |
| tokenDecimals | No | Decimals (default: 18) |
| tokenLogo | No | Logo URL (IPFS or HTTPS) |
| minPayoutUsd | No | Minimum payout threshold (default: $10) |

**Response (201 Created):**
```json
{
  "deal": {
    "id": "uuid",
    "supplierAddress": "0x...",
    "tokenAddress": "0x...",
    "tokenSymbol": "MTK",
    "status": "pending",
    "createdAt": "2026-02-09T12:00:00Z"
  }
}
```

**Errors:**
- `400` — Missing tokenAddress
- `401` — Invalid or missing API key
- `409` — Deal already exists for this token

### GET /api/agent/deals — List Deals

Returns all your deals enriched with on-chain contract data.

**Response:**
```json
{
  "deals": [
    {
      "id": "uuid",
      "tokenAddress": "0x...",
      "tokenSymbol": "MTK",
      "status": "active",
      "deposited": 1000.5,
      "purchased": 200.0,
      "availableBalance": 800.5,
      "totalUsdPaid": 150.00,
      "pendingEarnings": 25.00,
      "availableFormatted": "800.5",
      "availableUsd": "$400.25",
      "dailyLimit": 100,
      "dailyRemaining": 75,
      "createdAt": "2026-02-09T12:00:00Z"
    }
  ]
}
```

### GET /api/agent/deals/:id — Deal Details

Returns a single deal with full stats and your on-chain context.

**Response:**
```json
{
  "deal": {
    "id": "uuid",
    "tokenSymbol": "MTK",
    "status": "active",
    "deposited": 1000.5,
    "availableBalance": 800.5,
    "pendingEarnings": 25.00
  },
  "onChainStatus": {
    "isManager": true,
    "tokenAllowance": "1000000000000000000",
    "contractConfigured": true
  }
}
```

### POST /api/agent/deals/:id/deposit — Prepare Deposit

Prepares transaction calldata for depositing tokens. May return multiple transactions.

**Request:**
```json
{ "amount": "1000000000000000000" }
```

Amount is in **raw token units** (e.g., `1000000000000000000` = 1 token with 18 decimals).

**Response:**
```json
{
  "dealId": "uuid",
  "tokenAddress": "0x...",
  "tokenSymbol": "MTK",
  "amount": "1000000000000000000",
  "transactions": [
    {
      "step": 1,
      "description": "Add your wallet as a manager for this deal",
      "to": "0x...",
      "data": "0x...",
      "value": "0"
    },
    {
      "step": 2,
      "description": "Approve token transfer to the ConsignmentManager contract",
      "to": "0x...",
      "data": "0x...",
      "value": "0"
    },
    {
      "step": 3,
      "description": "Deposit tokens into the consignment deal",
      "to": "0x...",
      "data": "0x...",
      "value": "0"
    }
  ]
}
```

Steps 1 and 2 are only included when needed (first deposit, or insufficient allowance).

**Errors:**
- `400` — Deal not active, invalid amount
- `403` — You don't own this deal
- `503` — Contract not configured

### POST /api/agent/deals/:id/withdraw — Prepare Withdrawal

Prepares transaction calldata for withdrawing tokens or earnings.

**Request (withdraw tokens):**
```json
{ "type": "tokens", "amount": "500000000000000000" }
```

**Request (withdraw earnings):**
```json
{ "type": "earnings" }
```

**Response:**
```json
{
  "dealId": "uuid",
  "type": "tokens",
  "amount": "500000000000000000",
  "transactions": [
    {
      "step": 1,
      "description": "Withdraw tokens from the consignment deal",
      "to": "0x...",
      "data": "0x...",
      "value": "0"
    }
  ]
}
```

**Errors:**
- `400` — Insufficient balance, no pending earnings, invalid type
- `403` — You don't own this deal

### PATCH /api/agent/deals/:id — Update Preferences

Updates deal settings. Neo4j-side changes apply immediately; on-chain changes return transaction calldata.

**Request:**
```json
{
  "autoWithdraw": true,
  "pause": true,
  "dailyLimit": "5000000000000000000"
}
```

| Field | Type | Description |
|-------|------|-------------|
| autoWithdraw | boolean | Toggle auto-withdraw of earnings (applied immediately) |
| pause | true | Prepare pause transaction |
| resume | true | Prepare resume transaction |
| dailyLimit | string | Prepare setDailyLimit transaction (raw token units, "0" = unlimited) |

**Response:**
```json
{
  "deal": { "...deal stats..." },
  "transactions": [
    {
      "step": 1,
      "description": "Pause the consignment deal",
      "to": "0x...",
      "data": "0x...",
      "value": "0"
    }
  ]
}
```

## Deal Status Values

| Status | Description |
|--------|-------------|
| pending | Awaiting admin review |
| active | Tokens can be deposited and used in packs |
| paused | Temporarily disabled (tokens not used in new packs) |
| completed | Deal ended normally |
| cancelled | Deal cancelled |

## Transaction Execution

On-chain operations (deposit, withdraw, pause, resume, dailyLimit) return **prepared transaction calldata**. Your agent must:

1. Receive the `transactions` array from the API
2. Execute each transaction in `step` order
3. Sign with your wallet private key
4. Broadcast on Base network
5. **Wait for at least 2 block confirmations** before proceeding to the next step — later steps depend on state changes from earlier ones

Each transaction provides `{ to, data, value }` — standard Ethereum transaction fields.

## Best Practices

### Token Requirements

For best results, your token should have:
- Sufficient liquidity on Base (DEX pools)
- Reasonable market cap ($100K+ recommended)
- Active trading volume
- Clear token metadata (name, symbol, logo)

### Deal Management

1. **Start small** — Begin with a test deposit to verify everything works
2. **Monitor performance** — Check deal details regularly for earnings
3. **Keep tokens available** — Ensure sufficient balance for pack generation
4. **Set realistic limits** — Daily limits help manage exposure
5. **Use auto-withdraw** — Toggle on for automatic earnings collection

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| GET endpoints | 60/min |
| POST/PATCH endpoints | 10/min |
