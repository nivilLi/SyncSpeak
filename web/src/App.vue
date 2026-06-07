<script setup>
import { ref, computed } from 'vue'
import { NConfigProvider, NLayout, NSelect, NRadioGroup, NRadioButton, darkTheme } from 'naive-ui'
import SubtitlePanel from './components/SubtitlePanel.vue'
import WaveformDivider from './components/WaveformDivider.vue'
import ControlBar from './components/ControlBar.vue'
import { useWebSocket } from './composables/useWebSocket.js'
import { useAudioCapture } from './composables/useAudioCapture.js'
import { useAudioPlayer } from './composables/useAudioPlayer.js'

// ── Session state ──────────────────────────────────────────────────────────
const { state: sessionState, errorMsg, connect, disconnect, sendBinary } = useWebSocket()
const { startCapture, stopCapture } = useAudioCapture()
const { enqueueAudio, stopPlayback } = useAudioPlayer()

// ── Language / mode selection ──────────────────────────────────────────────
const srcLang = ref('auto')
const tgtLang = ref('en')
const outputMode = ref('subtitle') // 'subtitle' | 'tts'

const srcLangOptions = [
  { label: '自动检测', value: 'auto' },
  { label: '中文', value: 'zh' },
  { label: 'English', value: 'en' },
]
const tgtLangOptions = [
  { label: '中文', value: 'zh' },
  { label: 'English', value: 'en' },
]

// ── Subtitle state ─────────────────────────────────────────────────────────
const transcriptHistory = ref([])
const currentTranscript = ref('')
const translationHistory = ref([])
const currentTranslation = ref('')

function handleTranscript({ text, isFinal }) {
  if (isFinal) {
    if (text.trim()) transcriptHistory.value.push(text)
    currentTranscript.value = ''

    // Seal current translation when source sentence ends
    if (currentTranslation.value.trim()) {
      translationHistory.value.push(currentTranslation.value)
      currentTranslation.value = ''
    }
  } else {
    currentTranscript.value = text
  }
}

function handleTranslation({ chunk }) {
  currentTranslation.value += chunk
}

function handleAudio(arrayBuffer) {
  if (outputMode.value === 'tts') {
    enqueueAudio(arrayBuffer)
  }
}

// ── Controls ───────────────────────────────────────────────────────────────
async function handleStart() {
  // Reset subtitles
  transcriptHistory.value = []
  currentTranscript.value = ''
  translationHistory.value = []
  currentTranslation.value = ''

  connect(srcLang.value, tgtLang.value, {
    onTranscript: handleTranscript,
    onTranslation: handleTranslation,
    onAudio: handleAudio,
  })

  // Wait for 'started' before mic — the WS state will flip to 'started'
  // We start capture optimistically; the server will ignore audio before 'started'
  try {
    await startCapture((chunk) => sendBinary(chunk))
  } catch (err) {
    console.error('Microphone access denied:', err)
    disconnect()
  }
}

function handleStop() {
  stopCapture()
  stopPlayback()
  disconnect()
}

const isActive = computed(() => sessionState.value === 'started')

// Displayed lang pair label for the toolbar
const langPairLabel = computed(() => {
  const src = srcLang.value === 'auto' ? '自动' : srcLang.value === 'zh' ? '中' : 'EN'
  const tgt = tgtLang.value === 'zh' ? '中' : 'EN'
  return `${src} → ${tgt}`
})
</script>

<template>
  <NConfigProvider :theme="darkTheme">
    <div class="app-shell">
      <!-- Top toolbar -->
      <div class="toolbar">
        <span class="brand">SyncSpeak</span>
        <div class="toolbar-controls">
          <div class="lang-selects">
            <NSelect
              v-model:value="srcLang"
              :options="srcLangOptions"
              size="small"
              style="width: 110px"
              :disabled="isActive"
            />
            <span class="arrow">→</span>
            <NSelect
              v-model:value="tgtLang"
              :options="tgtLangOptions"
              size="small"
              style="width: 90px"
              :disabled="isActive"
            />
          </div>
          <NRadioGroup v-model:value="outputMode" size="small">
            <NRadioButton value="subtitle">字幕</NRadioButton>
            <NRadioButton value="tts">TTS</NRadioButton>
          </NRadioGroup>
        </div>
      </div>

      <!-- Transcript panel (source) -->
      <SubtitlePanel
        :history="transcriptHistory"
        :current-text="currentTranscript"
        text-color="#e0e0ff"
        background-color="#1a1a2e"
        empty-hint="原文字幕将显示在这里..."
      />

      <!-- Waveform divider -->
      <WaveformDivider :is-active="isActive" />

      <!-- Translation panel -->
      <SubtitlePanel
        :history="translationHistory"
        :current-text="currentTranslation"
        text-color="#CE93D8"
        background-color=""
        empty-hint="译文字幕将显示在这里..."
        class="translation-panel"
      />

      <!-- Error banner -->
      <div v-if="sessionState === 'error'" class="error-banner">
        {{ errorMsg || '连接出错，请重试' }}
      </div>

      <!-- Control bar -->
      <ControlBar
        :session-state="sessionState"
        :on-start="handleStart"
        :on-stop="handleStop"
      />
    </div>
  </NConfigProvider>
</template>

<style>
/* Global reset already in index.html; add font here */
body {
  font-family: 'Inter', 'PingFang SC', 'Helvetica Neue', sans-serif;
  -webkit-font-smoothing: antialiased;
}
</style>

<style scoped>
.app-shell {
  display: flex;
  flex-direction: column;
  height: 100vh;
  width: 100vw;
  overflow: hidden;
  background-color: #1a1a2e;
  color: #e0e0ff;
}

/* Toolbar */
.toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  height: 56px;
  background-color: #12122a;
  border-bottom: 1px solid #2a2a4a;
  flex-shrink: 0;
}

.brand {
  font-size: 18px;
  font-weight: 700;
  color: #CE93D8;
  letter-spacing: 0.5px;
}

.toolbar-controls {
  display: flex;
  align-items: center;
  gap: 16px;
}

.lang-selects {
  display: flex;
  align-items: center;
  gap: 8px;
}

.arrow {
  color: #7B2FBE;
  font-size: 16px;
}

/* Translation panel override background */
.translation-panel {
  background: linear-gradient(180deg, #16213e 0%, #1a0533 100%) !important;
}

/* Error banner */
.error-banner {
  background-color: #3a1f00;
  color: #f0a020;
  text-align: center;
  padding: 8px 16px;
  font-size: 13px;
  flex-shrink: 0;
}
</style>
