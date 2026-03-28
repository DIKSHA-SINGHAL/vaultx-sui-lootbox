<!--
  BoxesSection.vue
  ─────────────────────────────────────────────────────────────
  Shows the list of unopened loot boxes and the open animation.

  STAGE MACHINE:
  This component renders different UI based on the `stage` prop:
    - idle:    list of boxes with "Open →" buttons
    - opening: spinning box, waiting for tx confirmation
    - rolling: cycling 0-99 number (dice animation)
    - reveal:  the minted NFT card + action buttons
-->
<template>
  <!-- v-if: only show this section if there are boxes OR we're mid-animation -->
  <div class="section" v-if="lootBoxes.length > 0 || stage !== 'idle'">

    <!-- Section title with live box count badge -->
    <div class="section-label">
      Unopened
      <span class="count-badge">{{ lootBoxes.length }}</span>
    </div>

    <!-- ── IDLE: list of boxes ───────────────────────────── -->
    <div v-if="stage === 'idle'" class="box-list">
      <div
        v-for="box in lootBoxes"
        :key="box.id"
        class="box-row"
        :class="{ disabled: opening }"
        @click="!opening && $emit('open', box)"
      >
        <div class="box-row-left">
          <!-- Green numbered badge -->
          <div class="box-num-badge">{{ box.boxNumber }}</div>
          <div>
            <div class="box-title">Box #{{ box.boxNumber }}</div>
            <div class="box-date">{{ fmtDate(box.purchasedAt) }}</div>
          </div>
        </div>
        <div class="open-chip">{{ opening ? '...' : 'Open →' }}</div>
      </div>
    </div>

    <!-- ── OPENING: tx in flight ─────────────────────────── -->
    <div v-else-if="stage === 'opening'" class="anim-card">
      <div class="anim-box">📦</div>
      <div class="anim-label">Opening box...</div>
    </div>

    <!-- ── ROLLING: dice animation ───────────────────────── -->
    <div v-else-if="stage === 'rolling'" class="anim-card">
      <div class="roll-num mono">{{ displayRoll }}</div>
      <div class="anim-label">On-chain roll</div>
    </div>

    <!-- ── REVEAL: show the minted item ──────────────────── -->
    <div v-else-if="stage === 'reveal' && revealedItem" class="reveal-wrap">
      <!-- Reuse the ItemCard component in "large" mode -->
      <ItemCard :item="revealedItem" size="large" />
      <div class="reveal-actions">
        <button class="btn-cta" @click="$emit('dismiss')">Keep It</button>
        <button class="btn-ghost" @click="$emit('viewCollection')">View Collection</button>
      </div>
    </div>

  </div>
</template>

<script>
import { fmtDate } from '../utils/format.js'
import ItemCard    from './ItemCard.vue'

export default {
  name: 'BoxesSection',
  components: { ItemCard },

  props: {
    lootBoxes:   { type: Array,   required: true },
    stage:       { type: String,  default: 'idle' },
    opening:     { type: Boolean, default: false },
    displayRoll: { type: Number,  default: 0 },
    revealedItem:{ type: Object,  default: null },
  },

  emits: ['open', 'dismiss', 'viewCollection'],

  setup() {
    // Expose fmtDate to the template.
    // In the Options API (export default { ... }), you can also put
    // helpers in "methods" but setup() works for simple function imports.
    return { fmtDate }
  },
}
</script>

<style scoped>
.section { display: flex; flex-direction: column; gap: 12px; }

.section-label {
  font-size: 0.68rem;
  font-weight: 600;
  letter-spacing: 2px;
  text-transform: uppercase;
  color: var(--grey2);
  display: flex;
  align-items: center;
  gap: 8px;
}

.count-badge {
  background: var(--green);
  color: #000;
  font-size: 0.6rem;
  font-weight: 700;
  padding: 1px 7px;
  border-radius: 999px;
}

.box-list { display: flex; flex-direction: column; gap: 8px; }

.box-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  background: var(--raised);
  border: 1px solid var(--border);
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.15s;
}

.box-row:hover:not(.disabled) {
  border-color: var(--green);
  box-shadow: 0 0 14px rgba(57, 255, 110, 0.08);
}

.box-row.disabled { cursor: not-allowed; opacity: 0.5; }

.box-row-left { display: flex; align-items: center; gap: 12px; }

.box-num-badge {
  width: 36px;
  height: 36px;
  background: var(--green-dim);
  border: 1px solid rgba(57, 255, 110, 0.2);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--font-mono);
  font-size: 0.75rem;
  color: var(--green);
  font-weight: 700;
  flex-shrink: 0;
}

.box-title { font-size: 0.85rem; font-weight: 600; }
.box-date  { font-size: 0.7rem; color: var(--grey2); margin-top: 2px; }

.open-chip {
  padding: 6px 14px;
  border: 1px solid var(--border2);
  border-radius: 6px;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--green);
}

.box-row:hover:not(.disabled) .open-chip {
  border-color: var(--green);
  background: var(--green-dim);
}

/* ── Animation states ───────────────────────────── */
.anim-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48px;
  background: var(--raised);
  border: 1px solid var(--border);
  border-radius: 14px;
  gap: 16px;
  min-height: 200px;
}

.anim-box {
  font-size: 56px;
  animation: spinBox 0.5s linear infinite;
}

@keyframes spinBox {
  from { transform: rotateY(0deg); }
  to   { transform: rotateY(360deg); }
}

.anim-label {
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 3px;
  text-transform: uppercase;
  color: var(--grey2);
  animation: blink 1s ease-in-out infinite;
}

@keyframes blink { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }

.roll-num {
  font-size: 80px;
  font-weight: 700;
  color: var(--green);
  text-shadow: 0 0 40px rgba(57, 255, 110, 0.4);
  line-height: 1;
  font-family: var(--font-mono);
}

.reveal-wrap {
  display: flex;
  flex-direction: column;
  gap: 16px;
  animation: revealIn 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

@keyframes revealIn {
  from { opacity: 0; transform: scale(0.9) translateY(10px); }
  to   { opacity: 1; transform: scale(1) translateY(0); }
}

.reveal-actions { display: flex; gap: 10px; }

.btn-cta {
  flex: 1;
  padding: 12px 28px;
  background: var(--green);
  color: #000;
  font-weight: 700;
  font-size: 0.85rem;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
  font-family: var(--font-ui);
}

.btn-cta:hover { background: #4dffa0; }

.btn-ghost {
  flex: 1;
  padding: 11px 24px;
  background: transparent;
  color: var(--grey1);
  font-size: 0.82rem;
  font-weight: 500;
  border: 1px solid var(--border2);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s;
  font-family: var(--font-ui);
}

.btn-ghost:hover { border-color: var(--grey1); color: white; }
</style>