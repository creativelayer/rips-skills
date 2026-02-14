# Coin Data & Card Previews

This document details how AI agents can access data about their coins on the Rips platform, including card preview images for marketing.

## Overview

Agents with consignment deals can:
- List all their coins and market metadata
- Get detailed statistics on how their coins perform on the platform
- Generate card preview images (standard and legendary) for marketing use

## Endpoints

All coin endpoints require authentication:
```
Authorization: Bearer rips_agent_live_xxx
```

### GET /api/agent/coins — List Your Coins

Returns all coins from your active consignment deals with market metadata.

**Response:**
```json
{
  "coins": [
    {
      "tokenAddress": "0x1234...abcd",
      "symbol": "MTK",
      "name": "My Token",
      "image": "https://d2geem9d3khxko.cloudfront.net/ipfs/Qm...",
      "decimals": 18,
      "currentPrice": 0.00042,
      "marketCap": 420000,
      "volume24h": 52000,
      "priceChange1h": 2.5,
      "priceChange6h": -1.3,
      "priceChange24h": 8.7,
      "holders": 1250,
      "liquidity": 85000,
      "website": "https://mytoken.xyz",
      "twitterHandle": "mytoken",
      "dealId": "uuid",
      "dealStatus": "active"
    }
  ]
}
```

| Field | Type | Description |
|-------|------|-------------|
| tokenAddress | string | Contract address on Base |
| symbol | string | Token ticker symbol |
| name | string | Token display name |
| image | string\|null | Token logo URL |
| decimals | number | Token decimals |
| currentPrice | number | Current USD price |
| marketCap | number | Market capitalization in USD |
| volume24h | number | 24-hour trading volume in USD |
| priceChange1h | number\|null | 1-hour price change (%) |
| priceChange6h | number\|null | 6-hour price change (%) |
| priceChange24h | number\|null | 24-hour price change (%) |
| holders | number\|null | Number of token holders |
| liquidity | number\|null | Liquidity in USD |
| website | string\|null | Project website |
| twitterHandle | string\|null | Twitter/X handle |
| dealId | string | Associated consignment deal ID |
| dealStatus | string | Deal status (pending, active, paused) |

**Errors:**
- `401` — Invalid or missing API key

---

### GET /api/agent/coins/:address — Coin Details & Statistics

Returns detailed coin metadata and platform statistics. You must have an active deal for this coin.

**Path Parameters:**
| Parameter | Description |
|-----------|-------------|
| address | Token contract address (case-insensitive) |

**Response:**
```json
{
  "coin": {
    "tokenAddress": "0x1234...abcd",
    "symbol": "MTK",
    "name": "My Token",
    "image": "https://d2geem9d3khxko.cloudfront.net/ipfs/Qm...",
    "decimals": 18,
    "currentPrice": 0.00042,
    "marketCap": 420000,
    "volume24h": 52000,
    "priceChange1h": 2.5,
    "priceChange6h": -1.3,
    "priceChange24h": 8.7,
    "holders": 1250,
    "liquidity": 85000,
    "website": "https://mytoken.xyz",
    "twitterHandle": "mytoken"
  },
  "stats": {
    "totalPacks": 156,
    "totalCards": 892,
    "uniqueUsers": 234,
    "legendaryCards": 3
  }
}
```

**Stats Fields:**

| Field | Type | Description |
|-------|------|-------------|
| totalPacks | number | Total packs that included this coin |
| totalCards | number | Total cards distributed for this coin |
| uniqueUsers | number | Unique users who received this coin |
| legendaryCards | number | Legendary cards distributed for this coin |

**Errors:**
- `401` — Invalid or missing API key
- `404` — No active deal for this token, or token not found

---

### GET /api/agent/coins/:address/card-preview — Generate Card Preview

Generates a card preview image for your coin in standard or legendary style. Returns a base64 PNG data URL that you can decode and use for marketing materials, social media posts, etc.

**Path Parameters:**
| Parameter | Description |
|-----------|-------------|
| address | Token contract address (case-insensitive) |

**Query Parameters:**
| Parameter | Default | Description |
|-----------|---------|-------------|
| type | standard | Card style: `standard` or `legendary` |

**Example Request:**
```
GET /api/agent/coins/0x1234...abcd/card-preview?type=legendary
Authorization: Bearer rips_agent_live_xxx
```

**Response:**
```json
{
  "preview": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...",
  "type": "legendary",
  "tokenAddress": "0x1234...abcd",
  "symbol": "MTK"
}
```

| Field | Type | Description |
|-------|------|-------------|
| preview | string | Base64 PNG data URL (530×760px) |
| type | string | Card type that was generated |
| tokenAddress | string | Token address |
| symbol | string | Token symbol |

**Card Styles:**
- **Standard** — Silver/gray gradient card showing coin logo, market cap, and 24h volume
- **Legendary** — Gold gradient card with "LEGENDARY" badge

**Using the preview image:**
The `preview` field contains a data URL. To save it as a file:
```python
import base64
data = response["preview"].split(",")[1]
with open("card.png", "wb") as f:
    f.write(base64.b64decode(data))
```

**Errors:**
- `401` — Invalid or missing API key
- `404` — No active deal for this token, or token not found

## Use Cases

### Marketing & Social Media
Generate card preview images to share on Twitter, Discord, or Telegram to promote your token's presence on the Rips platform.

### Portfolio Dashboards
Use the coin details and statistics endpoints to display how your token is performing — how many users hold your cards, how many packs featured your coin, etc.

### Performance Tracking
Monitor `priceChange1h/6h/24h`, `volume24h`, and platform stats over time to understand the impact of being on the Rips platform.
