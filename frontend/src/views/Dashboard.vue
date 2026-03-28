<!--
  views/Dashboard.vue
  Tabs: Buy Box | Unopened (n) | My NFTs (n) | Rulebook
-->
<template>
  <div class="dashboard">

    <AppHeader
      :short-addr="currentAddr"
      :balance="currentBalance"
      @refresh="handleRefresh"
    />

    <div class="scroll-body">
      <div class="col">

        <NavTabs
          :active-tab="activeTab"
          :box-count="inv.lootBoxes.value.length"
          :nft-count="inv.gameItems.value.length"
          @change="switchTab"
        />

        <!-- BUY TAB -->
        <div v-show="activeTab === 'buy'">
          <BuySection
            :buying="game.buying.value"
            :rarities="RARITIES"
            @buy="handleBuyAndSwitch"
          />
        </div>

        <!-- UNOPENED BOXES TAB -->
        <div v-show="activeTab === 'boxes'">
          <BoxesSection
            :loot-boxes="inv.lootBoxes.value"
            :stage="game.stage.value"
            :opening="game.opening.value"
            :display-roll="game.displayRoll.value"
            :revealed-item="game.revealedItem.value"
            @open="game.handleOpen"
            @dismiss="game.resetStage"
            @view-collection="switchTab('nfts')"
          />
          <div
            class="empty-screen"
            v-if="inv.lootBoxes.value.length === 0 && game.stage.value === 'idle' && !inv.loadingInv.value"
          >
            <div class="empty-icon">📭</div>
            <div class="empty-title">No unopened boxes</div>
            <button class="link-btn" @click="switchTab('buy')">Buy a box →</button>
          </div>
        </div>

        <!-- MY NFTS TAB -->
        <div v-show="activeTab === 'nfts'">
          <CollectionSection
            :game-items="inv.gameItems.value"
            @transfer="showTransferModal"
            @burn="confirmBurn"
            @view-item="viewingItem = $event"
          />
          <div
            class="empty-screen"
            v-if="inv.gameItems.value.length === 0 && !inv.loadingInv.value"
          >
            <div class="empty-icon">🃏</div>
            <div class="empty-title">No items yet</div>
            <button class="link-btn" @click="switchTab('boxes')">Open a box →</button>
          </div>
        </div>

        <!-- RULEBOOK TAB -->
        <div v-show="activeTab === 'rulebook'">
          <RulesTab />
        </div>

        <div v-if="inv.loadingInv.value" class="loading-row">
          Loading inventory...
        </div>

      </div>
    </div>

    <!-- Item detail modal — opens when a card is clicked -->
    <ItemModal
      v-if="viewingItem"
      :item="viewingItem"
      @close="viewingItem = null"
    />

    <!-- Transfer modal -->
    <TransferModal
      v-if="transferTarget"
      :item="transferTarget"
      @close="transferTarget = null"
      @confirm="handleTransfer"
    />

    <ToastNotification v-if="ui.toast.value" :toast="ui.toast.value" />

  </div>
</template>

<script>
import { ref }           from 'vue'
import { RARITIES }      from '../config/rarity.js'
import { useInventory }  from '../composables/useInventory.js'
import { useGameFlow }   from '../composables/useGameFlow.js'
import { useToast }      from '../composables/useToast.js'
import { transferItem, burnItem } from '../services/game.js'

import AppHeader         from '../components/AppHeader.vue'
import NavTabs           from '../components/NavTabs.vue'
import BuySection        from '../components/BuySection.vue'
import BoxesSection      from '../components/BoxesSection.vue'
import CollectionSection from '../components/CollectionSection.vue'
import RulesTab          from '../components/RulesTab.vue'
import ItemModal         from '../components/ItemModal.vue'
import TransferModal     from '../components/TransferModal.vue'
import ToastNotification from '../components/ToastNotification.vue'

export default {
  name: 'Dashboard',
  components: {
    AppHeader, NavTabs, BuySection, BoxesSection,
    CollectionSection, RulesTab,
    ItemModal, TransferModal, ToastNotification,
  },
  props: {
    wallet: { type: Object, required: true },
  },

  setup(props) {
    const activeTab      = ref('buy')
    const viewingItem    = ref(null)
    const transferTarget = ref(null)

    const ui   = useToast()
    const inv  = useInventory()
    const game = useGameFlow(
      props.wallet.wallet,
      props.wallet.account,
      props.wallet.address,
      inv.loadAll,
      props.wallet.refreshBalance,
      ui.showToast,
    )

    game.setGameItemsRef(inv.gameItems)
    inv.loadAll(props.wallet.address.value)

    function switchTab(name) {
      activeTab.value = name
      if (name !== 'boxes') game.resetStage()
    }

    async function handleBuyAndSwitch() {
      const bal = parseFloat(props.wallet.balance.value)
      if (bal < 0.115) {
        ui.showToast(`Insufficient balance — need 0.115 SUI, have ${bal.toFixed(4)}`, 'error')
        return
      }
      await game.handleBuy()
      activeTab.value = 'boxes'
    }

    function showTransferModal(item) {
      transferTarget.value = item
    }

    async function handleTransfer(item, addr) {
      transferTarget.value = null
      try {
        await transferItem(props.wallet.wallet.value, props.wallet.account.value, item.id, addr)
        ui.showToast('Transfer sent!', 'success')
        await inv.loadAll(props.wallet.address.value)
      } catch (e) {
        ui.showToast(e.message, 'error')
      }
    }

    async function confirmBurn(item) {
      if (!confirm(`Permanently burn ${item.name}? This cannot be undone.`)) return
      try {
        await burnItem(props.wallet.wallet.value, props.wallet.account.value, item.id)
        ui.showToast(`${item.name} burned.`, 'success')
        await inv.loadAll(props.wallet.address.value)
      } catch (e) {
        ui.showToast(e.message, 'error')
      }
    }

    async function handleRefresh() {
      await props.wallet.refreshBalance()
      // Balance updates silently — no toast needed
    }

    return {
      RARITIES,
      activeTab, switchTab,
      handleRefresh,
      // Expose balance as a direct computed so template stays reactive
      get currentBalance() { return props.wallet.balance.value },
      get currentAddr()    { return props.wallet.shortAddrDisplay.value },
      viewingItem, transferTarget,
      ui, inv, game,
      handleBuyAndSwitch,
      showTransferModal, handleTransfer, confirmBurn,
    }
  },
}
</script>

<style scoped>
.dashboard {
  min-height: 100vh;
  background: #0a0a0f;
  display: flex;
  flex-direction: column;
}

.scroll-body {
  flex: 1; overflow-y: auto;
  display: flex; justify-content: center;
  padding: 28px 20px 60px;
}

.col {
  width: 100%; max-width: 600px;
  display: flex; flex-direction: column;
}

.empty-screen {
  display: flex; flex-direction: column;
  align-items: center; gap: 12px;
  padding: 60px 0; text-align: center;
}
.empty-icon  { font-size: 3rem; opacity: 0.2; }
.empty-title { font-size: 0.95rem; font-weight: 600; color: #a0a0a8; }

.link-btn {
  background: none; border: none;
  color: #00ff88; font-size: 0.85rem;
  cursor: pointer; font-family: inherit;
  text-decoration: underline; text-underline-offset: 3px;
}
.link-btn:hover { opacity: 0.7; }

.loading-row {
  text-align: center; padding: 24px;
  color: #9090a8; font-size: 0.78rem;
  animation: blink 1.2s ease-in-out infinite;
}
@keyframes blink { 0%,100% { opacity:1; } 50% { opacity:0.3; } }
</style>