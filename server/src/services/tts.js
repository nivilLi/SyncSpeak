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

export class TtsService extends DashscopeWsClient {
  #onAudio;
  #onDone;
  #voice;
  #model;

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

  // 接收二进制音频帧，直接转发给调用方
  onBinary(buffer) {
    this.#onAudio(buffer);
  }

  onMessage(event, data) {
    if (event === 'task-finished') {
      this.#onDone();
    }
  }

  // 流式送入文字片段（可以是词、短句）
  sendText(text) {
    this.sendContinue({
      payload: { input: { text } },
    });
  }
}

export { VOICES as TTS_VOICES, MODELS as TTS_MODELS };
