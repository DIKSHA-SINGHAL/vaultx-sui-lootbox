/**
 * config/sui.js
 * ─────────────────────────────────────────────────────────────
 * Single source of truth for every Sui blockchain constant.
 *
 * WHY A SEPARATE FILE?
 * If we re-deploy the contract we change PACKAGE_ID once here
 * and every other file picks it up automatically.
 *
 * SuiClient is our connection to the Sui RPC node — think of
 * it like a database connection. We create ONE instance and
 * re-use it everywhere instead of opening a new connection
 * in each service.
 */

import { SuiClient, getFullnodeUrl } from '@mysten/sui/client'

// ── RPC Connection ────────────────────────────────────────────
// getFullnodeUrl('testnet') returns the official Sui testnet URL.
// Swap 'testnet' → 'mainnet' when going live.
export const client = new SuiClient({
  url: getFullnodeUrl('testnet'),
})

// ── Our Deployed Contract ─────────────────────────────────────
// PACKAGE_ID: the on-chain address of our vaultx Move package.
// All function calls are: PACKAGE_ID::module_name::function_name
export const PACKAGE_ID =
  '0xb83f3fb3032bbe3441f8830e29563706d344c3dbd00685cecf196f625c8c458f'

// GAME_CONFIG: the shared GameConfig object (created once at deploy).
// "Shared object" = lives on-chain, any wallet can interact with it.
// Stores: price, drop weights, total boxes sold, treasury balance.
export const GAME_CONFIG =
  '0xf4f617814cfb7296ef157e6adc98ac9ec794a6646386b13768c9c8ffe14d2a1c'

// ── Sui System Objects (same address on every Sui network) ────

// CLOCK_ID: on-chain clock. Gives Move functions a trusted timestamp.
export const CLOCK_ID =
  '0x0000000000000000000000000000000000000000000000000000000000000006'

// RANDOM_ID: Sui's randomness beacon — produced by validators.
// open_box reads from this to decide your item rarity. Tamper-proof.
export const RANDOM_ID =
  '0x0000000000000000000000000000000000000000000000000000000000000008'

// ── Price ─────────────────────────────────────────────────────
// Sui's smallest unit is MIST (like satoshis).  1 SUI = 1_000_000_000 MIST.
// 0.1 SUI = 100_000_000 MIST
export const PRICE_MIST = 100_000_000