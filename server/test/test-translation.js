/**
 * 测试翻译服务：中→英、英→中，验证上下文连贯性
 */
import 'dotenv/config';
import { TranslationService } from '../src/services/translation.js';

const translator = new TranslationService(process.env.DASHSCOPE_API_KEY);

const cases = [
  { text: '今天天气真不错。',               src: 'zh',   tgt: 'en' },
  { text: '我们去吃火锅吧。',               src: 'zh',   tgt: 'en' },
  { text: 'That sounds great, I love hotpot!', src: 'en', tgt: 'zh' },
  { text: '好的，走吧！',                   src: 'auto', tgt: 'en' },
];

console.log('=== Translation Service Test (Qwen-MT) ===\n');

for (const { text, src, tgt } of cases) {
  process.stdout.write(`[${src}→${tgt}] "${text}"\n  → `);
  await translator.translateStream(text, src, tgt, (chunk) => process.stdout.write(chunk));
  process.stdout.write('\n\n');
}
