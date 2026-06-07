<script setup>
defineProps({
  isActive: {
    type: Boolean,
    default: false,
  },
})
</script>

<template>
  <div class="waveform-divider" :class="{ active: isActive }">
    <div class="bar b1" />
    <div class="bar b2" />
    <div class="bar b3" />
    <div class="bar b4" />
    <div class="bar b5" />
  </div>
</template>

<style scoped>
.waveform-divider {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  height: 32px;
  background: linear-gradient(90deg, #1a1a2e 0%, #16213e 50%, #1a0533 100%);
  padding: 0 16px;
  flex-shrink: 0;
}

.bar {
  width: 3px;
  border-radius: 2px;
  background-color: #7B2FBE;
  height: 6px;
  transition: height 0.2s ease;
}

/* Static state: bars at resting height */
.waveform-divider:not(.active) .bar {
  height: 6px;
  opacity: 0.5;
}

/* Active animations — each bar uses a different timing */
.waveform-divider.active .b1 {
  animation: wave 0.6s ease-in-out infinite alternate;
}
.waveform-divider.active .b2 {
  animation: wave 0.8s ease-in-out 0.1s infinite alternate;
}
.waveform-divider.active .b3 {
  animation: wave 0.5s ease-in-out 0.25s infinite alternate;
}
.waveform-divider.active .b4 {
  animation: wave 0.9s ease-in-out 0.05s infinite alternate;
}
.waveform-divider.active .b5 {
  animation: wave 0.7s ease-in-out 0.15s infinite alternate;
}

@keyframes wave {
  0%   { height: 4px;  opacity: 0.6; }
  25%  { height: 14px; opacity: 1; }
  50%  { height: 8px;  opacity: 0.8; }
  75%  { height: 20px; opacity: 1; }
  100% { height: 6px;  opacity: 0.7; }
}
</style>
