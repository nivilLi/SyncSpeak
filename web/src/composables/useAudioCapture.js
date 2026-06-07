export function useAudioCapture() {
  let audioCtx = null
  let mediaStream = null
  let sourceNode = null
  let processorNode = null

  // Samples accumulated between flushes
  let sampleBuffer = []
  const SAMPLES_PER_FRAME = 1600 // 100ms @ 16kHz

  function float32ToInt16(samples) {
    const buf = new ArrayBuffer(samples.length * 2)
    const view = new DataView(buf)
    for (let i = 0; i < samples.length; i++) {
      const s = Math.max(-32768, Math.min(32767, samples[i] * 32768))
      view.setInt16(i * 2, s, true) // little-endian
    }
    return buf
  }

  async function startCapture(onChunk) {
    if (audioCtx) return

    mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true })

    // ScriptProcessorNode requires a context whose sample rate matches our target.
    // Using sampleRate: 16000 avoids a resample step.
    audioCtx = new AudioContext({ sampleRate: 16000 })

    sourceNode = audioCtx.createMediaStreamSource(mediaStream)

    // bufferSize=4096 keeps latency low while still being power-of-two
    processorNode = audioCtx.createScriptProcessor(4096, 1, 1)

    processorNode.onaudioprocess = (e) => {
      const input = e.inputBuffer.getChannelData(0)
      sampleBuffer.push(...input)

      while (sampleBuffer.length >= SAMPLES_PER_FRAME) {
        const frame = sampleBuffer.splice(0, SAMPLES_PER_FRAME)
        onChunk(float32ToInt16(frame))
      }
    }

    sourceNode.connect(processorNode)
    // Must connect to destination or Chrome won't fire onaudioprocess
    processorNode.connect(audioCtx.destination)
  }

  function stopCapture() {
    processorNode?.disconnect()
    sourceNode?.disconnect()
    processorNode = null
    sourceNode = null

    mediaStream?.getTracks().forEach((t) => t.stop())
    mediaStream = null

    audioCtx?.close()
    audioCtx = null

    sampleBuffer = []
  }

  return { startCapture, stopCapture }
}
