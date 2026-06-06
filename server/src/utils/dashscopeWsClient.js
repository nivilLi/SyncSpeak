/**
 * 阿里云百炼 WebSocket 基础客户端
 *
 * 封装连接建立、认证、task 生命周期（run-task / continue-task / finish-task）
 * ASR 和 TTS 服务继承此类，只需实现各自的业务逻辑。
 */

import WebSocket from 'ws';
import { v4 as uuidv4 } from 'uuid';
import { createLogger } from './logger.js';

const DASHSCOPE_WS_URL = 'wss://dashscope.aliyuncs.com/api-ws/v1/inference';

export class DashscopeWsClient {
  #apiKey;
  #ws = null;
  #taskId = null;
  #taskStarted = false;
  #startResolve = null;
  #startReject = null;
  #logger;

  constructor(apiKey, loggerName) {
    this.#apiKey = apiKey;
    this.#logger = createLogger(loggerName);
  }

  get logger() { return this.#logger; }
  get taskId() { return this.#taskId; }

  // 子类实现：返回 run-task 的 header + payload
  buildRunTaskPayload() {
    throw new Error('buildRunTaskPayload() must be implemented');
  }

  // 子类实现：处理从服务器收到的消息
  onMessage(event, data) {
    throw new Error('onMessage() must be implemented');
  }

  // 子类实现：处理服务器发来的二进制帧（TTS 音频）
  onBinary(buffer) {}

  async connect() {
    return new Promise((resolve, reject) => {
      this.#ws = new WebSocket(DASHSCOPE_WS_URL, {
        headers: { Authorization: `Bearer ${this.#apiKey}` },
      });

      this.#ws.on('open', () => {
        this.#logger.debug('WebSocket connected');
        resolve();
      });

      this.#ws.on('message', (data, isBinary) => {
        if (isBinary) {
          this.onBinary(data);
          return;
        }
        let parsed;
        try { parsed = JSON.parse(data); } catch { return; }

        const event = parsed.header?.event;
        this.#logger.debug('←', event, JSON.stringify(parsed.header));

        if (event === 'task-started') {
          this.#taskStarted = true;
          this.#startResolve?.();
        } else if (event === 'task-failed') {
          const msg = parsed.header?.error_message ?? parsed.header?.message ?? JSON.stringify(parsed);
          this.#logger.error('task-failed:', msg);
          const err = new Error(msg);
          if (this.#startReject) {
            this.#startReject(err);
          } else {
            // task-failed 发生在任务运行中（不是 startTask 阶段）
            this.onMessage(event, parsed);
          }
          this.#taskStarted = false;
        } else {
          this.onMessage(event, parsed);
        }
      });

      this.#ws.on('error', (err) => {
        this.#logger.error('WebSocket error', err.message);
        reject(err);
      });

      this.#ws.on('close', (code) => {
        this.#logger.debug('WebSocket closed', code);
        this.#taskStarted = false;
      });
    });
  }

  async startTask() {
    this.#taskId = uuidv4();
    this.#taskStarted = false;

    return new Promise((resolve, reject) => {
      this.#startResolve = resolve;
      this.#startReject = reject;

      const payload = this.buildRunTaskPayload();
      this.#send({
        header: { action: 'run-task', task_id: this.#taskId, streaming: 'duplex' },
        ...payload,
      });

      this.#logger.debug('→ run-task', this.#taskId);
    });
  }

  // 发送文本/音频数据帧
  sendContinue(payload) {
    this.#send({
      header: { action: 'continue-task', task_id: this.#taskId, streaming: 'duplex' },
      ...payload,
    });
  }

  // 结束任务，返回 Promise（等待 task-finished）
  finishTask() {
    return new Promise((resolve) => {
      const handler = (data, isBinary) => {
        if (isBinary) return;
        let parsed;
        try { parsed = JSON.parse(data); } catch { return; }
        const event = parsed.header?.event;
        if (event === 'task-finished' || event === 'task-failed') {
          this.#ws.off('message', handler);
          resolve();
        }
      };
      this.#ws.on('message', handler);
      this.#send({
        header: { action: 'finish-task', task_id: this.#taskId, streaming: 'duplex' },
        payload: { input: {} },
      });
      this.#logger.debug('→ finish-task');
    });
  }

  close() {
    this.#ws?.close();
  }

  #send(obj) {
    if (this.#ws?.readyState === WebSocket.OPEN) {
      this.#ws.send(JSON.stringify(obj));
    }
  }

  // 直接发送二进制（音频块）
  sendBinary(buffer) {
    if (this.#ws?.readyState === WebSocket.OPEN) {
      this.#ws.send(buffer);
    }
  }
}
