/**
 * main.js
 * ─────────────────────────────────────────────────────────────
 * The JavaScript entry point for the Vue application.
 *
 * HOW VUE BOOTS UP:
 * 1. createApp(App) creates a Vue application instance from our
 *    root component (App.vue).
 * 2. .mount('#app') tells Vue to take over the <div id="app">
 *    in index.html and replace it with the rendered app.
 *
 * Everything else (state, components, routing) flows from App.vue.
 * This file intentionally stays tiny.
 */

import { createApp } from 'vue'
import App           from './App.vue'

// Import global CSS before mounting so it's available immediately
import './assets/main.css'

// Mount the app on the #app element in index.html
createApp(App).mount('#app')