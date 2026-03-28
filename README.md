# VaultX 🎲

**On-chain loot box game on Sui blockchain with provable fairness**


## What It Is

A fully decentralized loot box game where players spend SUI tokens to buy mystery boxes and receive randomly generated NFTs. The randomness comes directly from Sui's validator network — no server, no admin manipulation.

## Tech Stack

- **Blockchain:** Sui Testnet
- **Smart Contract:** Move (10-module architecture)
- **Frontend:** Vue 3 + Vite
- **Wallet:** Slush integration
- **SDK:** @mysten/sui

## Deployed Addresses

- **Package:** `0xb83f3fb3032bbe3441f8830e29563706d344c3dbd00685cecf196f625c8c458f`
- **GameConfig:** `0xf4f617814cfb7296ef157e6adc98ac9ec794a6646386b13768c9c8ffe14d2a1c`
- **Network:** Sui Testnet

## Features

✅ **Trustless Randomness** — Sui validator network generates random numbers on-chain  
✅ **4 Rarity Tiers** — Common (70%), Rare (20%), Epic (8%), Legendary (2%)  
✅ **Pity System** — Guaranteed Epic after 50 boxes without one  
✅ **NFT Transfers** — Items have `store` ability for marketplace composability  
✅ **Event Emission** — All actions emit events for indexers  
✅ **Admin Controls** — Pause, update weights, adjust price, withdraw treasury

## Quick Start

### Prerequisites
- Node.js 16+
- Sui CLI
- Slush wallet browser extension

### Frontend
```bash
cd frontend
npm install
npm run dev
```

### Smart Contract
```bash
cd contract
sui move build
sui client publish --gas-budget 100000000
```

## Architecture

**10-module Move package:**
- `vaultx` — Entry point
- `constants`, `errors` — Core config
- `config`, `events` — Shared state
- `loot_box`, `game_item`, `pity`, `open_box` — Game logic
- `admin` — Admin operations

**Frontend flow:**
1. Connect Slush wallet
2. Buy loot box (0.1 SUI)
3. Open box → on-chain random roll
4. Receive NFT with rarity + power
5. Transfer or burn items
