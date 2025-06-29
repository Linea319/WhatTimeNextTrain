import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    port: 3000,
    host: '0.0.0.0' // Raspberry Pi上でLAN内からアクセス可能にする
  },
  build: {
    outDir: 'dist'
  }
})
