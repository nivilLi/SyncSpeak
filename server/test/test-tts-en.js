import 'dotenv/config';
import fs from 'fs';
import { TtsService } from '../src/services/tts.js';

const chunks = [];
const tts = new TtsService(process.env.DASHSCOPE_API_KEY, {
  voice: 'longanhuan',
  onAudio: (buf) => { chunks.push(buf); process.stdout.write('▓'); },
  onDone: () => console.log('\nDone'),
});

await tts.connect();
await tts.startTask();

const text = "The weather is wonderful today. Let's go hiking together. Great! I haven't exercised in a long time either.";
console.log(`Sending: "${text}"\n`);
tts.sendText(text);

await tts.finishTask();
tts.close();

if (chunks.length) {
  fs.writeFileSync('test/output-en.mp3', Buffer.concat(chunks));
  console.log(`\nSaved test/output-en.mp3 (${Buffer.concat(chunks).length} bytes)`);
}
