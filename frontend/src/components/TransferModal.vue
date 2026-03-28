<!--
  TransferModal.vue
  ─────────────────────────────────────────────────────────────
  Overlay modal that appears when the user clicks Transfer on an NFT.
  Collects the recipient wallet address, validates it, then emits
  'confirm' upward so Dashboard.vue can run the actual transaction.

  WHY VALIDATE HERE?
  Cheap client-side check before sending to chain. Sui addresses
  start with 0x and are 66 characters total. If it fails this
  check it will definitely fail on-chain — save the user gas.
-->
<template>
  <div class="overlay" @click.self="$emit('close')">
    <div class="modal">

      <div class="modal-top">
        <span class="modal-title">Transfer Item</span>
        <button class="close-btn" @click="$emit('close')">✕</button>
      </div>

      <!-- Show which item is being transferred -->
      <div class="item-reminder">{{ item.name }}</div>

      <!-- Recipient address input -->
      <input
        v-model="recipient"
        type="text"
        class="addr-input"
        placeholder="Recipient wallet address (0x...)"
        @keyup.enter="submit"
      />

      <!-- Validation error shown inline -->
      <div v-if="error" class="input-error">{{ error }}</div>

      <div class="modal-actions">
        <button class="modal-btn secondary" @click="$emit('close')">Cancel</button>
        <button class="modal-btn primary" @click="submit">Transfer</button>
      </div>

    </div>
  </div>
</template>

<script>
import { ref } from 'vue'

export default {
  name: 'TransferModal',

  props: {
    item: { type: Object, required: true },
  },

  emits: ['close', 'confirm'],

  setup(props, { emit }) {
    const recipient = ref('')
    const error     = ref(null)

    function submit() {
      const addr = recipient.value.trim()

      // Sui addresses: 0x + 64 hex chars = 66 chars total
      if (!addr.startsWith('0x') || addr.length < 10) {
        error.value = 'Enter a valid 0x... Sui wallet address'
        return
      }

      error.value = null
      // Let the parent (Dashboard.vue) handle the actual transaction
      emit('confirm', props.item, addr)
    }

    return { recipient, error, submit }
  },
}
</script>

<style scoped>
.overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.8);
  backdrop-filter: blur(6px);
  display: flex; align-items: center; justify-content: center;
  z-index: 200;
  padding: 20px;
}

.modal {
  background: var(--raised, #141416);
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 16px;
  padding: 24px;
  width: 100%; max-width: 360px;
  animation: fadeUp 0.25s ease forwards;
}

@keyframes fadeUp {
  from { opacity:0; transform:translateY(8px); }
  to   { opacity:1; transform:translateY(0); }
}

.modal-top {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 16px;
}

.modal-title {
  font-size: 0.68rem; font-weight: 700;
  letter-spacing: 2px; text-transform: uppercase;
  color: var(--grey2, #5a5a64);
}

.close-btn {
  background: none; border: none;
  color: var(--grey2, #5a5a64); cursor: pointer;
  font-size: 1rem; line-height: 1; transition: color 0.15s;
}
.close-btn:hover { color: white; }

.item-reminder {
  font-size: 0.85rem; font-weight: 600;
  color: var(--grey1, #a0a0a8);
  margin-bottom: 14px;
  padding: 8px 10px;
  background: var(--surface, #0e0e10);
  border: 1px solid rgba(255,255,255,0.07);
  border-radius: 6px;
}

.addr-input {
  width: 100%;
  background: var(--surface, #0e0e10);
  border: 1px solid rgba(255,255,255,0.12);
  color: white;
  padding: 0.65rem 0.9rem;
  border-radius: 6px;
  font-size: 0.82rem;
  font-family: monospace;
  margin-bottom: 6px;
  transition: border-color 0.15s;
}
.addr-input:focus { outline: none; border-color: var(--green, #39ff6e); }

.input-error { font-size: 0.75rem; color: #f87171; margin-bottom: 10px; }

.modal-actions { display: flex; gap: 0.6rem; margin-top: 14px; }

.modal-btn {
  flex: 1; padding: 0.65rem;
  border-radius: 6px;
  font-size: 0.85rem; font-weight: 600;
  cursor: pointer; transition: all 0.15s;
  font-family: inherit;
}

.modal-btn.primary  { background: var(--green, #39ff6e); color: #000; border: none; }
.modal-btn.primary:hover { background: #4dffa0; }

.modal-btn.secondary {
  background: none;
  border: 1px solid rgba(255,255,255,0.12);
  color: var(--grey2, #5a5a64);
}
.modal-btn.secondary:hover { border-color: rgba(255,255,255,0.4); color: white; }
</style>