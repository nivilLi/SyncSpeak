export function useAudioPlayer() {
  let audioCtx = null
  const queue = [] // decoded AudioBuffers waiting to play
  let isPlaying = false

  function ensureContext() {
    if (!audioCtx || audioCtx.state === 'closed') {
      audioCtx = new AudioContext()
    }
    // Resume if suspended (browser autoplay policy)
    if (audioCtx.state === 'suspended') {
      audioCtx.resume()
    }
  }

  function playNext() {
    if (queue.length === 0) {
      isPlaying = false
      return
    }
    isPlaying = true
    const buffer = queue.shift()
    const source = audioCtx.createBufferSource()
    source.buffer = buffer
    source.connect(audioCtx.destination)
    source.onended = playNext
    source.start()
  }

  async function enqueueAudio(arrayBuffer) {
    ensureContext()

    let decoded
    try {
      // decodeAudioData consumes the buffer; copy to avoid detached-buffer issues
      decoded = await audioCtx.decodeAudioData(arrayBuffer.slice(0))
    } catch {
      // Corrupted or incomplete MP3 chunk — skip silently
      return
    }

    queue.push(decoded)
    if (!isPlaying) {
      playNext()
    }
  }

  function stopPlayback() {
    queue.length = 0
    isPlaying = false
    if (audioCtx && audioCtx.state !== 'closed') {
      audioCtx.close()
      audioCtx = null
    }
  }

  return { enqueueAudio, stopPlayback }
}
