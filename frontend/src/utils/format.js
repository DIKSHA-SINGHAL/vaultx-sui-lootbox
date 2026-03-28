/**
 * utils/format.js
 * ─────────────────────────────────────────────────────────────
 * Pure helper functions that format data for display.
 * "Pure" = no side effects, no imports, just input → output.
 *
 * Keeping these separate from components means we can test them
 * easily and reuse them anywhere without importing a whole component.
 */

/**
 * shortAddr(address)
 * Shortens a full Sui wallet address for display in the header.
 * "0xf97d...bd9a" is friendlier than the full 66-char string.
 *
 * @param {string} address - full 0x... Sui address
 * @returns {string}       - e.g. "0xf97d…bd9a"
 */
export function shortAddr(address) {
    if (!address) return ''
    // Keep first 6 chars (includes "0x") and last 4 chars
    return address.slice(0, 6) + '…' + address.slice(-4)
  }
  
  /**
   * fmtDate(timestampMs)
   * Converts a blockchain epoch timestamp (milliseconds) to a
   * human-readable local date string.
   *
   * The contract stores clock::timestamp_ms() — milliseconds since
   * Unix epoch, same as JavaScript's Date.now().
   *
   * @param {number|string} ts - timestamp in milliseconds
   * @returns {string}         - e.g. "3/25/2026"
   */
  export function fmtDate(ts) {
    return new Date(Number(ts)).toLocaleDateString()
  }
  
  /**
   * mistsToSui(mist)
   * Converts a MIST amount (what the blockchain stores) to SUI (what
   * users understand).  1 SUI = 1,000,000,000 MIST.
   *
   * @param {number|string} mist
   * @returns {string}            - e.g. "0.4507"
   */
  export function mistsToSui(mist) {
    return (Number(mist) / 1_000_000_000).toFixed(4)
  }