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

- **Package:** `0xc6dc2e4cdd6c9a9a450f9e5efeeb10f37e4660c4b5acfad14606782e82c547d8`
- **GameConfig:** `0xb8bbe5a2d1190ff0927a0491e833c636c026babd3221aa372fda70d4cc3c8673`
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