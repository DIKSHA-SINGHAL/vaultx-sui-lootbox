<!--
  ItemCard.vue
  ─────────────────────────────────────────────────────────────
  Revamped NFT card:
  - Per-tier gradient background (dark tint fading to black)
  - Emoji + item name picked deterministically from items.js
  - Contract name shown small above the item name
  - Transfer + Burn in mini (collection grid) mode
-->
<template>
  <div
    :class="['game-card', rarityData.key, size === 'mini' ? 'mini' : '']"
    @click="size !== 'mini' && clickable && $emit('click', item)"
    :style="size !== 'mini' && clickable ? 'cursor:pointer' : ''"
  >
    <!-- Tier badge + power -->
    <div class="card-top">
      <div :class="['tier-tag', rarityData.key]">{{ rarityData.label }}</div>
      <div class="card-power">⚡ {{ item.power }}</div>
    </div>

    <!-- Emoji -->
    <div class="card-icon">{{ pickedItem.emoji }}</div>

    <!-- Contract name (from chain) — small muted -->
    <div class="card-id">{{ item.name }}</div>

    <!-- Human item name (from pool) — bold -->
    <div class="card-name">{{ pickedItem.name }}</div>

    <!-- Flavour subname — large mode only -->
    <div v-if="size !== 'mini'" class="card-subname">{{ pickedItem.subname }}</div>

    <!-- Origin box — large mode only -->
    <div v-if="size !== 'mini'" class="card-origin">Origin box #{{ item.originBox }}</div>

    <!-- Action buttons — mini mode only -->
    <div v-if="size === 'mini'" class="card-actions">
      <button class="btn btn-transfer" @click.stop="$emit('clickTransfer', item)">Transfer</button>
      <button class="btn btn-burn"     @click.stop="$emit('clickBurn', item)">Burn</button>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue'
import { getRarity } from '../config/rarity.js'
import { pickItem }  from '../config/items.js'

export default {
  name: 'ItemCard',
  props: {
    item:      { type: Object,  required: true },
    size:      { type: String,  default: 'large' },
    clickable: { type: Boolean, default: false },
  },
  emits: ['click', 'clickTransfer', 'clickBurn'],
  setup(props) {
    const rarityData = computed(() => getRarity(props.item.rarity))
    const pickedItem = computed(() => pickItem(props.item.rarity, props.item.id))
    return { rarityData, pickedItem }
  },
}
</script>

<style scoped>
.game-card {
  border-radius: 10px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: transform 0.2s;
}

.game-card:not(.mini) { padding: 14px 14px 12px; gap: 5px; }
.game-card.mini       { padding: 10px 10px 0; gap: 4px; }
.game-card.mini:hover { transform: translateY(-4px); }

/* Tier gradient backgrounds */
.game-card.common    { background: linear-gradient(160deg, #1e2228 0%, #0f0f14 100%); border: 1px solid rgba(136,153,170,0.35); }
.game-card.rare      { background: linear-gradient(160deg, #0a1830 0%, #0a0a14 100%); border: 1px solid rgba(68,136,255,0.5); }
.game-card.epic      { background: linear-gradient(160deg, #150a28 0%, #0a0a14 100%); border: 1px solid rgba(170,68,255,0.5); }
.game-card.legendary { background: linear-gradient(160deg, #1e1200 0%, #0a0a0a 100%); border: 1px solid rgba(255,170,0,0.6); animation: lgPulse 2.5s ease-in-out infinite; }

@keyframes lgPulse {
  0%,100% { box-shadow: 0 0 0 rgba(255,170,0,0); }
  50%      { box-shadow: 0 0 22px rgba(255,170,0,0.25); }
}

.card-top { display: flex; justify-content: space-between; align-items: center; }

.tier-tag {
  font-size: 10px; font-weight: 700;
  letter-spacing: 1.5px; text-transform: uppercase;
  padding: 3px 8px; border-radius: 3px;
}
.tier-tag.common    { color: #8899aa; background: rgba(136,153,170,0.12); }
.tier-tag.rare      { color: #4488ff; background: rgba(68,136,255,0.12); }
.tier-tag.epic      { color: #aa44ff; background: rgba(170,68,255,0.12); }
.tier-tag.legendary { color: #ffaa00; background: rgba(255,170,0,0.12); }

.card-power { font-size: 12px; color: #9090a8; font-weight: 600; }

.card-icon {
  font-size: 40px; line-height: 1;
  text-align: center;
  height: 52px;
  display: flex; align-items: center; justify-content: center;
  margin: 2px 0;
}

.card-id   { font-size: 10px; color: #555570; text-align: center; }
.card-name { font-family: 'Rajdhani', sans-serif; font-size: 15px; font-weight: 700; color: #e8e8f0; text-align: center; }
.card-subname { font-size: 11px; color: #9090a8; font-style: italic; text-align: center; opacity: 0.7; }
.card-origin  { font-size: 10px; color: #444460; text-align: center; }

.card-actions { display: flex; gap: 6px; padding: 8px 0 10px; margin-top: 2px; }

.btn {
  flex: 1; padding: 5px 4px;
  font-size: 11px; font-weight: 500;
  border-radius: 3px; cursor: pointer;
  text-align: center; font-family: inherit;
  letter-spacing: 0.3px; transition: all 0.15s;
}
.btn-transfer { background: none; border: 1px solid rgba(255,255,255,0.12); color: rgba(200,200,220,0.6); }
.btn-transfer:hover { border-color: #4488ff; color: #4488ff; }
.btn-burn     { background: none; border: 1px solid rgba(255,60,60,0.2); color: rgba(255,100,100,0.5); }
.btn-burn:hover { border-color: rgba(255,60,60,0.6); color: #ff6464; }
</style>