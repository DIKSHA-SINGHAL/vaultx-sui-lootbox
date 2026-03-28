<!--
  NavTabs.vue
  ─────────────────────────────────────────────────────────────
  Tab bar with: Buy Box | Unopened (n) | My NFTs (n) | Rulebook

  HOW TABS WORK:
  The parent (Dashboard.vue) holds a `activeTab` ref (a string).
  NavTabs receives it as a prop and emits 'change' with the new
  tab name when the user clicks. Dashboard updates activeTab,
  which shows/hides the right section via v-show.

  WHY v-show INSTEAD OF v-if?
  v-if destroys and recreates the DOM on every switch.
  v-show just toggles display:none — the component stays mounted
  so scroll positions and state are preserved when switching back.
-->
<template>
  <div class="nav-tabs">
    <button
      v-for="tab in tabs"
      :key="tab.id"
      :class="['nav-tab', { active: activeTab === tab.id }]"
      @click="$emit('change', tab.id)"
    >
      {{ tab.label }}
      <!-- Badge showing count (boxes or NFTs) -->
      <span v-if="tab.count !== null" class="badge-count">
        {{ tab.count }}
      </span>
    </button>
  </div>
</template>

<script>
import { computed } from 'vue'

export default {
  name: 'NavTabs',

  props: {
    activeTab:  { type: String, required: true },
    boxCount:   { type: Number, default: 0 },
    nftCount:   { type: Number, default: 0 },
  },

  emits: ['change'],

  setup(props) {
    // Build the tab list dynamically so counts stay reactive
    const tabs = computed(() => [
      { id: 'buy',      label: 'Buy Box',   count: null },
      { id: 'boxes',    label: 'Unopened',  count: props.boxCount },
      { id: 'nfts',     label: 'My NFTs',   count: props.nftCount },
      { id: 'rulebook', label: 'Rulebook',  count: null },
    ])
    return { tabs }
  },
}
</script>

<style scoped>
.nav-tabs {
  display: flex;
  gap: 0;
  border-bottom: 1px solid rgba(255,255,255,0.07);
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
}

.nav-tab {
  padding: 0.65rem 1.1rem;
  font-family: 'Exo 2', sans-serif;
  font-size: 0.8rem;
  font-weight: 500;
  letter-spacing: 0.08em;
  color: #9090a8;
  background: none;
  border: none;
  cursor: pointer;
  /* The active indicator is a bottom border on the button itself */
  border-bottom: 2px solid transparent;
  margin-bottom: -1px; /* overlap the container's border-bottom */
  transition: color 0.15s, border-color 0.15s;
  text-transform: uppercase;
  white-space: nowrap;
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.nav-tab:hover { color: #e8e8f0; }

/* Active tab: green text + green underline */
.nav-tab.active {
  color: #00ff88;
  border-bottom-color: #00ff88;
}

/* Count badge (e.g. "3" on Unopened tab) */
.badge-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: #00ff88;
  color: #000;
  font-size: 0.62rem;
  font-weight: 700;
  border-radius: 10px;
  min-width: 18px;
  height: 16px;
  padding: 0 4px;
}
</style>