<!--
  ItemModal.vue
  Full-detail overlay for a selected NFT.
  Click the dark overlay or the X to close.
-->
<template>
  <div class="overlay" @click.self="$emit('close')">
    <div class="modal">

      <div class="modal-top">
        <span class="modal-title">Item Detail</span>
        <button class="close-btn" @click="$emit('close')">✕</button>
      </div>

      <ItemCard :item="item" size="large" style="margin-bottom:16px" />

      <div class="modal-stats">
        <div class="modal-stat">
          <span class="dim">Minted</span>
          <span class="mono">{{ fmtDate(item.mintedAt) }}</span>
        </div>
        <div class="modal-stat">
          <span class="dim">Rarity</span>
          <span :style="{ color: rarityData.color, fontWeight: 600 }">{{ rarityData.label }}</span>
        </div>
        <div class="modal-stat">
          <span class="dim">Power</span>
          <span class="mono">{{ item.power }}</span>
        </div>
        <div class="modal-stat" style="border-bottom:none">
          <span class="dim">Origin Box</span>
          <span class="mono">#{{ item.originBox }}</span>
        </div>
      </div>

      <button class="close-full" @click="$emit('close')">Close</button>

    </div>
  </div>
</template>

<script>
import { computed } from 'vue'
import { getRarity } from '../config/rarity.js'
import { fmtDate }   from '../utils/format.js'
import ItemCard       from './ItemCard.vue'

export default {
  name: 'ItemModal',
  components: { ItemCard },
  props: { item: { type: Object, required: true } },
  emits: ['close'],
  setup(props) {
    const rarityData = computed(() => getRarity(props.item.rarity))
    return { rarityData, fmtDate }
  },
}
</script>

<style scoped>
.overlay {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.85);
  backdrop-filter: blur(6px);
  display: flex; align-items: center; justify-content: center;
  z-index: 200; padding: 20px;
}

.modal {
  background: #141422;
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 14px;
  padding: 22px;
  width: 100%; max-width: 340px;
  animation: fadeUp 0.2s ease forwards;
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
  color: #9090a8;
}

.close-btn {
  background: none; border: none;
  color: #9090a8; cursor: pointer;
  font-size: 1rem; transition: color 0.15s;
}
.close-btn:hover { color: #e8e8f0; }

.modal-stats { display: flex; flex-direction: column; margin-bottom: 16px; }

.modal-stat {
  display: flex; justify-content: space-between;
  padding: 8px 0;
  border-bottom: 1px solid rgba(255,255,255,0.06);
  font-size: 0.8rem;
}

.dim  { color: #9090a8; }
.mono { font-family: monospace; color: #e8e8f0; }

.close-full {
  width: 100%; padding: 10px;
  background: none;
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 8px;
  color: #9090a8; font-size: 0.82rem;
  cursor: pointer; transition: all 0.15s;
  font-family: inherit;
}
.close-full:hover { border-color: #e8e8f0; color: #e8e8f0; }
</style>