<!--
  LandingScreen.vue
-->
<template>
  <div class="connect-screen">
    <div class="bg-grid"></div>
    <div class="bg-radial"></div>

    <div class="connect-inner">
      <div class="logo">VAULTX</div>
      <p class="sub">On-chain loot boxes. Verifiable randomness.</p>

      <button
        class="connect-btn"
        :disabled="connecting"
        @click="$emit('connect')"
      >
        {{ connecting ? 'Connecting...' : '⬡ Connect Wallet' }}
      </button>

      <p v-if="connectError" class="err">{{ connectError }}</p>
      <p class="footnote">No signup. Your wallet is your identity.</p>

      <div class="trust-row">
        <div class="badge"><div class="badge-dot"></div> Provably fair</div>
        <div class="badge"><div class="badge-dot"></div> On-chain random</div>
        <div class="badge"><div class="badge-dot"></div> Non-custodial</div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'LandingScreen',
  props: {
    connecting:   { type: Boolean, default: false },
    connectError: { type: String,  default: null },
  },
  emits: ['connect'],
}
</script>

<style scoped>
.connect-screen {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  background: #0a0a0f;
}

.bg-grid {
  position: absolute; inset: 0;
  background-image:
    linear-gradient(rgba(0,255,136,0.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0,255,136,0.04) 1px, transparent 1px);
  background-size: 40px 40px;
  mask-image: radial-gradient(ellipse 80% 80% at 50% 50%, black 30%, transparent 100%);
  -webkit-mask-image: radial-gradient(ellipse 80% 80% at 50% 50%, black 30%, transparent 100%);
}

.bg-radial {
  position: absolute; inset: 0;
  background: radial-gradient(ellipse 60% 50% at 50% 40%, rgba(0,255,136,0.06) 0%, transparent 70%);
}

.connect-inner {
  position: relative;
  z-index: 1;
  text-align: center;
  padding: 2rem;
  max-width: 520px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.logo {
  font-family: 'Rajdhani', 'Exo 2', sans-serif;
  font-size: clamp(3rem, 10vw, 5.5rem);
  font-weight: 700;
  letter-spacing: 0.15em;
  color: #00ff88;
  text-shadow: 0 0 40px rgba(0,255,136,0.4);
  margin-bottom: 0.25rem;
  animation: pulseGlow 3s ease-in-out infinite;
}

@keyframes pulseGlow {
  0%,100% { text-shadow: 0 0 30px rgba(0,255,136,0.3); }
  50%      { text-shadow: 0 0 60px rgba(0,255,136,0.6), 0 0 100px rgba(0,255,136,0.2); }
}

.sub {
  color: #9090a8;
  font-size: 1rem;
  letter-spacing: 0.05em;
  font-weight: 300;
  margin-bottom: 0.5rem;
}

.connect-btn {
  background: #00ff88;
  color: #000;
  border: 2px solid #00ff88;
  padding: 0.9rem 2.5rem;
  font-family: 'Rajdhani', 'Exo 2', sans-serif;
  font-size: 1.1rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.2s;
  margin-bottom: 0.5rem;
  min-width: 220px;
}

.connect-btn:hover:not(:disabled) {
  background: transparent;
  color: #00ff88;
  border-color: #00ff88;
  box-shadow: 0 0 30px rgba(0,255,136,0.35), inset 0 0 20px rgba(0,255,136,0.05);
  transform: translateY(-2px);
}

.connect-btn:active:not(:disabled) { transform: translateY(0); }
.connect-btn:disabled { opacity: 0.5; cursor: not-allowed; }

.footnote { font-size: 0.8rem; color: #9090a8; letter-spacing: 0.03em; }

.trust-row {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
  margin-top: 0.25rem;
}

.badge {
  display: flex; align-items: center; gap: 0.4rem;
  color: #9090a8; font-size: 0.78rem; letter-spacing: 0.08em;
  padding: 0.4rem 0.8rem;
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 2px;
  background: rgba(255,255,255,0.02);
}

.badge-dot {
  width: 6px; height: 6px;
  background: #00ff88;
  border-radius: 50%;
  flex-shrink: 0;
}

.err { font-size: 0.8rem; color: #f87171; }
</style>