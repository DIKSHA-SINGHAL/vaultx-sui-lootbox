<!--
  CollectionSection.vue
  ─────────────────────────────────────────────────────────────
  Grid of all NFTs. The card handles its own colour now (gradient
  background per tier) so we no longer need the nft-wrap + strip
  wrapper that the old version used.
-->
<template>
  <div class="section" v-if="gameItems.length > 0">

    <div class="section-label">
      My NFTs
      <span class="count-badge">{{ gameItems.length }}</span>
    </div>

    <div class="cards-grid">
      <ItemCard
        v-for="item in gameItems"
        :key="item.id"
        :item="item"
        size="mini"
        :clickable="true"
        @click="$emit('view-item', $event)"
        @click-transfer="$emit('transfer', $event)"
        @click-burn="$emit('burn', $event)"
      />
    </div>

  </div>
</template>

<script>
import ItemCard from './ItemCard.vue'

export default {
  name: 'CollectionSection',
  components: { ItemCard },
  props: {
    gameItems: { type: Array, required: true },
  },
  emits: ['transfer', 'burn', 'view-item'],
}
</script>

<style scoped>
.section { display: flex; flex-direction: column; gap: 12px; }

.section-label {
  font-size: 0.68rem; font-weight: 600;
  letter-spacing: 2px; text-transform: uppercase;
  color: var(--grey2, #5a5a64);
  display: flex; align-items: center; gap: 8px;
}

.count-badge {
  background: #00ff88; color: #000;
  font-size: 0.6rem; font-weight: 700;
  padding: 1px 7px; border-radius: 999px;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 12px;
}
</style>