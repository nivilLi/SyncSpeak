import { ref } from 'vue'

const WS_URL = 'ws://localhost:3000'

export function useWebSocket() {
  const state = ref('idle') // 'idle' | 'connecting' | 'started' | 'stopping' | 'error'
  const errorMsg = ref(null)

  let ws = null

  function connect(srcLang, tgtLang, { onTranscript, onTranslation, onAudio } = {}) {
    if (ws) {
      ws.close()
      ws = null
    }

    state.value = 'connecting'
    errorMsg.value = null

    ws = new WebSocket(WS_URL)
    ws.binaryType = 'arraybuffer'

    ws.addEventListener('open', () => {
      ws.send(JSON.stringify({ type: 'start', srcLang, tgtLang }))
    })

    ws.addEventListener('message', (event) => {
      if (event.data instanceof ArrayBuffer) {
        onAudio?.(event.data)
        return
      }

      let msg
      try {
        msg = JSON.parse(event.data)
      } catch {
        return
      }

      switch (msg.type) {
        case 'started':
          state.value = 'started'
          break
        case 'transcript':
          onTranscript?.({ text: msg.text, isFinal: msg.isFinal })
          break
        case 'translation':
          onTranslation?.({ chunk: msg.chunk })
          break
        case 'error':
          state.value = 'error'
          errorMsg.value = msg.message ?? '未知错误'
          break
      }
    })

    ws.addEventListener('close', () => {
      if (state.value !== 'error') {
        state.value = 'idle'
      }
      ws = null
    })

    ws.addEventListener('error', () => {
      state.value = 'error'
      errorMsg.value = '无法连接到服务器'
      ws = null
    })
  }

  function disconnect() {
    if (!ws) return
    state.value = 'stopping'
    ws.send(JSON.stringify({ type: 'stop' }))
    // Give server a moment to finish, then close
    setTimeout(() => {
      ws?.close()
      ws = null
      state.value = 'idle'
    }, 500)
  }

  function sendBinary(arrayBuffer) {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(arrayBuffer)
    }
  }

  return { state, errorMsg, connect, disconnect, sendBinary }
}
