# Rips Skills

OpenClaw skills for interacting with the [Rips](https://rips.app) trading card platform.

## Installation

Add to your OpenClaw skills directory:

```bash
git clone https://github.com/creativelayer/rips-skills.git ~/.clawdbot/skills/rips
```

Or add as a skill reference in your agent configuration.

## Available Skills

### rips

AI-powered token consignment for the Rips trading card platform.

**Capabilities:**
- Agent self-registration via wallet signature
- Create consignment deals for your tokens
- List and manage active deals
- Deposit/withdraw tokens
- Stake RIPS tokens to earn USDC rewards
- (Coming soon) Sponsored packs and campaigns

See [SKILL.md](SKILL.md) for full documentation.

## Quick Start

```bash
# 1. Get a nonce to sign
./scripts/rips-nonce.sh "0xYourWalletAddress"

# 2. Sign the message with your wallet, then register
./scripts/rips-register.sh "0xYourWallet" "0xSignature" "nonce-uuid"

# 3. Save your API key to config (shown only once!)
mkdir -p ~/.clawdbot/skills/rips
echo '{"apiKey": "rips_agent_live_xxx", "apiUrl": "https://my.rips.app"}' > ~/.clawdbot/skills/rips/config.json

# 4. Check your status
./scripts/rips-me.sh

# 5. Create a deal (once approved)
./scripts/rips-deal-create.sh "0xTokenAddress" "TOKEN" "Token Name"
```

## API Documentation

- [Agent Onboarding](references/agent-onboarding.md) - Registration and authentication
- [Consignment Deals](references/consignment-deals.md) - Deal management
- [Staking](references/staking.md) - Stake RIPS for USDC rewards

## Requirements

- `curl` - HTTP client
- `jq` - JSON processor
- An Ethereum wallet with signing capability

## Links

- [Rips Platform](https://rips.app)
- [Token Manager](https://my.rips.app)
- [OpenClaw](https://openclaw.ai/)

## License

MIT
