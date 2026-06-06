/**
 * 测试完整管道：ASR → 翻译 → TTS
 *
 * 用法：
 *   node test/test-pipeline.js audio.wav
 *
 * audio.wav 需为 16kHz/16bit/mono 格式
 * 转换命令（需安装 ffmpeg）：
 *   ffmpeg -i input.wav -ar 16000 -ac 1 -sample_fmt s16 audio.wav
 */
import 'dotenv/config';
import fs from 'fs';
import { InterpretPipeline } from '../src/pipeline/interpretPipeline.js';

const audioFile = process.argv[2];
if (!audioFile) {
  console.error('Usage: node test/test-pipeline.js <audio.wav>');
  process.exit(1);
}

const audioChunks = [];
let translationBuffer = '';

const pipeline = new InterpretPipeline({
  dashscopeApiKey: process.env.DASHSCOPE_API_KEY,
  srcLang: 'auto',
  tgtLang: 'en',

  onTranscript: (text, isFinal) => {
    if (isFinal) {
      console.log(`\n[原文 ✓] ${text}`);
    } else {
      process.stdout.write(`\r[识别中] ${text}          `);
    }
  },

  onTranslation: (chunk) => {
    translationBuffer += chunk;
    process.stdout.write(`\r[翻译中] ${translationBuffer}          `);
  },

  onAudio: (buf) => {
    audioChunks.push(buf);
    process.stdout.write('♪');
  },

  onError: (err) => console.error('\n[错误]', err.message),
});

console.log('=== Full Pipeline Test ===\n');
console.log('Starting pipeline...');
await pipeline.start();
console.log('Pipeline ready ✓\n');

const wav = fs.readFileSync(audioFile);
const pcm = wav.slice(44);
const chunkSize = Math.floor(16000 * 2 * 0.1);  // 100ms

console.log(`Streaming ${audioFile} (${(pcm.length / 1024).toFixed(0)}KB PCM)...\n`);

for (let i = 0; i < pcm.length; i += chunkSize) {
  pipeline.sendAudio(pcm.slice(i, i + chunkSize));
  await new Promise(r => setTimeout(r, 100));
}

console.log('\n\nWaiting for final results...');
await new Promise(r => setTimeout(r, 1000));

await pipeline.stop();

if (audioChunks.length > 0) {
  const outPath = new URL('./pipeline-output.mp3', import.meta.url).pathname;
  fs.writeFileSync(outPath, Buffer.concat(audioChunks));
  console.log(`\nTTS audio saved → ${outPath}`);
}

console.log('Pipeline test complete');
