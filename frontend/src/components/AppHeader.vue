<!--
  AppHeader.vue
  Sticky top bar: VAULTX logo | wallet address | SUI balance (with refresh)
-->
<template>
  <header class="header">

    <div class="logo">VAULTX</div>

    <div class="header-right">

      <div class="pill wallet-pill">
        <span class="live-dot"></span>
        <span class="addr">{{ shortAddr }}</span>
      </div>

      <div class="pill balance-pill" @click="$emit('refresh')" title="Click to refresh balance">
        <span class="balance-num">{{ balance }}</span>
        <span class="balance-unit">SUI</span>
        <span class="refresh-icon">↻</span>
      </div>

    </div>
  </header>
</template>

<script>
export default {
  name: 'AppHeader',
  props: {
    shortAddr: { type: String, required: true },
    balance:   { type: String, required: true },
  },
  emits: ['refresh'],
}
</script>

<style scoped>
.header {
  height: 54px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 1.5rem;
  background: #0f0f1a;
  border-bottom: 1px solid rgba(255,255,255,0.07);
  position: sticky;
  top: 0;
  z-index: 50;
  flex-shrink: 0;
}

.logo {
  font-family: 'Rajdhani', sans-serif;
  font-size: 1.15rem;
  font-weight: 700;
  letter-spacing: 0.2em;
  color: #00ff88;
  text-shadow: 0 0 20px rgba(0,255,136,0.3);
}

.header-right { display: flex; align-items: center; gap: 0.6rem; }

.pill {
  display: flex; align-items: center; gap: 0.45rem;
  padding: 0.3rem 0.85rem;
  background: #141422;
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 3px;
}

.wallet-pill:hover { border-color: rgba(0,255,136,0.3); }

.live-dot {
  width: 7px; height: 7px;
  background: #00ff88;
  border-radius: 50%;
  flex-shrink: 0;
  animation: dotPulse 2s ease-in-out infinite;
}

@keyframes dotPulse {
  0%,100% { box-shadow: 0 0 4px rgba(0,255,136,0.5); }
  50%      { box-shadow: 0 0 10px rgba(0,255,136,1); }
}

.addr {
  color: #9090a8;
  font-family: monospace;
  font-size: 0.75rem;
}

/* Balance pill — clickable to refresh */
.balance-pill {
  border-color: rgba(0,255,136,0.15);
  cursor: pointer;
  transition: border-color 0.2s;
}
.balance-pill:hover { border-color: rgba(0,255,136,0.5); }

.balance-num {
  color: #00ff88;
  font-family: 'Rajdhani', sans-serif;
  font-size: 1rem;
  font-weight: 600;
  line-height: 1;
}

.balance-unit {
  color: #9090a8;
  font-size: 0.68rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.refresh-icon {
  color: rgba(0,255,136,0.4);
  font-size: 0.8rem;
  transition: color 0.2s;
}
.balance-pill:hover .refresh-icon { color: #00ff88; }
</style>