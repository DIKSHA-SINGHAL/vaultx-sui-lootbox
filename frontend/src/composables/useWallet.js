/**
 * composables/useWallet.js
 * ─────────────────────────────────────────────────────────────
 * A Vue "composable" that manages wallet connection state.
 *
 * WHAT IS A COMPOSABLE?
 * It's a function that uses Vue's reactivity system (ref, computed)
 * to create shared, reusable state. Instead of dumping all state
 * into one giant App.vue, we split by concern:
 *   - useWallet  → connected?, address, balance, connect()
 *   - useInventory → boxes, items, loading, loadAll()
 *   - useGameFlow  → buying, opening, stage, animations
 *
 * Composables are called inside a component's setup() and their
 * reactive refs auto-update the template when values change.
 *
 * WHY markRaw FOR wallet AND account?
 * Vue's reactivity system tries to make every object "reactive"
 * by wrapping it in a Proxy. Wallet objects from the Sui SDK are
 * complex and have circular references — wrapping them in a Proxy
 * breaks them. markRaw() tells Vue: "leave this object alone,
 * don't make it reactive". We manage the state (connected, address)
 * separately as plain refs.
 */

import { ref, computed, markRaw } from 'vue'
import { connectSlush, fetchBalance } from '../services/wallet.js'
import { shortAddr }                 from '../utils/format.js'

export function useWallet() {
  // ── State ─────────────────────────────────────────────────
  // ref(value) creates a reactive variable.
  // In the template, Vue unwraps refs automatically (no .value needed).
  // In JS code, you must use wallet.value, address.value, etc.

  const connected    = ref(false)   // is a wallet currently connected?
  const connecting   = ref(false)   // are we waiting for the wallet popup?
  const connectError = ref(null)    // any error message from connection attempt

  // markRaw: don't make these SDK objects reactive (see explanation above)
  const wallet  = ref(null)   // the Slush wallet instance
  const account = ref(null)   // the active account object (has .address, .publicKey)
  const address = ref(null)   // the wallet's public address string
  const balance = ref('0.0000') // current SUI balance as a display string

  // ── Computed ──────────────────────────────────────────────
  // computed() derives a value from other refs and auto-updates.
  // shortAddrDisplay recalculates whenever address.value changes.
  const shortAddrDisplay = computed(() => shortAddr(address.value))

  // ── Actions ───────────────────────────────────────────────
  /**
   * connect()
   * Called when the user clicks "Connect Wallet".
   * Sets connecting = true so the button shows "Connecting..."
   * and is disabled to prevent double-clicks.
   */
  async function connect() {
    connecting.value   = true
    connectError.value = null

    try {
      const result = await connectSlush() // wallet popup appears here

      // markRaw prevents Vue from proxying the SDK objects
      wallet.value  = markRaw(result.wallet)
      account.value = markRaw(result.account)
      address.value = result.address
      balance.value = result.balance
      connected.value = true             // switches the UI to the dashboard

      // Fetch balance again after 2s — the first fetch can return stale
      // cached data from the RPC. A delayed second fetch gets fresh data.
      setTimeout(async () => {
        balance.value = await fetchBalance(address.value)
      }, 2000)

    } catch (err) {
      // Show the error below the connect button
      connectError.value = err.message
    } finally {
      // Always stop the loading state, even if there was an error
      connecting.value = false
    }
  }

  /**
   * refreshBalance()
   * Re-fetches the SUI balance after a buy or open transaction
   * so the header shows the updated amount.
   */
  async function refreshBalance() {
    if (!address.value) return
    balance.value = await fetchBalance(address.value)
  }

  return {
    // State (expose as-is for template binding)
    connected, connecting, connectError,
    wallet, account, address, balance,
    // Computed
    shortAddrDisplay,
    // Actions
    connect, refreshBalance,
  }
}