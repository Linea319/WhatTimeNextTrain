<template>
  <div class="app">
    <!-- ヘッダー -->
    <header class="header">
      <div class="container">
        <div class="header-content">
          <h1 class="app-title">WhatTimeNextTrain</h1>
          
          <!-- ヘッダー内プロファイル選択 -->
          <div class="header-profile-section">
            <div class="current-profile-display">
              <span class="profile-icon">📍</span>
              <span class="profile-text">
                {{ currentProfileName || '出発駅を選択' }}
              </span>
            </div>
            <button 
              @click="toggleProfileSelector"
              :class="['profile-settings-btn', { active: showProfileSelector }]"
              :aria-label="showProfileSelector ? '設定を閉じる' : '設定を開く'"
            >
              <span class="settings-icon">⚙️</span>
              <span class="expand-icon" :class="{ rotated: showProfileSelector }">▼</span>
            </button>
          </div>
          
          <div class="current-time">{{ currentTime }}</div>
        </div>
        
        <!-- スライド式プロファイル選択（ヘッダー下） -->
        <div class="header-profile-selection" :class="{ expanded: showProfileSelector }">
          <div class="profile-selection-content">
            <h3 class="selection-title">📍 出発駅を選択</h3>
            <div class="profile-buttons">
              <button 
                v-for="profile in profiles" 
                :key="profile.name"
                @click="selectProfile(profile.name)"
                :class="['profile-button', { active: selectedProfile === profile.name }]"
              >
                <div class="profile-name">{{ profile.departure }}</div>
                <div class="profile-destinations">
                  {{ profile.destinations.map(d => d.station).join(', ') }}
                </div>
              </button>
            </div>
          </div>
        </div>
      </div>
    </header>

    <!-- メインコンテンツ -->
    <main class="main">
      <div class="container">
        <div class="content-wrapper">
          
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
              <div class="main-info-card">
                <CurrentTrainInfo 
                  :departure-time="nextTrainData.departure_time"
                  :waiting-time="nextTrainData.time_until_departure"
                />
              </div>
              
              <!-- 右側：次の列車詳細 -->
              <div class="main-info-card">
                <NextTrainInfo 
                  :train="nextTrainData.train"
                />
              </div>
            </div>

          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import type { NextTrainResponse } from './types/api'
import { apiService } from './services/api'
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
const showProfileSelector = ref(false)

// タイマーID
let timeUpdateInterval: any = null
let dataUpdateInterval: any = null

// 現在選択されているプロファイル名を取得
const currentProfileName = computed(() => {
  const currentProfile = profiles.value.find(p => p.name === selectedProfile.value)
  return currentProfile ? currentProfile.departure : null
})

// プロファイル選択UIの開閉
const toggleProfileSelector = () => {
  showProfileSelector.value = !showProfileSelector.value
}

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
  // 選択後は自動的に閉じる
  showProfileSelector.value = false
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

/* ヘッダー内プロファイル選択 */
.header-profile-section {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.current-profile-display {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  color: white;
}

.profile-icon {
  font-size: 1rem;
}

.profile-text {
  font-size: 0.9rem;
  font-weight: 500;
  white-space: nowrap;
}

.profile-settings-btn {
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.5rem 0.75rem;
  background: rgba(255, 255, 255, 0.2);
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  color: white;
  font-size: 0.85rem;
}

.profile-settings-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.profile-settings-btn.active {
  background: rgba(255, 255, 255, 0.4);
}

.settings-icon {
  font-size: 0.9rem;
}

.expand-icon {
  font-size: 0.7rem;
  transition: transform 0.3s ease;
}

.expand-icon.rotated {
  transform: rotate(180deg);
}

/* ヘッダー下スライド式選択UI */
.header-profile-selection {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.3s ease-out;
  background: rgba(255, 255, 255, 0.95);
  border-top: 1px solid rgba(255, 255, 255, 0.3);
}

.header-profile-selection.expanded {
  max-height: 300px;
}

.profile-selection-content {
  padding: 1.5rem;
}

.selection-title {
  font-size: 1rem;
  font-weight: 600;
  color: #333;
  margin-bottom: 1rem;
  text-align: center;
}

.profile-buttons {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 0.75rem;
}

.profile-button {
  padding: 0.75rem;
  background: rgba(103, 126, 234, 0.2);
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  min-height: 3.5rem;
}

.profile-button:hover {
  background: rgba(103, 126, 234, 0.3);
  transform: translateY(-1px);
}

.profile-button.active {
  background: rgba(103, 126, 234, 0.5);
  box-shadow: 0 2px 8px rgba(103, 126, 234, 0.3);
}

.profile-name {
  font-size: 0.9rem;
  font-weight: 600;
  color: #333;
  margin-bottom: 0.25rem;
}

.profile-destinations {
  font-size: 0.75rem;
  color: #666;
  line-height: 1.2;
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
  display: flex;
  flex-direction: row;
  gap: 2rem;
  padding: 2rem;
  background: rgba(255, 255, 255, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.3);
}
.main-info-card {
  flex-grow: 1;
}

/* レスポンシブデザイン */
@media (max-width: 768px) {
  
  .app-title {
    font-size: 1.3rem;
  }
  
  .header-profile-section {
    order: 1;
  }
  
  .current-time {
    font-size: 1rem;
    order: 2;
  }
  
  .current-profile-display {
    padding: 0.4rem 0.6rem;
  }
  
  .profile-text {
    font-size: 0.8rem;
  }
  
  .profile-settings-btn {
    padding: 0.4rem 0.6rem;
    font-size: 0.8rem;
  }
  
  .profile-buttons {
    grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
    gap: 0.5rem;
  }
  
  .profile-button {
    padding: 0.5rem;
    min-height: 3rem;
  }
  
  .profile-name {
    font-size: 0.8rem;
  }
  
  .profile-destinations {
    font-size: 0.7rem;
  }

  .main{
    padding: 0;
  }
  
  .main-info-display {
    gap: 1.0rem;
    padding: 1.0rem;
  }
}
</style>
