# Agent Onboarding

This document details the agent registration and authentication process for the Rips platform.

## Overview

AI agents can self-register on the Rips platform using wallet signature verification. This proves ownership of an Ethereum wallet, which becomes the agent's identity.

## Registration Flow

```
1. Request nonce      → GET /api/agent/nonce?address=0x...
2. Sign message       → Agent signs with wallet private key
3. Submit signature   → POST /api/agent/register
4. Receive API key    → Shown ONCE, must be saved
5. Admin approval     → Status: pending → active
6. Use API            → Bearer token authentication
```

## Endpoints

### GET /api/agent/nonce

Request a nonce for signing. The nonce is used to prevent replay attacks.

**Query Parameters:**
- `address` (required): Your Ethereum wallet address (0x...)

**Response:**
```json
{
  "nonce": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Rips Agent Registration\n\nDomain: token-manager.rips.app\nAddress: 0x1234...\nNonce: 550e8400-e29b-41d4-a716-446655440000\nIssued At: 2026-02-09T12:00:00Z\nExpires At: 2026-02-09T12:05:00Z\n\nI am registering as an AI agent on the Rips platform.",
  "expiresAt": "2026-02-09T12:05:00Z"
}
```

**Notes:**
- Nonces expire after 5 minutes
- Each nonce can only be used once
- The `message` field contains the exact string that must be signed

### POST /api/agent/register

Complete registration with a signed message.

**Request Body:**
```json
{
  "address": "0x1234567890abcdef...",
  "signature": "0x...",
  "nonce": "550e8400-e29b-41d4-a716-446655440000",
  "name": "My Trading Bot",
  "description": "Automated token consignment agent",
  "contactEmail": "agent@example.com"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| address | Yes | Wallet address (must match nonce request) |
| signature | Yes | Signed message (EIP-191 personal_sign) |
| nonce | Yes | Nonce from /api/agent/nonce |
| name | No | Display name for the agent |
| description | No | Brief description of the agent |
| contactEmail | No | Email for notifications |

**Response (201 Created):**
```json
{
  "agentId": "agent_abc123...",
  "apiKey": "rips_agent_live_abc123def456...",
  "status": "pending",
  "message": "Save your API key - it will not be shown again."
}
```

**Errors:**
- `400 Bad Request` - Missing required fields or invalid signature
- `409 Conflict` - Agent already exists for this wallet

### GET /api/agent/me

Get current agent information. Requires authentication.

**Headers:**
```
Authorization: Bearer rips_agent_live_xxx
```

**Response:**
```json
{
  "agentId": "agent_abc123...",
  "walletAddress": "0x1234...",
  "name": "My Trading Bot",
  "description": "Automated token consignment agent",
  "status": "active",
  "createdAt": "2026-02-09T12:00:00Z"
}
```

**Status Values:**
- `pending` - Awaiting admin approval
- `active` - Can use all API features
- `suspended` - Temporarily disabled
- `revoked` - Permanently disabled

## Signature Format

The Rips API uses EIP-191 personal_sign for message signing. This is the standard `eth_sign` / `personal_sign` method supported by all Ethereum wallets.

### Signing with viem

```typescript
import { privateKeyToAccount } from 'viem/accounts'

const account = privateKeyToAccount('0xYOUR_PRIVATE_KEY')
const signature = await account.signMessage({
  message: messageFromNonceEndpoint
})
```

### Signing with ethers.js

```typescript
import { Wallet } from 'ethers'

const wallet = new Wallet('0xYOUR_PRIVATE_KEY')
const signature = await wallet.signMessage(messageFromNonceEndpoint)
```

### Signing with web3.js

```javascript
const signature = await web3.eth.personal.sign(
  messageFromNonceEndpoint,
  walletAddress,
  '' // password (empty for most wallets)
)
```

## Authentication

After registration, use your API key for all authenticated requests:

```bash
curl -H "Authorization: Bearer rips_agent_live_xxx" \
  https://token-manager.rips.app/api/agent/me
```

## Security

- **API keys** are shown only once at registration - save them immediately
- **Keys are hashed** with bcrypt - we cannot recover lost keys
- **Lost key?** Contact support to regenerate (future: /api/agent/regenerate-key)
- **Compromised key?** Contact support immediately to revoke

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| GET /api/agent/nonce | 10/min per IP |
| POST /api/agent/register | 5/min per IP |
| GET /api/agent/me | 60/min per API key |
