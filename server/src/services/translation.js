/**
 * 翻译服务 — 阿里云百炼 Qwen-MT 流式翻译，带滑动上下文窗口
 *
 * 使用 OpenAI 兼容接口，同一个 DASHSCOPE_API_KEY 即可，无需 Anthropic Key。
 *
 * 用法：
 *   const translator = new TranslationService(apiKey);
 *   await translator.translateStream('你好世界', 'zh', 'en', (chunk) => process.stdout.write(chunk));
 */

import OpenAI from 'openai';
import { createLogger } from '../utils/logger.js';

const logger = createLogger('Translation');

// Qwen-MT 要求语言名用英文全称
const LANG_NAMES = {
  zh: 'Chinese',
  en: 'English',
  ja: 'Japanese',
  ko: 'Korean',
  fr: 'French',
  de: 'German',
  es: 'Spanish',
};

export class TranslationService {
  #client;
  #model;

  /**
   * @param {string} apiKey  DashScope API Key
   * @param {{ model?: string }} opts
   */
  constructor(apiKey, { model = 'qwen-mt-flash' } = {}) {
    this.#client = new OpenAI({
      apiKey,
      baseURL: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    });
    this.#model = model;
  }

  /**
   * 流式翻译，逐 token 回调
   * @param {string} text    源文本
   * @param {string} srcLang 源语言 ('zh' | 'en' | 'auto')
   * @param {string} tgtLang 目标语言 ('zh' | 'en')
   * @param {(chunk: string) => void} onChunk
   * @returns {Promise<string>} 完整译文
   */
  async translateStream(text, srcLang, tgtLang, onChunk) {
    let fullText = '';

    const stream = await this.#client.chat.completions.create({
      model: this.#model,
      messages: this.#buildMessages(text, srcLang, tgtLang),
      stream: true,
    });

    for await (const chunk of stream) {
      const delta = chunk.choices[0]?.delta?.content;
      if (delta) {
        fullText += delta;
        onChunk(delta);
      }
    }

    logger.debug(`${srcLang}→${tgtLang}: "${text}" → "${fullText}"`);
    return fullText;
  }

  /**
   * 非流式翻译（一次性返回）
   */
  async translate(text, srcLang, tgtLang) {
    const response = await this.#client.chat.completions.create({
      model: this.#model,
      messages: this.#buildMessages(text, srcLang, tgtLang),
    });

    const translated = response.choices[0].message.content.trim();
    logger.debug(`${srcLang}→${tgtLang}: "${text}" → "${translated}"`);
    return translated;
  }

  // Qwen-MT 只支持 user/assistant，且只接受单轮
  // 将语言方向直接嵌入用户消息
  #buildMessages(text, srcLang, tgtLang) {
    const src = srcLang === 'auto' ? 'auto-detect' : (LANG_NAMES[srcLang] ?? srcLang);
    const tgt = LANG_NAMES[tgtLang] ?? tgtLang;
    return [
      {
        role: 'user',
        content: `Translate the following text from ${src} to ${tgt}. Output only the translation:\n${text}`,
      },
    ];
  }
}
