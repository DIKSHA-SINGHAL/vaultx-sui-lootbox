/**
 * services/game.js
 * ─────────────────────────────────────────────────────────────
 * All blockchain read/write calls for VaultX.
 *
 * MODULE MAP (matches the deployed Move package):
 *   buy box   → PACKAGE_ID::loot_box::buy
 *   open box  → PACKAGE_ID::open_box::open_box   (entry, not public)
 *   fetch     → RPC queries (free, no gas)
 */

import { Transaction } from '@mysten/sui/transactions'
import {
  client, PACKAGE_ID, GAME_CONFIG, CLOCK_ID, RANDOM_ID, PRICE_MIST
} from '../config/sui.js'

// ── Internal: sign and broadcast a transaction ────────────────
// Handles the old (signAndExecuteTransactionBlock) vs new
// (signAndExecuteTransaction) wallet API difference.
async function signAndExecute(wallet, account, tx) {
  const feature =
    wallet.features['sui:signAndExecuteTransaction'] ??
    wallet.features['sui:signAndExecuteTransactionBlock']

  const result =
    await feature.signAndExecuteTransaction?.({
      transaction: tx,
      account,
      chain: 'sui:testnet',
    }) ??
    await feature.signAndExecuteTransactionBlock?.({
      transactionBlock: tx,
      account,
      chain: 'sui:testnet',
    })

  const digest = result.digest

  // Wait for the transaction to be indexed by the RPC node before returning.
  // Without this, loadAll() runs too fast and the new object isn't queryable yet.
  await client.waitForTransaction({ digest, timeout: 30 })

  return digest
}

// ── Buy a loot box ────────────────────────────────────────────
// Calls: vaultx::loot_box::buy(config, payment, clock, ctx)
// Splits exactly PRICE_MIST from the gas coin as the payment.
export async function buyBox(wallet, account) {
  const tx = new Transaction()
  tx.setSender(account.address)

  // Split exact payment from gas coin
  const [payment] = tx.splitCoins(tx.gas, [PRICE_MIST])

  tx.moveCall({
    target: `${PACKAGE_ID}::loot_box::buy`,
    arguments: [
      tx.object(GAME_CONFIG),  // &mut GameConfig
      payment,                  // Coin<SUI> — exact price
      tx.object(CLOCK_ID),     // &Clock
    ],
  })

  return signAndExecute(wallet, account, tx)
}

// ── Open a loot box ───────────────────────────────────────────
// Calls: vaultx::open_box::open_box(config, loot_box, rand, clock, ctx)
// This is an `entry` function — wallet-only, no contract can call it.
export async function openBox(wallet, account, lootBoxId) {
  const tx = new Transaction()
  tx.setSender(account.address)

  tx.moveCall({
    target: `${PACKAGE_ID}::open_box::open_box`,
    arguments: [
      tx.object(GAME_CONFIG),  // &mut GameConfig
      tx.object(lootBoxId),    // LootBox (consumed + burned)
      tx.object(RANDOM_ID),    // &Random at 0x8
      tx.object(CLOCK_ID),     // &Clock
    ],
  })

  return signAndExecute(wallet, account, tx)
}

// ── Transfer a GameItem to another wallet ─────────────────────
// Calls: vaultx::game_item::transfer_item(item, recipient, clock, ctx)
export async function transferItem(wallet, account, itemId, recipientAddress) {
  const tx = new Transaction()
  tx.setSender(account.address)

  tx.moveCall({
    target: `${PACKAGE_ID}::game_item::transfer_item`,
    arguments: [
      tx.object(itemId),                    // GameItem (consumed)
      tx.pure.address(recipientAddress),    // recipient address
      tx.object(CLOCK_ID),                  // &Clock
    ],
  })

  return signAndExecute(wallet, account, tx)
}

// ── Burn a GameItem permanently ───────────────────────────────
// Calls: vaultx::game_item::burn_item(item, clock, ctx)
export async function burnItem(wallet, account, itemId) {
  const tx = new Transaction()
  tx.setSender(account.address)

  tx.moveCall({
    target: `${PACKAGE_ID}::game_item::burn_item`,
    arguments: [
      tx.object(itemId),    // GameItem (consumed + deleted)
      tx.object(CLOCK_ID),  // &Clock
    ],
  })

  return signAndExecute(wallet, account, tx)
}

// ── Fetch all unopened LootBoxes owned by player ──────────────
export async function fetchLootBoxes(address) {
  const result = await client.getOwnedObjects({
    owner: address,
    filter: { StructType: `${PACKAGE_ID}::loot_box::LootBox` },
    options: { showContent: true },
  })

  return result.data
    .filter(obj => obj.data?.content?.fields)
    .map(obj => ({
      id:          obj.data.objectId,
      boxNumber:   obj.data.content.fields.box_number,
      purchasedAt: obj.data.content.fields.purchased_at,
    }))
}

// ── Fetch all GameItem NFTs owned by player ───────────────────
export async function fetchGameItems(address) {
  const result = await client.getOwnedObjects({
    owner: address,
    filter: { StructType: `${PACKAGE_ID}::game_item::GameItem` },
    options: { showContent: true },
  })

  return result.data
    .filter(obj => obj.data?.content?.fields)
    .map(obj => ({
      id:        obj.data.objectId,
      name:      obj.data.content.fields.name,
      rarity:    obj.data.content.fields.rarity,
      power:     obj.data.content.fields.power,
      originBox: obj.data.content.fields.origin_box,
      mintedAt:  obj.data.content.fields.minted_at,
    }))
}

// ── Fetch global GameConfig (price, weights, total sold) ──────
export async function fetchGameConfig() {
  const obj = await client.getObject({
    id: GAME_CONFIG,
    options: { showContent: true },
  })
  return obj.data?.content?.fields ?? null
}