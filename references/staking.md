# Staking RIPS

Stake RIPS tokens on Base to earn USDC rewards from the Rips platform fee pool.

## Contracts

| Contract | Address | Decimals |
|----------|---------|----------|
| RIPS Token (ERC-20) | `0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07` | 18 |
| USDC (reward token) | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | 6 |
| Staker V2 | `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` | — |
| Rewards Pool (FeePool) | `0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3` | — |

**Network:** Base (chain ID `8453`)

> **Decimals matter:** RIPS uses 18 decimals (1 RIPS = `1000000000000000000` wei). USDC uses 6 decimals (1 USDC = `1000000`). Don't mix these up when formatting amounts for display or when parsing return values.

## How It Works

1. You stake RIPS tokens into the Staker V2 contract
2. You join the Rewards Pool to start earning
3. Platform swap fees are distributed as USDC to the Rewards Pool
4. Rewards accumulate proportionally based on your staked amount
5. You claim USDC rewards whenever you want

## Transactions

### 1. Approve RIPS spending

Standard ERC-20 approval on the RIPS token contract.

**Contract:** `0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07` (RIPS Token)

```solidity
function approve(address spender, uint256 amount) returns (bool)
```

| Parameter | Value |
|-----------|-------|
| spender | `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` (Staker V2) |
| amount | Amount to stake in wei, or `type(uint256).max` for unlimited |

### 2. Stake + Join Rewards Pool (single transaction)

> **Key UX detail:** By passing `customize: true` with the Rewards Pool address in `customPools`, the `stake()` call both stakes your RIPS *and* joins the USDC rewards pool in a single transaction. Without this, you'd need a separate `joinPools()` call, and you won't earn rewards until you do.

**Contract:** `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` (Staker V2)

```solidity
function stake(address user, address token, uint256 quantity, bool customize, address[] customPools)
```

| Parameter | Value |
|-----------|-------|
| user | Your wallet address |
| token | `0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07` (RIPS) |
| quantity | Amount to stake in wei (18 decimals) |
| customize | `true` |
| customPools | `[0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3]` (Rewards Pool) |

<details>
<summary>ABI</summary>

```json
{
  "inputs": [
    { "internalType": "address", "name": "user", "type": "address" },
    { "internalType": "address", "name": "token", "type": "address" },
    { "internalType": "uint256", "name": "quantity", "type": "uint256" },
    { "internalType": "bool", "name": "customize", "type": "bool" },
    { "internalType": "address[]", "name": "customPools", "type": "address[]" }
  ],
  "name": "stake",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
}
```

</details>

### 3. Claim USDC Rewards

Claims all accumulated USDC rewards.

**Contract:** `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` (Staker V2)

```solidity
function claimRewards(address user, address token)
```

| Parameter | Value |
|-----------|-------|
| user | Your wallet address |
| token | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (USDC) |

<details>
<summary>ABI</summary>

```json
{
  "inputs": [
    { "internalType": "address", "name": "user", "type": "address" },
    { "internalType": "address", "name": "token", "type": "address" }
  ],
  "name": "claimRewards",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
}
```

</details>

### 4. Unstake (optional)

Returns staked RIPS tokens to your wallet.

**Contract:** `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` (Staker V2)

```solidity
function unstake(address user, address token, uint256 quantity)
```

| Parameter | Value |
|-----------|-------|
| user | Your wallet address |
| token | `0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07` (RIPS) |
| quantity | Amount to unstake in wei (18 decimals) |

<details>
<summary>ABI</summary>

```json
{
  "inputs": [
    { "internalType": "address", "name": "user", "type": "address" },
    { "internalType": "address", "name": "token", "type": "address" },
    { "internalType": "uint256", "name": "quantity", "type": "uint256" }
  ],
  "name": "unstake",
  "outputs": [],
  "stateMutability": "nonpayable",
  "type": "function"
}
```

</details>

## Read Functions

### Check Staked Balance

**Contract:** `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` (Staker V2)

```solidity
function getStake(address user, address token) view returns (uint256)
```

| Parameter | Value |
|-----------|-------|
| user | Wallet address to check |
| token | `0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07` (RIPS) |

Returns staked amount in wei (**18 decimals** — divide by `1e18` for human-readable RIPS amount).

<details>
<summary>ABI</summary>

```json
{
  "inputs": [
    { "internalType": "address", "name": "user", "type": "address" },
    { "internalType": "address", "name": "token", "type": "address" }
  ],
  "name": "getStake",
  "outputs": [
    { "internalType": "uint256", "name": "", "type": "uint256" }
  ],
  "stateMutability": "view",
  "type": "function"
}
```

</details>

### Check Claimable Rewards

**Contract:** `0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3` (Rewards Pool)

```solidity
function getUnpaidRewards(address user) view returns (uint256)
```

| Parameter | Value |
|-----------|-------|
| user | Wallet address to check |

Returns claimable USDC amount (**6 decimals** — divide by `1e6` for human-readable USDC amount).

<details>
<summary>ABI</summary>

```json
{
  "inputs": [
    { "internalType": "address", "name": "user", "type": "address" }
  ],
  "name": "getUnpaidRewards",
  "outputs": [
    { "internalType": "uint256", "name": "", "type": "uint256" }
  ],
  "stateMutability": "view",
  "type": "function"
}
```

</details>

### Check if Joined Rewards Pool

**Contract:** `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` (Staker V2)

```solidity
function hasJoinedPool(address user, address token, address pool) view returns (bool)
```

| Parameter | Value |
|-----------|-------|
| user | Wallet address to check |
| token | `0xc1aDDAe61Bc74a14971BFA48A0B7141AdeD4fB07` (RIPS) |
| pool | `0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3` (Rewards Pool) |

Returns `true` if the user is earning rewards.

## Additional Operations

### Join Rewards Pool (if not done during stake)

If you staked with `customize: false`, you need to join the pool separately.

**Contract:** `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` (Staker V2)

```solidity
function joinPools(address user, address[] pools)
```

| Parameter | Value |
|-----------|-------|
| user | Your wallet address |
| pools | `[0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3]` |

### Leave Rewards Pool

Stop earning rewards while keeping tokens staked.

**Contract:** `0xB6d7B6F1c4Ad64d75fc8c63e56188b6e3eF0c004` (Staker V2)

```solidity
function leavePools(address user, address[] pools, bool useGasCap)
```

| Parameter | Value |
|-----------|-------|
| user | Your wallet address |
| pools | `[0xb0D256824ACd2EE1cbC03e97C47A7B5fec9Fe5f3]` |
| useGasCap | `false` |
