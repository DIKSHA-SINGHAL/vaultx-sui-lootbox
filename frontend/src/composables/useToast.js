/**
 * composables/useToast.js
 * ─────────────────────────────────────────────────────────────
 * A tiny notification system ("toast" messages).
 *
 * Usage from any component:
 *   const { toast, showToast } = useToast()
 *   showToast('Box purchased!', 'success')
 *   showToast('Transaction failed', 'error')
 *
 * The toast auto-dismisses after 3 seconds.
 */

import { ref } from 'vue'

export function useToast() {
  // toast is null when hidden, or { message, type } when visible
  const toast = ref(null)

  let timer = null  // store the timeout ID so we can cancel it

  /**
   * showToast(message, type)
   * @param {string} message - text to display
   * @param {'success'|'error'} type - controls the colour
   */
  function showToast(message, type = 'success') {
    // Cancel any existing dismiss timer so rapid toasts don't overlap
    if (timer) clearTimeout(timer)

    toast.value = { message, type }

    // Auto-dismiss after 3 seconds
    timer = setTimeout(() => {
      toast.value = null
    }, 3000)
  }

  return { toast, showToast }
}