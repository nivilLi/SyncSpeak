/**
 * 同声传译管道
 *
 * 串联 ASR → 翻译 → TTS，对外提供简洁接口：
 *   pipeline.start()       开始监听
 *   pipeline.sendAudio()   推入麦克风音频块
 *   pipeline.stop()        停止并释放资源
 *
 * 事件回调：
 *   onTranscript(text, isFinal)   识别结果（实时 partial + 最终 final）
 *   onTranslation(text)           翻译结果
 *   onAudio(buffer)               TTS 音频块，直接转发给客户端播放
 *   onError(err)                  错误回调
 */

import { AsrService } from '../services/asr.js';
import { TtsService, TTS_VOICES, TTS_MODELS } from '../services/tts.js';
import { TranslationService } from '../services/translation.js';
import { createLogger } from '../utils/logger.js';

const logger = createLogger('Pipeline');

// 翻译 token 流按标点分片的分隔符
const PHRASE_SPLIT_RE = /([，。！？,.!?])/;

// 检测文本语言（简单规则：含中文字符则为中文）
function detectLang(text) {
  return /[一-龥]/.test(text) ? 'zh' : 'en';
}

export class InterpretPipeline {
  #asr;
  #dashscopeApiKey;
  #tgtLang;
  #translator;
  #callbacks;
  #running = false;
  #ttsQueue = Promise.resolve();  // 串行化 TTS 任务，避免音频乱序
  #nextTts = null;                // lookahead：下一个 TTS 实例（已 connect+startTask）

  /**
   * @param {{
   *   dashscopeApiKey: string,
   *   srcLang?: 'zh' | 'en' | 'auto',
   *   tgtLang?: 'zh' | 'en',
   *   onTranscript?: (text: string, isFinal: boolean) => void,
   *   onTranslation?: (text: string) => void,
   *   onAudio?: (buffer: Buffer) => void,
   *   onError?: (err: Error) => void,
   * }} opts
   */
  constructor({
    dashscopeApiKey,
    srcLang = 'auto',
    tgtLang = 'en',
    onTranscript = () => {},
    onTranslation = () => {},
    onAudio = () => {},
    onError = (e) => logger.error(e),
  }) {
    this.#dashscopeApiKey = dashscopeApiKey;
    this.#tgtLang = tgtLang;
    this.#callbacks = { onTranscript, onTranslation, onAudio, onError };
    this.#translator = new TranslationService(dashscopeApiKey);

    // ASR：final 句子才触发翻译+TTS，partial 只回调给前端展示
    this.#asr = new AsrService(dashscopeApiKey, {
      onPartial: (text) => onTranscript(text, false),
      onFinal:   (text) => {
        onTranscript(text, true);
        this.#handleFinalText(text, srcLang, tgtLang);
      },
    });
  }

  async start() {
    if (this.#running) return;
    logger.info('Starting pipeline...');

    // 只启动 ASR，TTS 按需创建（避免 CosyVoice task 空闲超时）
    await this.#asr.connect();
    await this.#asr.startTask();

    this.#running = true;
    logger.info('Pipeline ready');
  }

  // 推入麦克风 PCM 音频块
  sendAudio(pcmBuffer) {
    if (!this.#running) return;
    this.#asr.sendAudio(pcmBuffer);
  }

  async stop() {
    if (!this.#running) return;
    this.#running = false;
    logger.info('Stopping pipeline...');

    // 1. 结束 ASR — 服务端会推送最后一批 final 结果，触发 #handleFinalText 更新 #ttsQueue
    await this.#asr.finishTask().catch(() => {});
    this.#asr.close();

    // 2. 等待所有翻译+TTS 任务完成（#ttsQueue 已被 final 回调更新）
    await this.#ttsQueue.catch(() => {});

    // 3. 若 lookahead TTS 实例未被用到，关闭它
    if (this.#nextTts) {
      const pending = this.#nextTts;
      this.#nextTts = null;
      pending.then(t => t.close()).catch(() => {});
    }

    logger.info('Pipeline stopped');
  }

  // 新建一个 TTS 实例并完成握手，返回 Promise<TtsService>
  #createReadyTts() {
    const tts = new TtsService(this.#dashscopeApiKey, {
      voice: this.#tgtLang === 'zh' ? TTS_VOICES.zh : TTS_VOICES.en,
      onAudio: this.#callbacks.onAudio,
    });
    return tts.connect().then(() => tts.startTask()).then(() => tts);
  }

  #handleFinalText(text, srcLang, tgtLang) {
    const detectedSrc = srcLang === 'auto' ? detectLang(text) : srcLang;
    const detectedTgt = detectedSrc === 'zh' ? 'en' : 'zh';
    const target = tgtLang === 'auto' ? detectedTgt : tgtLang;

    // 串行化：上一段 TTS 结束后再处理下一段，保证音频顺序
    this.#ttsQueue = this.#ttsQueue.then(async () => {
      try {
        // lookahead：消费预建连接（若存在），同时立即开始建立下一个
        const ttsPromise = this.#nextTts ?? this.#createReadyTts();
        this.#nextTts = this.#createReadyTts();

        let pendingPhrase = '';

        // 翻译 token 流到达时按标点分片，立即 sendText，不等全句完成
        const translated = await this.#translator.translateStream(
          text, detectedSrc, target,
          async (chunk) => {
            this.#callbacks.onTranslation(chunk);
            pendingPhrase += chunk;

            // 按标点切分，每个完整短语立即送入 TTS
            const parts = pendingPhrase.split(PHRASE_SPLIT_RE);
            // split 含捕获组：[phrase, delimiter, phrase, delimiter, ...]
            // 最后一段（不含标点）留作下次拼接
            pendingPhrase = parts[parts.length - 1];

            if (parts.length > 1) {
              const tts = await ttsPromise;
              // 将所有完整短语（含跟随的标点）合并后送入
              const toSend = parts.slice(0, -1).join('');
              if (toSend.trim()) tts.sendText(toSend);
            }
          },
        );

        const tts = await ttsPromise;

        // 翻译结束后 pendingPhrase 保存最后一段未带标点的尾部文字
        const clean = translated.replace(/[—–]/g, '-').trim();
        if (!clean) {
          tts.close();
          return;
        }

        if (pendingPhrase.trim()) tts.sendText(pendingPhrase.trim());

        await tts.finishTask();
        tts.close();
      } catch (err) {
        this.#callbacks.onError(err);
      }
    });
  }
}
