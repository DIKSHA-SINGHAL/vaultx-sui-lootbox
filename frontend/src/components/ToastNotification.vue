<!--
  ToastNotification.vue
  ─────────────────────────────────────────────────────────────
  A brief notification banner that appears at the bottom of the
  screen and auto-dismisses after 3 seconds (managed by useToast).

  The `v-if="toast"` in the parent controls whether this renders.
  When toast becomes null, Vue removes this component from the DOM.
-->
<template>
  <div :class="['toast', toast.type]">
    {{ toast.message }}
  </div>
</template>

<script>
export default {
  name: 'ToastNotification',

  props: {
    toast: {
      type:     Object,   // { message: string, type: 'success'|'error' }
      required: true,
    },
  },
}
</script>

<style scoped>
.toast {
  position: fixed;
  bottom: 80px;            /* sit above the FAB button */
  left: 50%;
  transform: translateX(-50%);
  padding: 10px 20px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 500;
  z-index: 999;
  animation: fadeUp 0.2s ease forwards;
  white-space: nowrap;
}

.toast.success {
  background: rgba(57, 255, 110, 0.1);
  border: 1px solid rgba(57, 255, 110, 0.3);
  color: var(--green);
}

.toast.error {
  background: rgba(239, 68, 68, 0.1);
  border: 1px solid rgba(239, 68, 68, 0.3);
  color: #f87171;
}

@keyframes fadeUp {
  from { opacity: 0; transform: translateX(-50%) translateY(8px); }
  to   { opacity: 1; transform: translateX(-50%) translateY(0); }
}
</style>