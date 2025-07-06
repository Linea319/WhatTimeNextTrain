<template>
  <!-- エラー表示 -->
  <div v-if="error" class="error-card">
    <div class="card">
      <h2>⚠️ エラー</h2>
      <p>{{ error }}</p>
      <button @click="onRetry" class="retry-button">
        再試行
      </button>
    </div>
  </div>

  <!-- ローディング表示 -->
  <div v-else-if="loading" class="loading-card">
    <div class="card text-center">
      <div class="spinner"></div>
      <p>データを読み込み中...</p>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  error?: string
  loading?: boolean
}

interface Emits {
  (e: 'retry'): void
}

defineProps<Props>()
const emit = defineEmits<Emits>()

const onRetry = () => {
  emit('retry')
}
</script>

<style scoped>
.error-card, .loading-card {
  text-align: center;
}

.error-card h2 {
  color: #e74c3c;
  margin-bottom: 1rem;
}

.retry-button {
  background: #3498db;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1rem;
  margin-top: 1rem;
  transition: background 0.3s;
}

.retry-button:hover {
  background: #2980b9;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>
