/**
 * 用 TTS 生成测试用的 WAV 文件（16kHz/16bit/mono），供 ASR 测试使用
 */
import 'dotenv/config';
import fs from 'fs';
import { TtsService } from '../src/services/tts.js';

const chunks = [];

const tts = new TtsService(process.env.DASHSCOPE_API_KEY, {
  model: 'cosyvoice-v2',
  voice: 'longxiaochun_v2',
  onAudio: (buf) => chunks.push(buf),
});

// 生成 PCM 格式（用于 ASR 回测）
tts.buildRunTaskPayload = function() {
  return {
    payload: {
      task_group: 'audio',
      task: 'tts',
      function: 'SpeechSynthesizer',
      model: 'cosyvoice-v2',
      parameters: {
        text_type: 'PlainText',
        voice: 'longxiaochun_v2',
        format: 'pcm',
        sample_rate: 16000,
        volume: 50,
        rate: 1.0,
        pitch: 1.0,
        enable_ssml: false,
      },
      input: {},
    },
  };
};

await tts.connect();
await tts.startTask();
tts.sendText('今天天气非常好，我们一起去爬山吧。');
tts.sendText('好啊，我也很久没有运动了。');
await tts.finishTask();
tts.close();

// 写成 WAV（加 44 字节 header）
const pcm = Buffer.concat(chunks);
const sampleRate = 16000;
const channels = 1;
const bitsPerSample = 16;
const byteRate = sampleRate * channels * bitsPerSample / 8;
const blockAlign = channels * bitsPerSample / 8;
const dataSize = pcm.length;
const fileSize = 36 + dataSize;

const header = Buffer.alloc(44);
header.write('RIFF', 0);
header.writeUInt32LE(fileSize, 4);
header.write('WAVE', 8);
header.write('fmt ', 12);
header.writeUInt32LE(16, 16);
header.writeUInt16LE(1, 20);
header.writeUInt16LE(channels, 22);
header.writeUInt32LE(sampleRate, 24);
header.writeUInt32LE(byteRate, 28);
header.writeUInt16LE(blockAlign, 32);
header.writeUInt16LE(bitsPerSample, 34);
header.write('data', 36);
header.writeUInt32LE(dataSize, 40);

const outPath = new URL('./test-speech.wav', import.meta.url).pathname;
fs.writeFileSync(outPath, Buffer.concat([header, pcm]));
console.log(`Generated ${outPath} (${(fileSize / 1024).toFixed(0)} KB)`);
