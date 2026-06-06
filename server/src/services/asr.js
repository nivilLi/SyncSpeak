/**
 * ASR 服务 — 阿里云百炼 FunASR 实时流式语音识别
 *
 * 用法：
 *   const asr = new AsrService(apiKey, { onPartial, onFinal });
 *   await asr.connect();
 *   await asr.startTask();
 *   asr.sendAudio(pcmBuffer);   // 持续调用
 *   await asr.finishTask();
 *   asr.close();
 */

import { DashscopeWsClient } from '../utils/dashscopeWsClient.js';

const MODELS = {
  funAsr: 'paraformer-realtime-v2',   // 中文最强，多方言
  qwen:   'qwen3-asr-flash-realtime', // 多语言，52 种语言
};

export class AsrService extends DashscopeWsClient {
  #onPartial;
  #onFinal;
  #model;

  /**
   * @param {string} apiKey
   * @param {{ onPartial?: (text: string) => void, onFinal?: (text: string) => void, model?: string }} opts
   */
  constructor(apiKey, { onPartial, onFinal, model = MODELS.funAsr } = {}) {
    super(apiKey, 'ASR');
    this.#onPartial = onPartial ?? (() => {});
    this.#onFinal   = onFinal   ?? (() => {});
    this.#model = model;
  }

  buildRunTaskPayload() {
    return {
      payload: {
        task_group: 'audio',
        task: 'asr',
        function: 'recognition',
        model: this.#model,
        parameters: {
          format: 'pcm',
          sample_rate: 16000,
          language_hints: ['zh', 'en'],  // 中英自动识别
          punctuation_prediction: true,
          inverse_text_normalization: true,
        },
        input: {},
      },
    };
  }

  onMessage(event, data) {
    if (event !== 'result-generated') return;

    const output = data.payload?.output;
    if (!output?.sentence) return;

    const { text, sentence_end } = output.sentence;
    if (!text) return;

    if (sentence_end) {
      this.logger.debug('final:', text);
      this.#onFinal(text);
    } else {
      this.logger.debug('partial:', text);
      this.#onPartial(text);
    }
  }

  // 发送 PCM 音频块（建议每 100ms 一次，16kHz/16bit/mono）
  sendAudio(pcmBuffer) {
    this.sendBinary(pcmBuffer);
  }
}

export { MODELS as ASR_MODELS };
