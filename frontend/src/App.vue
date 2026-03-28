<!--
  App.vue
  ─────────────────────────────────────────────────────────────
  Root component. Single responsibility: switch between the
  landing screen and the dashboard when wallet connects.

  If your app is still showing the OLD layout, it means this
  file was the old monolithic App.vue. Replace it with this.
-->
<template>
  <div class="app">
    <LandingScreen
      v-if="!wallet.connected.value"
      :connecting="wallet.connecting.value"
      :connect-error="wallet.connectError.value"
      @connect="wallet.connect"
    />

    <Dashboard
      v-else
      :wallet="wallet"
    />
  </div>
</template>

<script>
import { useWallet }    from './composables/useWallet.js'
import LandingScreen    from './components/LandingScreen.vue'
import Dashboard        from './views/Dashboard.vue'

export default {
  name: 'App',
  components: { LandingScreen, Dashboard },

  setup() {
    const wallet = useWallet()
    return { wallet }
  },
}
</script>

<style>
* { margin: 0; padding: 0; box-sizing: border-box; }

.app {
  min-height: 100vh;
  background: #0a0a0f;
  display: flex;
  flex-direction: column;
  font-family: 'Exo 2', 'Inter', sans-serif;
  color: #e8e8f0;
}
</style>