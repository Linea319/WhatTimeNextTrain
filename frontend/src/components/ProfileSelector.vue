<template>
  <div class="profile-selector card mb-6">
    <!-- 設定ボタン -->
    <div class="profile-header">
      <div class="current-profile-info">
        <span class="current-profile-icon">📍</span>
        <span class="current-profile-text">
          {{ currentProfileName || '出発駅を選択' }}
        </span>
      </div>
      <button 
        @click="toggleSelector"
        :class="['settings-button', { active: isExpanded }]"
        :aria-label="isExpanded ? '設定を閉じる' : '設定を開く'"
      >
        <span class="settings-icon">⚙️</span>
        <span class="expand-icon" :class="{ rotated: isExpanded }">▼</span>
      </button>
    </div>
    
    <!-- スライド式選択UI -->
    <div class="profile-selection" :class="{ expanded: isExpanded }">
      <h3 class="selection-title">出発駅を選択</h3>
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
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

interface Profile {
  name: string
  departure: string
  destinations: Array<{ station: string }>
}

interface Props {
  profiles: Profile[]
  selectedProfile: string
}

interface Emits {
  (e: 'select-profile', profileName: string): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// リアクティブデータ
const isExpanded = ref(false)

// 現在選択されているプロファイル名を取得
const currentProfileName = computed(() => {
  const currentProfile = props.profiles.find(p => p.name === props.selectedProfile)
  return currentProfile ? currentProfile.departure : null
})

// 選択UIの開閉
const toggleSelector = () => {
  isExpanded.value = !isExpanded.value
}

// プロファイル選択
const selectProfile = (profileName: string) => {
  emit('select-profile', profileName)
  // 選択後は自動的に閉じる
  isExpanded.value = false
}
</script>

<style scoped>
.profile-selector {
  margin-bottom: 2rem;
  padding: 1rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

/* ヘッダー部分（常に表示） */
.profile-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  min-height: 2.5rem;
}

.current-profile-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex: 1;
}

.current-profile-icon {
  font-size: 1.1rem;
}

.current-profile-text {
  font-size: 1rem;
  font-weight: 500;
  color: #333;
}

/* 設定ボタン */
.settings-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: rgba(103, 126, 234, 0.2);
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  color: #333;
  font-size: 0.9rem;
}

.settings-button:hover {
  background: rgba(103, 126, 234, 0.3);
}

.settings-button.active {
  background: rgba(103, 126, 234, 0.4);
}

.settings-icon {
  font-size: 1rem;
}

.expand-icon {
  font-size: 0.8rem;
  transition: transform 0.3s ease;
}

.expand-icon.rotated {
  transform: rotate(180deg);
}

/* スライド式選択UI */
.profile-selection {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.3s ease-out, padding 0.3s ease-out;
  padding: 0 0;
}

.profile-selection.expanded {
  max-height: 500px;
  padding: 1rem 0 0 0;
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
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
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
  min-height: 4rem;
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
  font-size: 0.95rem;
  font-weight: 600;
  color: #333;
  margin-bottom: 0.25rem;
}

.profile-destinations {
  font-size: 0.8rem;
  color: #666;
  line-height: 1.2;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .profile-selector {
    padding: 0.75rem;
    margin-bottom: 1rem;
  }
  
  .profile-header {
    min-height: 2rem;
  }
  
  .current-profile-text {
    font-size: 0.9rem;
  }
  
  .settings-button {
    padding: 0.4rem 0.8rem;
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
    font-size: 0.85rem;
  }
  
  .profile-destinations {
    font-size: 0.75rem;
  }
}
</style>
