<template>
  <div class="app">
    <!-- ヘッダー -->
    <header class="header">
      <div class="container">
        <div class="header-content">
          <h1 class="app-title">🚃 WhatTimeNextTrain</h1>
          <div class="current-time">{{ currentTime }}</div>
        </div>
      </div>
    </header>

    <!-- メインコンテンツ -->
    <main class="main">
      <div class="container">
        <div class="content-wrapper">
          
          <!-- エラー表示 -->
          <div v-if="error" class="error-card">
            <div class="card">
              <h2>⚠️ エラー</h2>
              <p>{{ error }}</p>
              <button @click="fetchNextTrain" class="retry-button">
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

          <!-- 次の列車情報 -->
          <div v-else-if="nextTrainData" class="train-info">
            
            <!-- 出発・到着時刻表示 -->
            <div class="time-display card mb-6">
              <div class="time-section">
                <div class="time-item">
                  <div class="icon">🏠</div>
                  <div class="time-info">
                    <div class="label">自宅出発</div>
                    <div class="time">{{ nextTrainData.departure_time }}</div>
                  </div>
                </div>
                
                <div class="arrow">→</div>
                
                <div class="time-item">
                  <div class="icon">🚉</div>
                  <div class="time-info">
                    <div class="label">{{ nextTrainData.station_name || '駅' }}到着</div>
                    <div class="time">{{ nextTrainData.arrival_time }}</div>
                  </div>
                </div>
              </div>
              
              <!-- カウントダウン -->
              <div class="countdown">
                <div v-if="nextTrainData.time_until_departure > 0" class="countdown-text">
                  出発まで <strong>{{ nextTrainData.time_until_departure }}分</strong>
                </div>
                <div v-else class="countdown-text warning">
                  出発時刻を過ぎています
                </div>
              </div>
            </div>

            <!-- 列車情報 -->
            <div v-if="nextTrainData.train" class="train-details card">
              <h2 class="train-title">🚊 次の列車</h2>
              <div class="train-info-grid">
                <div class="train-detail">
                  <span class="label">路線</span>
                  <span class="value">{{ nextTrainData.train.line }}</span>
                </div>
                <div class="train-detail">
                  <span class="label">行き先</span>
                  <span class="value">{{ nextTrainData.train.destination }}</span>
                </div>
                <div class="train-detail">
                  <span class="label">出発時刻</span>
                  <span class="value">{{ nextTrainData.train.departure_time }}</span>
                </div>
                <div class="train-detail">
                  <span class="label">到着時刻</span>
                  <span class="value">{{ nextTrainData.train.arrival_time }}</span>
                </div>
              </div>
            </div>

            <!-- 列車がない場合 -->
            <div v-else class="no-train card">
              <h2>📅 本日の列車は終了しました</h2>
              <p>明日の時刻表をご確認ください</p>
            </div>

          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import type { NextTrainResponse } from './types/api'
import { apiService } from './services/api'

// リアクティブデータ
const currentTime = ref('')
const nextTrainData = ref<NextTrainResponse | null>(null)
const loading = ref(true)
const error = ref('')

// タイマーID
let timeUpdateInterval: number | null = null
let dataUpdateInterval: number | null = null

/**
 * 現在時刻を更新
 */
const updateCurrentTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('ja-JP', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

/**
 * 次の列車情報を取得
 */
const fetchNextTrain = async () => {
  try {
    loading.value = true
    error.value = ''
    
    const data = await apiService.getNextTrain()
    
    if (data.error) {
      error.value = data.error
    } else {
      nextTrainData.value = data
    }
  } catch (err) {
    console.error('API Error:', err)
    error.value = 'サーバーに接続できませんでした。バックエンドが起動していることを確認してください。'
  } finally {
    loading.value = false
  }
}

/**
 * コンポーネントマウント時の処理
 */
onMounted(() => {
  // 初期データ取得
  fetchNextTrain()
  
  // 現在時刻の更新を開始
  updateCurrentTime()
  timeUpdateInterval = setInterval(updateCurrentTime, 1000)
  
  // データの定期更新を開始（1分毎）
  dataUpdateInterval = setInterval(fetchNextTrain, 60000)
})

/**
 * コンポーネント削除時の処理
 */
onUnmounted(() => {
  if (timeUpdateInterval) {
    clearInterval(timeUpdateInterval)
  }
  if (dataUpdateInterval) {
    clearInterval(dataUpdateInterval)
  }
})
</script>

<style scoped>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.header {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  padding: 1rem 0;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.app-title {
  color: white;
  font-size: 1.5rem;
  font-weight: 600;
}

.current-time {
  color: white;
  font-size: 1.2rem;
  font-weight: 500;
  font-family: 'Courier New', monospace;
}

.main {
  flex: 1;
  padding: 2rem 0;
}

.time-display {
  margin-bottom: 2rem;
}

.time-section {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2rem;
  margin-bottom: 1.5rem;
}

.time-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.icon {
  font-size: 2rem;
}

.time-info {
  text-align: center;
}

.label {
  font-size: 0.9rem;
  color: #666;
  margin-bottom: 0.25rem;
}

.time {
  font-size: 1.8rem;
  font-weight: 700;
  color: #333;
  font-family: 'Courier New', monospace;
}

.arrow {
  font-size: 1.5rem;
  color: #666;
  font-weight: bold;
}

.countdown {
  text-align: center;
  padding-top: 1rem;
  border-top: 1px solid #eee;
}

.countdown-text {
  font-size: 1.1rem;
  color: #333;
}

.countdown-text.warning {
  color: #e74c3c;
  font-weight: 600;
}

.train-details {
  margin-bottom: 2rem;
}

.train-title {
  text-align: center;
  margin-bottom: 1.5rem;
  color: #333;
  font-size: 1.3rem;
}

.train-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.train-detail {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: rgba(103, 126, 234, 0.1);
  border-radius: 8px;
}

.train-detail .label {
  font-weight: 600;
  color: #666;
}

.train-detail .value {
  font-weight: 700;
  color: #333;
}

.error-card, .loading-card, .no-train {
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

.no-train {
  color: #666;
}

.no-train h2 {
  color: #f39c12;
  margin-bottom: 1rem;
}

/* レスポンシブデザイン */
@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    gap: 0.5rem;
    text-align: center;
  }
  
  .app-title {
    font-size: 1.3rem;
  }
  
  .current-time {
    font-size: 1rem;
  }
  
  .time-section {
    flex-direction: column;
    gap: 1rem;
  }
  
  .arrow {
    transform: rotate(90deg);
  }
  
  .time {
    font-size: 1.5rem;
  }
  
  .train-info-grid {
    grid-template-columns: 1fr;
  }
}
</style>
