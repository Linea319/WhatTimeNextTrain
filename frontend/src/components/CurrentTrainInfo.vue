<template>
  <div class="current-train-section">
    <h3 class="section-title">🏠 自宅から</h3>
    <div class="time-info-item">
      <div class="time-label">次の列車発車時刻</div>
      <div class="time-value primary">{{ departureTime || '--:--' }}</div>
    </div>
    <div class="time-info-item">
      <div class="time-label">目標到着時刻</div>
      <div class="time-value">{{ arrivalTime }}</div>
    </div>
    <div class="time-info-item">
      <div class="time-label">自宅出発まで</div>
      <div class="time-value">
        <span v-if="waitingTime > 0">
          {{ waitingTime }}分
        </span>
        <span v-else class="warning">出発済み</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  departureTime?: string
  arrivalTime: string
  waitingTime: number
}

defineProps<Props>()
</script>

<style scoped>
.current-train-section {
  padding: 1rem;
  background: rgba(103, 126, 234, 0.1);
  border-radius: 8px;
  border-left: 4px solid #677EEA;
}

.section-title {
  font-size: 1.1rem;
  font-weight: 800;
  margin-bottom: 1rem;
  color: #333;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.time-info-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  padding: 0.75rem;
  background: rgba(103, 126, 234, 0.05);
  border-radius: 6px;
  border-left: 3px solid rgba(103, 126, 234, 0.3);
  margin-bottom: 1rem;
}

.time-label {
  font-size: 0.9rem;
  color: #666;
  margin-bottom: 0.25rem;
}

.time-value {
  font-size: 1.4rem;
  font-weight: 700;
  color: #333;
  font-family: 'Courier New', monospace;
}

.time-value.primary {
  color: #677EEA;
  font-weight: 900;
}

.time-value .warning {
  color: #e74c3c;
  font-size: 1rem;
}

@media (max-width: 768px) {
  .section-title {
    font-size: 0.8rem;
  }

  .time-info-item {
    gap : 0.1rem;
    padding: 0.25rem;
    margin-bottom: 0.25rem;
  }

  .time-value {
    font-size: 0.6rem;
  }
  
  .time-label{
    font-size: 0.6rem;
  }
}
</style>
