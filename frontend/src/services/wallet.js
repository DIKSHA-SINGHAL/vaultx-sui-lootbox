/**
 * services/wallet.js
 * ─────────────────────────────────────────────────────────────
 * Handles wallet connection and balance fetching.
 *
 * WHAT IS A WALLET SERVICE?
 * The browser doesn't know anything about Sui by default.
 * A wallet extension (like Slush) injects itself into the page
 * and registers under the @mysten/wallet-standard interface.
 * This file talks to that extension to connect and read data.
 *
 * WHY SEPARATE FROM GAME LOGIC?
 * Wallet logic (connect, disconnect, fetch balance) is completely
 * different from game logic (buy box, open box). Splitting them
 * keeps each file small and focused.
 */

import { getWallets } from '@mysten/wallet-standard'
import { client }     from '../config/sui.js'
import { mistsToSui } from '../utils/format.js'

/**
 * connectSlush()
 * Asks the Slush wallet extension to connect to VaultX.
 *
 * HOW WALLET STANDARD WORKS:
 * 1. Slush registers itself as a "standard wallet" in the browser.
 * 2. getWallets().get() returns a list of all registered wallets.
 * 3. We find the one named "Slush" and call .connect() on it.
 * 4. After connect(), wallet.accounts[0] contains the user's
 *    active address and public key.
 *
 * @returns {{ wallet, account, address, balance }}
 * @throws  if Slush is not installed or user rejects the popup
 */
export async function connectSlush() {
  // Get the list of all wallets registered in the browser
  const walletList = getWallets().get()

  // Find Slush specifically (could also support Sui Wallet, Phantom, etc.)
  const slush = walletList.find(w => w.name === 'Slush')
  if (!slush) {
    throw new Error('Slush wallet not found. Please install it at slush.app')
  }

  // Trigger the "connect" popup in the user's wallet extension
  await slush.features['standard:connect'].connect()

  // After approval, accounts[0] is the user's primary account
  const account = slush.accounts[0]
  const address = account.address

  // Fetch the current SUI balance for this address
  const balance = await fetchBalance(address)

  // Return everything the app needs about the connected wallet
  return { wallet: slush, account, address, balance }
}

/**
 * fetchBalance(address)
 * Reads the SUI coin balance for a given wallet address from the
 * Sui RPC node. This is a READ — it costs no gas.
 *
 * client.getBalance() returns the total in MIST (the smallest
 * unit, like satoshis).  We divide by 1e9 to get SUI.
 *
 * @param {string} address - Sui wallet address
 * @returns {string}       - e.g. "0.4507"
 */
export async function fetchBalance(address) {
  const data = await client.getBalance({ owner: address })
  return mistsToSui(data.totalBalance)
}