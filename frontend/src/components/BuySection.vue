<!--
  BuySection.vue
  ─────────────────────────────────────────────────────────────
  "Get a Box" card + drop rate bars.

  THE BAR WIDTH FIX:
  Previously the bars used CSS width with percentage values that
  weren't being passed correctly. Now each bar gets its width
  directly from the rarity's .pct property via inline style,
  so Common = 60%, Rare = 25%, Epic = 12%, Legendary = 3%.
-->
<template>
  <div class="section">
    <div class="section-label">Get a Box</div>

    <!-- Buy card -->
    <div
      class="buy-card"
      :class="{ 'buying-active': buying }"
      @click="!buying && $emit('buy')"
    >
      <div class="buy-left">
        <div class="buy-icon">📦</div>
        <div>
          <div class="buy-title">Loot Box</div>
          <div class="buy-sub">Random NFT card inside • Provably fair on-chain roll</div>
        </div>
      </div>
      <div class="buy-right">
        <div class="buy-price">0.1 <span class="price-unit">SUI</span></div>
        <button
          class="buy-btn"
          :class="{ disabled: buying }"
          :disabled="buying"
          @click.stop="!buying && $emit('buy')"
        >
          {{ buying ? '...' : 'BUY NOW' }}
        </button>
      </div>
    </div>

    <!-- Drop rates -->
    <div class="rate-card">
      <div class="section-label" style="margin-bottom: 14px">Drop Rates</div>

      <div v-for="r in rarities" :key="r.label" class="rate-row">
        <div class="rate-top">
          <span :style="{ color: r.color, fontWeight: 600 }">{{ r.label }}</span>
          <span class="rate-pct">{{ r.pct }}%</span>
        </div>
        <div class="rate-track">
          <!--
            Width is set directly from r.pct (a number like 60).
            We convert it to a percentage string: "60%"
            This is the fix — previously the width wasn't applying correctly.
          -->
          <div
            class="rate-fill"
            :style="{ width: r.pct + '%', background: r.color }"
          ></div>
        </div>
      </div>
    </div>

    <!-- Pity system info -->
    <div class="rate-card">
      <div class="section-label" style="margin-bottom: 10px">Pity System</div>
      <div class="pity-row">
        <div class="pity-star">★</div>
        <span>
          After 30 consecutive non-Legendary opens, your next box is
          <span style="color: #ffaa00; font-weight: 600">guaranteed Legendary</span>.
          Counter resets on any Legendary drop.
        </span>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'BuySection',
  props: {
    buying:   { type: Boolean, default: false },
    rarities: { type: Array,   required: true },
  },
  emits: ['buy'],
}
</script>

<style scoped>
.section { display: flex; flex-direction: column; gap: 14px; }

.section-label {
  font-size: 0.72rem;
  font-weight: 600;
  letter-spacing: 0.15em;
  color: #9090a8;
  text-transform: uppercase;
}

/* ── Buy card ────────────────────────────────────── */
.buy-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.4rem 1.5rem;
  background: #141422;
  border: 1px solid rgba(255,255,255,0.07);
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.15s;
  position: relative;
  overflow: hidden;
}

/* Top green accent line */
.buy-card::before {
  content: '';
  position: absolute; top: 0; left: 0; right: 0; height: 2px;
  background: linear-gradient(90deg, transparent, #00ff88, transparent);
}

.buy-card:hover:not(.buying-active) {
  border-color: rgba(0,255,136,0.3);
  box-shadow: 0 0 24px rgba(0,255,136,0.08);
}

.buy-card.buying-active { opacity: 0.6; cursor: not-allowed; }

.buy-left  { display: flex; align-items: center; gap: 1rem; }
.buy-icon  { font-size: 2.5rem; line-height: 1; }
.buy-title { font-weight: 700; font-size: 1rem; margin-bottom: 3px; }
.buy-sub   { font-size: 0.78rem; color: #9090a8; }

.buy-right {
  display: flex; flex-direction: column;
  align-items: flex-end; gap: 10px;
}

.buy-price {
  font-size: 1.8rem; font-weight: 700;
  color: #00ff88;
  font-family: 'Rajdhani', sans-serif;
}
.price-unit { font-size: 0.8rem; color: #9090a8; }

.buy-btn {
  background: #00ff88; color: #000;
  border: none;
  padding: 0.6rem 1.4rem;
  font-family: 'Rajdhani', sans-serif;
  font-size: 0.95rem; font-weight: 700;
  letter-spacing: 0.08em;
  cursor: pointer; border-radius: 3px;
  transition: all 0.15s;
}
.buy-btn:hover:not(.disabled) { background: #00ffaa; box-shadow: 0 4px 20px rgba(0,255,136,0.3); }
.buy-btn.disabled { opacity: 0.5; cursor: not-allowed; }

/* ── Drop rate card ───────────────────────────────── */
.rate-card {
  background: #141422;
  border: 1px solid rgba(255,255,255,0.07);
  border-radius: 10px;
  padding: 1.2rem 1.5rem;
}

.rate-row { margin-bottom: 12px; }
.rate-row:last-child { margin-bottom: 0; }

.rate-top {
  display: flex; justify-content: space-between;
  font-size: 0.82rem; margin-bottom: 5px;
}

.rate-pct { color: #9090a8; }

/* The track (grey bg) and the coloured fill bar */
.rate-track {
  height: 5px;
  background: rgba(255,255,255,0.06);
  border-radius: 10px;
  overflow: hidden;
}

.rate-fill {
  height: 100%;
  border-radius: 10px;
  /* Width is set via inline :style binding in the template */
  transition: width 0.6s ease;
}

/* ── Pity row ─────────────────────────────────────── */
.pity-row {
  display: flex; align-items: flex-start; gap: 0.75rem;
  font-size: 0.85rem; color: #9090a8; line-height: 1.5;
}

.pity-star {
  width: 20px; height: 20px; flex-shrink: 0;
  background: rgba(0,255,136,0.08);
  border: 1px solid rgba(0,255,136,0.2);
  border-radius: 3px;
  display: flex; align-items: center; justify-content: center;
  font-size: 0.75rem; font-weight: 700; color: #00ff88;
}
</style>