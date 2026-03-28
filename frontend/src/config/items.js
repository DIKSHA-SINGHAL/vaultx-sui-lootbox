/**
 * config/items.js
 * ─────────────────────────────────────────────────────────────
 * Item name + emoji pool for each rarity tier.
 *
 * HOW DETERMINISTIC PICKING WORKS:
 * We never store the item name/emoji on-chain — the contract only
 * stores rarity (0-3) and the object ID. On the frontend we use
 * the last 2 hex chars of the object ID as a number, then mod by
 * the pool size. This means:
 *   - Same NFT always shows the same item name across sessions
 *   - Different NFTs of the same rarity can look different
 *   - No extra blockchain call needed
 *
 * Usage:
 *   import { pickItem } from '../config/items.js'
 *   const { emoji, name, subname } = pickItem(item.rarity, item.id)
 */

export const ITEM_POOLS = {
    // ── Common (10 items) ─────────────────────────────────────
    // Basic loot — grey-toned, rough gear
    0: [
      { emoji: '🛡️', name: 'Buckler',       subname: 'worn iron shield' },
      { emoji: '🗡️', name: 'Dagger',        subname: 'chipped steel blade' },
      { emoji: '🪵', name: 'Wooden Staff',  subname: 'rough hewn oak' },
      { emoji: '🎯', name: 'Arrow Bundle',  subname: 'twelve plain arrows' },
      { emoji: '🪨', name: 'Stone Rune',    subname: 'faded inscription' },
      { emoji: '🧤', name: 'Iron Gloves',   subname: 'basic hand armour' },
      { emoji: '👞', name: 'Soldier Boots', subname: 'worn leather soles' },
      { emoji: '🪬', name: 'Ward Token',    subname: 'minor protection charm' },
      { emoji: '🏺', name: 'Clay Vessel',   subname: 'ancient cracked pot' },
      { emoji: '🔩', name: 'Scrap Metal',   subname: 'salvageable parts' },
    ],
  
    // ── Rare (6 items) ────────────────────────────────────────
    // Crafted gear — blue-toned, quality materials
    1: [
      { emoji: '⚔️',  name: 'Longsword',    subname: 'forged steel blade' },
      { emoji: '💎',  name: 'Sapphire',     subname: 'deep ocean gem' },
      { emoji: '🏹',  name: 'Crossbow',     subname: 'precise enchanted aim' },
      { emoji: '🦺',  name: 'Chainmail',    subname: 'riveted iron links' },
      { emoji: '💙',  name: 'Frost Shard',  subname: 'crystallised cold' },
      { emoji: '🔵',  name: 'Mana Crystal', subname: 'concentrated arcane' },
    ],
  
    // ── Epic (6 items) ────────────────────────────────────────
    // Magical artifacts — purple-toned, supernatural origin
    2: [
      { emoji: '🔮', name: 'Arcane Orb',   subname: 'pulsing void energy' },
      { emoji: '🌀', name: 'Storm Blade',  subname: 'crackling with lightning' },
      { emoji: '👁️', name: 'Eye of Chaos', subname: 'sees beyond the veil' },
      { emoji: '🌙', name: 'Moon Shard',   subname: 'sliver of pale light' },
      { emoji: '🕯️', name: 'Soul Lantern', subname: 'guides the wandering dead' },
      { emoji: '🧿', name: 'Void Sphere',  subname: 'space bent inside glass' },
    ],
  
    // ── Legendary (4 items) ───────────────────────────────────
    // Ancient relics — gold-toned, mythic power
    3: [
      { emoji: '👑', name: 'Eternal Crown',    subname: 'relic of the ancients' },
      { emoji: '🔱', name: 'Trident of Gods',  subname: 'wielded by titans' },
      { emoji: '🐉', name: 'Dragon Seal',      subname: 'bound a god once' },
      { emoji: '⚡', name: 'Thunderfang',      subname: 'strikes without warning' },
    ],
  }
  
  /**
   * pickItem(rarity, objectId)
   * Deterministically selects an item from the pool for this NFT.
   *
   * Uses the last 2 hex characters of the Sui object ID as a seed.
   * This gives 256 possible values, evenly distributed across pool sizes
   * of 4, 6, or 10 with minimal bias.
   *
   * @param {number} rarity   - 0=Common, 1=Rare, 2=Epic, 3=Legendary
   * @param {string} objectId - Sui object ID (0x...)
   * @returns {{ emoji, name, subname }}
   */
  export function pickItem(rarity, objectId) {
    const pool = ITEM_POOLS[rarity] ?? ITEM_POOLS[0]
  
    // Take last 2 hex chars of objectId as a number (0-255)
    // Fallback to 0 if objectId is missing or malformed
    let seed = 0
    if (objectId && objectId.length >= 2) {
      const lastTwo = objectId.slice(-2)
      seed = parseInt(lastTwo, 16) || 0
    }
  
    return pool[seed % pool.length]
  }