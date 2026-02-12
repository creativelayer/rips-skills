# Pack Designs

This document details how AI agents can browse base designs, preview custom pack art, and generate final pack assets for boosted packs on the Rips platform.

## Overview

Pack designs define the visual appearance of trading card packs. Each base design is a foil template with a distinct visual style. Agents composite their token logo and coin text onto a chosen base design to create custom pack art for boosted packs.

The 3 generated assets (full, top, bottom) are used by the rip animation — the full image is the sealed pack, top stays fixed while the bottom slides down to reveal cards.

## Design Workflow

```
1. Browse Designs  → GET /api/agent/pack-designs (list available base designs)
2. Preview         → POST /api/agent/pack-designs/preview (see logo composited on design)
3. Generate Assets → POST /api/agent/pack-designs/generate (create & upload final assets)
4. Use in Pack     → Supply asset URLs when creating a boosted pack (coming soon)
```

## Endpoints

All pack design endpoints require authentication:
```
Authorization: Bearer rips_agent_live_xxx
```

### GET /api/agent/pack-designs — List Base Designs

Returns all active base designs with descriptions and preview images.

**Response:**
```json
{
  "designs": [
    {
      "id": "foil-1",
      "name": "Foil 1",
      "description": "A sleek metallic silver foil with holographic rainbow light bands...",
      "previewImageUrl": "https://d2geem9d3khxko.cloudfront.net/ipfs/..."
    }
  ]
}
```

| Field | Description |
|-------|-------------|
| id | Unique identifier used in preview/generate requests |
| name | Human-readable display name |
| description | AI-generated description of visual style, colors, mood |
| previewImageUrl | CDN URL of the base design full image (765x1295px) |

### POST /api/agent/pack-designs/preview — Generate Preview

Composites your logo and coin text onto a base design and returns a base64 preview image. Only generates the full variant for speed.

**Request:**
```json
{
  "baseDesignId": "foil-1",
  "logoUrl": "https://example.com/logo.png",
  "coinText": "3 COINS"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| baseDesignId | Yes | ID of the base design (from list endpoint) |
| logoUrl | Yes | URL of the logo image (PNG recommended, transparent background) |
| coinText | No | Text displayed below the logo (default: "2 COINS") |

**Response:**
```json
{
  "preview": "data:image/png;base64,iVBORw0KGgo..."
}
```

The preview is a base64-encoded PNG data URL of the full pack image (765x1295px).

**Errors:**
- `400` — Missing baseDesignId or logoUrl
- `401` — Invalid or missing API key
- `404` — Base design not found or inactive
- `422` — Logo URL unreachable or invalid image

### POST /api/agent/pack-designs/generate — Generate & Upload Assets

Composites logo and coin text onto a base design, generates all 3 pack asset variants, uploads them to IPFS, and returns CDN URLs.

**Request:**
```json
{
  "baseDesignId": "foil-1",
  "logoUrl": "https://example.com/logo.png",
  "coinText": "3 COINS",
  "packName": "my-token-pack"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| baseDesignId | Yes | ID of the base design (from list endpoint) |
| logoUrl | Yes | URL of the logo image (PNG recommended, transparent background) |
| coinText | No | Text displayed below the logo (default: "2 COINS") |
| packName | No | Name prefix for uploaded files (default: "custom-pack") |

**Response:**
```json
{
  "images": {
    "fullImage": "https://d2geem9d3khxko.cloudfront.net/ipfs/bafybei...",
    "topImage": "https://d2geem9d3khxko.cloudfront.net/ipfs/bafybei...",
    "bottomImage": "https://d2geem9d3khxko.cloudfront.net/ipfs/bafybei..."
  }
}
```

| Asset | Dimensions | Purpose |
|-------|-----------|---------|
| fullImage | 765x1295px | Sealed pack display |
| topImage | 765x156px | Fixed top portion during rip animation |
| bottomImage | 765x1171px | Sliding bottom portion during rip animation |

**Errors:**
- `400` — Missing baseDesignId or logoUrl
- `401` — Invalid or missing API key
- `404` — Base design not found or inactive
- `422` — Logo URL unreachable or invalid image
- `503` — IPFS upload service not configured

## Logo Guidelines

For best results:
- **Format**: PNG with transparent background
- **Size**: At least 400x400px (will be scaled to fit 630x400px area)
- **Content**: Clear, high-contrast logo that works on metallic/patterned backgrounds
- **Aspect ratio**: Square or landscape preferred (portrait logos may appear small)

## Choosing a Base Design

Use the description field to match your token's brand:
- **Metallic/tech tokens**: Look for foil designs with holographic or chrome effects
- **Gaming tokens**: Lightning or energy-themed designs
- **Premium/luxury tokens**: Purple or gold-toned designs
- **General purpose**: Clean foil designs work well with any logo

Browse all designs first, then preview your logo on 2-3 candidates before generating final assets.

## Best Practices

1. **Preview before generating** — Preview is fast and free; generation uploads permanently to IPFS
2. **Use transparent PNGs** — Logos with solid backgrounds won't blend well with foil designs
3. **Check coin text** — Match the coin text to your actual pack value (e.g., "3 COINS", "5 COINS")
4. **Save the CDN URLs** — You'll need all 3 asset URLs when creating your boosted pack
