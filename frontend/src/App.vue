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
          
          <!-- プロファイル選択 -->
          <ProfileSelector 
            :profiles="profiles"
            :selected-profile="selectedProfile"
            @select-profile="selectProfile"
          />
          
          <!-- エラー・ローディング表示 -->
          <LoadingErrorCard 
            :error="error"
            :loading="loading"
            @retry="fetchData"
          />

          <!-- 次の列車情報 -->
          <div v-if="!error && !loading && nextTrainData && selectedProfile" class="train-info">
            
            <!-- 駅名ヘッダー -->
            <StationHeader 
              :station-name="nextTrainData.departure_station || nextTrainData.station_name || '駅'"
            />
            
            <!-- メイン情報表示 -->
            <div class="main-info-display card .mb-sm-2">
              <!-- 左側：現在時刻で間に合う列車情報 -->
              <CurrentTrainInfo 
                :departure-time="nextTrainData.train?.departure_time"
                :arrival-time="nextTrainData.arrival_time"
                :waiting-time="nextTrainData.time_until_departure"
              />
              
              <!-- 右側：次の列車詳細 -->
              <NextTrainInfo 
                :train="nextTrainData.train"
              />
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
import ProfileSelector from './components/ProfileSelector.vue'
import StationHeader from './components/StationHeader.vue'
import CurrentTrainInfo from './components/CurrentTrainInfo.vue'
import NextTrainInfo from './components/NextTrainInfo.vue'
import LoadingErrorCard from './components/LoadingErrorCard.vue'

// プロファイル関連の型定義
interface Profile {
  name: string
  departure: string
  destinations: Array<{ station: string }>
}

// リアクティブデータ
const currentTime = ref('')
const nextTrainData = ref<NextTrainResponse | null>(null)
const loading = ref(true)
const error = ref('')
const selectedProfile = ref('')
const profiles = ref<Profile[]>([])

// タイマーID
let timeUpdateInterval: any = null
let dataUpdateInterval: any = null

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
 * プロファイル一覧を取得
 */
const fetchProfiles = async () => {
  try {
    const data = await apiService.getProfiles()
    profiles.value = data.profiles
    
    // 最初のプロファイルを自動選択
    if (data.profiles.length > 0) {
      selectedProfile.value = data.profiles[0].name
    }
  } catch (err) {
    console.error('プロファイル取得エラー:', err)
    error.value = 'プロファイルの取得に失敗しました'
  }
}

/**
 * 次の列車情報を取得
 */
const fetchNextTrain = async () => {
  if (!selectedProfile.value) return
  
  try {
    loading.value = true
    error.value = ''
    
    const data = await apiService.getNextTrainByProfile(selectedProfile.value)
    
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
 * データを取得（プロファイル + 次の列車）
 */
const fetchData = async () => {
  await fetchProfiles()
  await fetchNextTrain()
}

/**
 * プロファイルを選択
 */
const selectProfile = (profileName: string) => {
  selectedProfile.value = profileName
  fetchNextTrain()
}

/**
 * コンポーネントマウント時の処理
 */
onMounted(() => {
  // 初期データ取得
  fetchData()
  
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

/* メイン情報表示 */
.main-info-display {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  padding: 2rem;
  background: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.3);
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
  
  .main-info-display {
    grid-template-columns: 1fr;
    gap: 1.5rem;
    padding: 1.5rem;
  }
}
</style>
