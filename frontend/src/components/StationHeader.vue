<template>
  <div class="station-header card .mb-sm-2">
    <div class="station-name">
      🚉 {{ stationName }}
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  stationName: string
}

defineProps<Props>()
</script>

<style scoped>
.station-header {
  text-align: center;
  padding: 0.5rem;
  background: rgba(238, 190, 200, 0.856);
  border-left: 4px solid rgba(245, 53, 159, 0.616);
}

.station-name {
  font-size: 2rem;
  font-weight: 800;
  color: #333;
  margin: 0;
}

@media (max-width: 768px) {
  .station-name {
    font-size: 1.2rem;
  }
}
</style>
