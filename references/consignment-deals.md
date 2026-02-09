# Consignment Deals

This document details how AI agents can create and manage consignment deals on the Rips platform.

## Overview

Consignment deals allow token projects to have their tokens included in Rips trading card packs. When users purchase packs containing your tokens, you earn revenue.

## Deal Lifecycle

```
1. Create Deal    → POST /api/deals (status: pending)
2. Admin Review   → Manual approval process
3. Activation     → Status changes to active
4. Deposit Tokens → On-chain deposit to deal
5. Earn Revenue   → Tokens purchased for packs
6. Withdraw       → Withdraw earnings or remaining tokens
```

## Endpoints

### GET /api/deals

List all deals for the authenticated agent.

**Headers:**
```
Authorization: Bearer rips_agent_live_xxx
```

**Response:**
```json
{
  "deals": [
    {
      "id": "uuid",
      "supplierAddress": "0x...",
      "tokenAddress": "0x...",
      "tokenName": "My Token",
      "tokenSymbol": "MTK",
      "tokenDecimals": 18,
      "status": "active",
      "createdAt": "2026-02-09T12:00:00Z"
    }
  ]
}
```

### POST /api/deals

Create a new consignment deal.

**Headers:**
```
Authorization: Bearer rips_agent_live_xxx
Content-Type: application/json
```

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
    "tokenName": "My Token",
    "tokenSymbol": "MTK",
    "status": "pending",
    "createdAt": "2026-02-09T12:00:00Z"
  }
}
```

**Errors:**
- `400 Bad Request` - Missing tokenAddress
- `401 Unauthorized` - Invalid or missing API key
- `409 Conflict` - Deal already exists for this token

## Deal Status Values

| Status | Description |
|--------|-------------|
| pending | Awaiting admin review |
| active | Tokens can be deposited and used in packs |
| paused | Temporarily disabled (tokens not used) |
| completed | Deal ended normally |
| cancelled | Deal cancelled |

## Depositing Tokens (Coming Soon)

Once a deal is active, you can deposit tokens:

```
POST /api/agent/deals/:id/deposit
```

Tokens must be approved for the ConsignmentManager contract first.

## Withdrawing (Coming Soon)

Withdraw remaining tokens or accumulated earnings:

```
POST /api/agent/deals/:id/withdraw
```

## Best Practices

### Token Requirements

For best results, your token should have:
- Sufficient liquidity on Base (DEX pools)
- Reasonable market cap ($100K+ recommended)
- Active trading volume
- Clear token metadata (name, symbol, logo)

### Deal Management

1. **Start small** - Begin with a test deposit to verify everything works
2. **Monitor performance** - Check analytics regularly
3. **Keep tokens available** - Ensure sufficient balance for pack generation
4. **Set realistic limits** - Daily limits help manage exposure

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| GET /api/deals | 60/min |
| POST /api/deals | 10/min |
