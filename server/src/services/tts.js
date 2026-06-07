/**
 * TTS 服务 — 阿里云百炼 CosyVoice 实时流式语音合成
 *
 * 用法：
 *   const tts = new TtsService(apiKey, { onAudio, onDone });
 *   await tts.connect();
 *   await tts.startTask();
 *   tts.sendText('你好');     // 可多次调用，流式送入
 *   await tts.finishTask();
 *   tts.close();
 */

import { DashscopeWsClient } from '../utils/dashscopeWsClient.js';

const VOICES = {
  zh: 'longanyang',   // cosyvoice-v3-flash 中文男声，支持中英
  en: 'longanhuan',   // cosyvoice-v3-flash 中文女声，支持中英
};

const MODELS = {
  cosyvoiceV2:    'cosyvoice-v2',
  cosyvoiceFlash: 'cosyvoice-v3-flash',
};

const FLUSH_SIZE_BYTES = 40 * 1024;  // 40KB
const FLUSH_INTERVAL_MS = 100;

export class TtsService extends DashscopeWsClient {
  #onAudio;
  #onDone;
  #voice;
  #model;
  #audioChunks = [];
  #audioBufferedBytes = 0;
  #flushTimer = null;

  /**
   * @param {string} apiKey
   * @param {{
   *   onAudio?: (buffer: Buffer) => void,
   *   onDone?: () => void,
   *   voice?: string,
   *   model?: string,
   * }} opts
   */
  constructor(apiKey, { onAudio, onDone, voice = VOICES.zh, model = MODELS.cosyvoiceFlash } = {}) {
    super(apiKey, 'TTS');
    this.#onAudio = onAudio ?? (() => {});
    this.#onDone  = onDone  ?? (() => {});
    this.#voice = voice;
    this.#model = model;
  }

  buildRunTaskPayload() {
    return {
      payload: {
        task_group: 'audio',
        task: 'tts',
        function: 'SpeechSynthesizer',
        model: this.#model,
        parameters: {
          voice: this.#voice,
          format: 'mp3',
          sample_rate: 22050,
          volume: 50,
          rate: 1.0,
          pitch: 1.0,
        },
        input: {},
      },
    };
  }

  onBinary(buffer) {
    this.#audioChunks.push(buffer);
    this.#audioBufferedBytes += buffer.length;

    if (this.#audioBufferedBytes >= FLUSH_SIZE_BYTES) {
      this.#flushAudio();
      return;
    }

    if (!this.#flushTimer) {
      this.#flushTimer = setTimeout(() => this.#flushAudio(), FLUSH_INTERVAL_MS);
    }
  }

  #flushAudio() {
    if (this.#flushTimer) {
      clearTimeout(this.#flushTimer);
      this.#flushTimer = null;
    }
    if (this.#audioChunks.length === 0) return;
    const merged = Buffer.concat(this.#audioChunks);
    this.#audioChunks = [];
    this.#audioBufferedBytes = 0;
    this.#onAudio(merged);
  }

  onMessage(event, data) {
    if (event === 'task-finished') {
      this.#flushAudio();
      this.#onDone();
    }
  }

  // 流式送入文字片段（可以是词、短句）
  sendText(text) {
    this.sendContinue({
      payload: { input: { text } },
    });
  }

  // 覆盖基类 finishTask，等待完成前确保缓冲已 flush
  async finishTask() {
    await super.finishTask();
    this.#flushAudio();
  }
}

export { VOICES as TTS_VOICES, MODELS as TTS_MODELS };
