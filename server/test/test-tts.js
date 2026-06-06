/**
 * 测试 TTS 服务：发送文本，接收音频，保存为 output.mp3
 */
import 'dotenv/config';
import fs from 'fs';
import { TtsService } from '../src/services/tts.js';

const chunks = [];

const tts = new TtsService(process.env.DASHSCOPE_API_KEY, {
  onAudio: (buf) => {
    chunks.push(buf);
    process.stdout.write('▓');
  },
  onDone: () => console.log('\nTTS done signal received'),
});

console.log('=== TTS Service Test ===\n');
console.log('Connecting...');
await tts.connect();

console.log('Starting task...');
await tts.startTask();

const sentences = ['你好，欢迎使用同声传译助手。', '今天天气不错，我们去吃火锅吧。'];
for (const s of sentences) {
  console.log(`Sending: "${s}"`);
  tts.sendText(s);
}

await tts.finishTask();
tts.close();

if (chunks.length > 0) {
  const outPath = new URL('./output.mp3', import.meta.url).pathname;
  fs.writeFileSync(outPath, Buffer.concat(chunks));
  console.log(`\nSaved ${chunks.length} chunks → ${outPath}`);
  console.log(`Total audio size: ${(Buffer.concat(chunks).length / 1024).toFixed(1)} KB`);
} else {
  console.log('\n⚠️  No audio received');
}
