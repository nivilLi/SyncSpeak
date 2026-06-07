<script setup>
import { computed } from 'vue'

const props = defineProps({
  history: {
    type: Array,
    default: () => [],
  },
  currentText: {
    type: String,
    default: '',
  },
  textColor: {
    type: String,
    default: '#ffffff',
  },
  backgroundColor: {
    type: String,
    default: '#1a1a2e',
  },
  emptyHint: {
    type: String,
    default: '等待语音输入...',
  },
})

// Show at most 5 history items; newest last
const visibleHistory = computed(() => {
  const items = props.history.slice(-5)
  // Each item gets a "recency" index: 0 = oldest visible, last = newest
  return items.map((text, idx) => {
    const fromEnd = items.length - 1 - idx // 0 = newest, 1 = second newest ...
    return { text, fromEnd }
  })
})

function historyStyle(fromEnd) {
  // fromEnd 0 → newest, 1 → second newest, ...
  const configs = [
    { fontSize: '18px', opacity: 0.85 },
    { fontSize: '16px', opacity: 0.65 },
    { fontSize: '14px', opacity: 0.45 },
    { fontSize: '13px', opacity: 0.25 },
    { fontSize: '13px', opacity: 0.25 },
  ]
  const cfg = configs[fromEnd] ?? { fontSize: '13px', opacity: 0.25 }
  return {
    fontSize: cfg.fontSize,
    opacity: cfg.opacity,
    lineHeight: '1.6',
    transition: 'opacity 0.3s, font-size 0.3s',
  }
}
</script>

<template>
  <div
    class="subtitle-panel"
    :style="{ backgroundColor }"
  >
    <div class="inner">
      <template v-if="visibleHistory.length === 0 && !currentText">
        <span class="empty-hint">{{ emptyHint }}</span>
      </template>
      <template v-else>
        <p
          v-for="(item, i) in visibleHistory"
          :key="i"
          class="history-line"
          :style="{ color: textColor, ...historyStyle(item.fromEnd) }"
        >
          {{ item.text }}
        </p>
        <p
          v-if="currentText"
          class="current-line"
          :style="{ color: textColor }"
        >
          {{ currentText }}
        </p>
      </template>
    </div>
  </div>
</template>

<style scoped>
.subtitle-panel {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 16px 24px;
}

.inner {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.empty-hint {
  font-size: 15px;
  opacity: 0.35;
  color: #aaa;
  text-align: center;
  align-self: center;
  margin-bottom: 8px;
}

.history-line {
  margin: 0;
  word-break: break-word;
}

.current-line {
  margin: 0;
  font-size: 22px;
  font-weight: bold;
  opacity: 1;
  line-height: 1.5;
  word-break: break-word;
}
</style>
