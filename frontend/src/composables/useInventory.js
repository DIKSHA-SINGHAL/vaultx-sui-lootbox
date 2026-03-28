/**
 * composables/useInventory.js
 * ─────────────────────────────────────────────────────────────
 * Manages the player's on-chain inventory: loot boxes and NFTs.
 *
 * WHY IS THIS SEPARATE FROM useWallet?
 * Inventory state (boxes, items, loadingInv) has nothing to do
 * with wallet connection state.  Keeping them separate means:
 *  - Each file is smaller and easier to read
 *  - We can reload inventory without touching wallet state
 *  - Easier to add features (e.g. refresh button) later
 */

import { ref } from 'vue'
import { fetchLootBoxes, fetchGameItems, fetchGameConfig } from '../services/game.js'

export function useInventory() {
  // ── State ──────────────────────────────────────────────────
  const lootBoxes  = ref([])    // array of { id, boxNumber, purchasedAt }
  const gameItems  = ref([])    // array of { id, name, rarity, power, ... }
  const totalSold  = ref('—')   // total loot boxes ever sold (from GameConfig)
  const loadingInv = ref(false) // true while fetching from RPC

  // ── Actions ───────────────────────────────────────────────
  /**
   * loadAll(address)
   * Fetches boxes, items, and config in parallel using Promise.all.
   *
   * WHY PROMISE.ALL?
   * If we awaited each call sequentially, we'd wait: 300ms + 300ms + 300ms.
   * Promise.all fires all three at the same time and waits for the
   * slowest one — total wait ≈ 300ms instead of 900ms.
   *
   * @param {string} address - the player's wallet address
   */
  async function loadAll(address) {
    loadingInv.value = true
    try {
      const [boxes, items, cfg] = await Promise.all([
        fetchLootBoxes(address),
        fetchGameItems(address),
        fetchGameConfig().catch(() => null), // don't crash if config fails
      ])

      lootBoxes.value = boxes
      gameItems.value = items
      totalSold.value = cfg ? cfg.total_boxes_sold : '—'
    } finally {
      // Always stop the loading spinner, even on error
      loadingInv.value = false
    }
  }

  return {
    lootBoxes, gameItems, totalSold, loadingInv,
    loadAll,
  }
}