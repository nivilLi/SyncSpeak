/**
 * 测试 ASR 服务：用生成的 PCM 静音帧测试连接，再用真实音频测试识别
 *
 * 用法：
 *   node test/test-asr.js              # 只测连接（静音帧）
 *   node test/test-asr.js audio.wav    # 用 WAV 文件测试识别（需 16kHz/16bit/mono）
 */
import 'dotenv/config';
import fs from 'fs';
import { AsrService } from '../src/services/asr.js';

const audioFile = process.argv[2];

const asr = new AsrService(process.env.DASHSCOPE_API_KEY, {
  onPartial: (text) => process.stdout.write(`\r  partial: ${text}          `),
  onFinal:   (text) => console.log(`\n  ✓ final: "${text}"`),
});

console.log('=== ASR Service Test ===\n');
console.log('Connecting...');
await asr.connect();

console.log('Starting task...');
await asr.startTask();
console.log('Task started ✓\n');

if (audioFile) {
  // 读取 WAV 文件，跳过 44 字节 WAV header，每 100ms 发一帧
  console.log(`Streaming file: ${audioFile}`);
  const wav = fs.readFileSync(audioFile);
  const pcm = wav.slice(44);  // 跳过 WAV header
  const chunkSize = 16000 * 2 * 0.1;  // 100ms @ 16kHz/16bit

  for (let i = 0; i < pcm.length; i += chunkSize) {
    asr.sendAudio(pcm.slice(i, i + chunkSize));
    await new Promise(r => setTimeout(r, 100));  // 模拟实时速率
  }
  console.log('File streaming done, waiting for final result...');
  await new Promise(r => setTimeout(r, 2000));
} else {
  // 发 2 秒静音（验证连接）
  console.log('Sending 2s silence (connection test only)...');
  const silence = Buffer.alloc(16000 * 2 * 2);  // 2s
  const chunkSize = 16000 * 2 * 0.1;
  for (let i = 0; i < silence.length; i += chunkSize) {
    asr.sendAudio(silence.slice(i, i + chunkSize));
    await new Promise(r => setTimeout(r, 100));
  }
  console.log('Connection test done (no speech detected in silence, that is expected)');
}

await asr.finishTask();
asr.close();
console.log('\nASR test complete');
