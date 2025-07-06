<template>
  <div class="next-train-section">
    <h3 class="section-title">🚊 次の列車</h3>
    <div v-if="train" class="train-details-compact">
      <div class="train-info-item">
        <div class="train-label">路線名</div>
        <div class="train-value">{{ train.line }}</div>
      </div>
      <div class="train-info-item">
        <div class="train-label">行先</div>
        <div class="train-value">{{ train.destination }}</div>
      </div>
      <div class="train-info-item">
        <div class="train-label">到着予想時刻</div>
        <div class="train-value primary">{{ train.arrival_time }}</div>
      </div>
    </div>
    <div v-else class="no-train-info">
      <p>📅 本日の運行終了</p>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Train {
  line: string
  destination: string
  departure_time: string
  arrival_time: string
}

interface Props {
  train?: Train | null
}

defineProps<Props>()
</script>

<style scoped>
.next-train-section {
  padding: 1rem;
  background: rgba(75, 193, 164, 0.1);
  border-radius: 8px;
  border-left: 4px solid #4BC1A4;
}

.section-title {
  font-size: 1.1rem;
  font-weight: 600;
  margin-bottom: 1rem;
  color: #333;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.train-details-compact {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.train-info-item {
  margin-bottom: 1rem;
}

.train-label {
  font-size: 0.9rem;
  color: #666;
  margin-bottom: 0.25rem;
}

.train-value {
  font-size: 1.2rem;
  font-weight: 600;
  color: #333;
}

.train-value.primary {
  font-size: 1.4rem;
  color: #4BC1A4;
  font-family: 'Courier New', monospace;
}

.no-train-info {
  text-align: center;
  color: #666;
  font-style: italic;
  padding: 2rem 0;
}

@media (max-width: 768px) {
  .train-value.primary {
    font-size: 1.2rem;
  }
}
</style>
