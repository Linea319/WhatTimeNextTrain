/**
 * Vue アプリケーションエントリーポイント
 * 
 * アプリケーションの初期化と設定を行います
 */

import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

const app = createApp(App)

app.mount('#app')
