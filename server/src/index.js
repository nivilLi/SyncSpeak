import 'dotenv/config';
import { WebSocketServer } from 'ws';
import { InterpretPipeline } from './pipeline/interpretPipeline.js';
import { createLogger } from './utils/logger.js';

const logger = createLogger('Server');
const PORT = process.env.PORT ?? 3000;

const wss = new WebSocketServer({ port: PORT });
logger.info(`WebSocket server listening on ws://localhost:${PORT}`);

wss.on('connection', (ws) => {
  logger.info('Client connected');
  let pipeline = null;

  ws.on('message', async (data, isBinary) => {
    // 二进制帧 = PCM 音频块
    if (isBinary) {
      pipeline?.sendAudio(data);
      return;
    }

    let msg;
    try { msg = JSON.parse(data); } catch { return; }

    // 控制指令
    switch (msg.type) {
      case 'start': {
        if (pipeline) break;
        pipeline = new InterpretPipeline({
          dashscopeApiKey: process.env.DASHSCOPE_API_KEY,
          srcLang: msg.srcLang ?? 'auto',
          tgtLang: msg.tgtLang ?? 'en',

          onTranscript: (text, isFinal) =>
            send(ws, { type: 'transcript', text, isFinal }),

          onTranslation: (chunk) =>
            send(ws, { type: 'translation', chunk }),

          // 音频块用二进制帧发送，减少 base64 开销
          onAudio: (buffer) => {
            if (ws.readyState === ws.OPEN) ws.send(buffer);
          },

          onError: (err) => {
            logger.error(err);
            send(ws, { type: 'error', message: err.message });
          },
        });

        try {
          await pipeline.start();
          send(ws, { type: 'started' });
        } catch (err) {
          logger.error('Pipeline start failed', err);
          send(ws, { type: 'error', message: err.message });
          pipeline = null;
        }
        break;
      }

      case 'stop': {
        await pipeline?.stop();
        pipeline = null;
        send(ws, { type: 'stopped' });
        break;
      }

      default:
        logger.warn('Unknown message type:', msg.type);
    }
  });

  ws.on('close', async () => {
    logger.info('Client disconnected');
    await pipeline?.stop();
    pipeline = null;
  });

  ws.on('error', (err) => logger.error('Client WS error', err.message));
});

function send(ws, obj) {
  if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(obj));
}
