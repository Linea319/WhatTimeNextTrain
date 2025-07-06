<template>
  <div class="profile-selector card mb-6">
    <h2>📍 出発駅を選択</h2>
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
</template>

<script setup lang="ts">
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

defineProps<Props>()
const emit = defineEmits<Emits>()

const selectProfile = (profileName: string) => {
  emit('select-profile', profileName)
}
</script>

<style scoped>
.profile-selector {
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.profile-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  justify-content: center;
}

.profile-button {
  flex: 1 1 150px;
  padding: 1rem;
  background: rgba(103, 126, 234, 0.2);
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.3s;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.profile-button.active {
  background: rgba(103, 126, 234, 0.4);
}

.profile-name {
  font-size: 1.1rem;
  font-weight: 500;
  color: #333;
  margin-bottom: 0.5rem;
}

.profile-destinations {
  font-size: 0.9rem;
  color: #666;
}
</style>
