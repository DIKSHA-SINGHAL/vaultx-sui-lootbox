/**
 * composables/useGameFlow.js
 * ─────────────────────────────────────────────────────────────
 * Controls the buying and box-opening user flow.
 *
 * THE OPENING STAGE MACHINE:
 * Opening a box goes through several visual states:
 *
 *   idle → opening → rolling → reveal → idle
 *
 *   idle:    normal inventory view, click "Open" to start
 *   opening: transaction is in-flight, show spinning box
 *   rolling: tx confirmed, animate the 0-99 number cycling
 *   reveal:  show the minted NFT card with rarity effects
 *
 * WHY A STAGE MACHINE?
 * Instead of a tangle of booleans (isOpening, isRolling, isRevealing),
 * a single `stage` string makes the template v-if conditions cleaner
 * and impossible to be in two states at once.
 */

import { ref } from 'vue'
import { buyBox, openBox } from '../services/game.js'

export function useGameFlow(wallet, account, address, loadAll, refreshBalance, showToast) {
  // ── State ──────────────────────────────────────────────────
  const buying      = ref(false)    // true while buy transaction is pending
  const opening     = ref(false)    // true while open transaction is pending
  const stage       = ref('idle')   // current animation stage (see above)
  const displayRoll = ref(0)        // the number shown during the roll animation
  const revealedItem = ref(null)    // the NFT item to show in the reveal card

  // ── Buy Flow ──────────────────────────────────────────────
  /**
   * handleBuy()
   * Sends 0.1 SUI → receives a LootBox in wallet → reloads inventory.
   */
  async function handleBuy() {
    buying.value = true
    try {
      await buyBox(wallet.value, account.value)
      showToast('Box added to inventory!', 'success')
      // Reload so the new box shows up in the Unopened list
      await loadAll(address.value)
      // Show updated balance after spending SUI
      await refreshBalance()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      buying.value = false
    }
  }

  // ── Open Flow ─────────────────────────────────────────────
  /**
   * handleOpen(box)
   * Full open sequence: transaction → animation → reveal.
   *
   * @param {{ id, boxNumber }} box - the loot box to open
   */
  async function handleOpen(box) {
    opening.value = true
    stage.value   = 'opening'  // show the spinning box icon

    try {
      // Submit the open_box transaction and wait for on-chain confirmation.
      // The LootBox is burned and a GameItem is minted inside this call.
      await openBox(wallet.value, account.value, box.id)

      // Transaction confirmed — start the dice animation
      stage.value = 'rolling'
      await animateRoll()  // cycle numbers for ~1.5 seconds

      // Reload inventory to get the newly minted NFT
      await loadAll(address.value)
      await refreshBalance()

      // The newest item will be at index 0 (most recently minted)
      const item = gameItems_ref.value[0] // injected below via closure trick
      if (item) {
        revealedItem.value = item
        stage.value = 'reveal'
        showToast(`${item.rarityLabel ?? 'Item'} dropped!`, 'success')
      } else {
        stage.value = 'idle'
      }
    } catch (err) {
      stage.value = 'idle'
      showToast(err.message, 'error')
    } finally {
      opening.value = false
    }
  }

  // ── Roll Animation ────────────────────────────────────────
  /**
   * animateRoll()
   * Cycles displayRoll through random numbers to create the
   * "slot machine" effect before the real result is shown.
   *
   * WHY RETURN A PROMISE?
   * We want to await the animation before showing the reveal card.
   * Wrapping setInterval in a Promise lets us use async/await
   * instead of messy callback chains.
   *
   * @returns {Promise<void>} resolves when the animation ends
   */
  function animateRoll() {
    return new Promise(resolve => {
      let ticks = 0
      const interval = setInterval(() => {
        // Random number 0-99 (matches the on-chain range)
        displayRoll.value = Math.floor(Math.random() * 100)
        ticks++
        if (ticks > 25) {
          // After 25 ticks (~1.75 seconds at 70ms each), stop
          clearInterval(interval)
          resolve()
        }
      }, 70) // 70ms between each number change
    })
  }

  function resetStage() {
    stage.value = 'idle'
    revealedItem.value = null
  }

  // ── Workaround: inject gameItems ref so reveal works ─────
  // We need the latest gameItems after loadAll to pick the top item.
  // The caller (App.vue) injects it after composable setup.
  let gameItems_ref = { value: [] }
  function setGameItemsRef(ref_) { gameItems_ref = ref_ }

  return {
    buying, opening, stage, displayRoll, revealedItem,
    handleBuy, handleOpen, resetStage, setGameItemsRef,
  }
}