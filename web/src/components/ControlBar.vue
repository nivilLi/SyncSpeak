<script setup>
import { NButton } from 'naive-ui'
import { computed } from 'vue'

const props = defineProps({
  sessionState: {
    type: String,
    default: 'idle',
  },
  onStart: {
    type: Function,
    default: () => {},
  },
  onStop: {
    type: Function,
    default: () => {},
  },
})

const buttonConfig = computed(() => {
  switch (props.sessionState) {
    case 'idle':
      return { label: '● 开始传译', type: 'primary', disabled: false, action: 'start' }
    case 'connecting':
      return { label: '连接中...', type: 'default', disabled: true, action: null }
    case 'started':
      return { label: '■ 停止传译', type: 'error', disabled: false, action: 'stop' }
    case 'stopping':
      return { label: '正在停止...', type: 'default', disabled: true, action: null }
    case 'error':
      return { label: '重试', type: 'warning', disabled: false, action: 'start' }
    default:
      return { label: '开始传译', type: 'primary', disabled: false, action: 'start' }
  }
})

const statusText = computed(() => {
  switch (props.sessionState) {
    case 'idle':      return '就绪'
    case 'connecting': return '正在连接服务器...'
    case 'started':   return '翻译进行中'
    case 'stopping':  return '正在停止...'
    case 'error':     return '连接出错'
    default:          return ''
  }
})

function handleClick() {
  const { action } = buttonConfig.value
  if (action === 'start') props.onStart()
  else if (action === 'stop') props.onStop()
}
</script>

<template>
  <div class="control-bar">
    <NButton
      :type="buttonConfig.type"
      :disabled="buttonConfig.disabled"
      size="large"
      round
      @click="handleClick"
    >
      {{ buttonConfig.label }}
    </NButton>
    <span class="status-text" :class="`status-${sessionState}`">
      {{ statusText }}
    </span>
  </div>
</template>

<style scoped>
.control-bar {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
  height: 72px;
  background-color: #12122a;
  border-top: 1px solid #2a2a4a;
  flex-shrink: 0;
  padding: 0 24px;
}

.status-text {
  font-size: 13px;
  min-width: 120px;
}

.status-idle       { color: #6a6a9a; }
.status-connecting { color: #aaa; }
.status-started    { color: #CE93D8; }
.status-stopping   { color: #aaa; }
.status-error      { color: #f0a020; }
</style>
