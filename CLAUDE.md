# CLAUDE.md — 同声传译助手

## 项目概览

中英双向实时同声传译 App。Flutter（iOS/Android）+ Node.js 后端 + 阿里云语音 API + Claude Haiku 翻译。

参考 TODO.md 了解进度，参考 README.md 了解架构。

## 目录

```
server/   Node.js 后端
app/      Flutter 前端（待创建）
```

## 后端（server/）

**运行**
```bash
cd server && npm run dev   # node --watch 热重载
```

**环境变量**（`.env`）
```
DASHSCOPE_API_KEY=   # 阿里云百炼
ANTHROPIC_API_KEY=   # Anthropic
PORT=3000
LOG_LEVEL=debug      # 开发时开 debug
```

**核心分层**

```
utils/dashscopeWsClient.js   ← 阿里云 WS 基类，不要直接改
services/asr.js              ← 继承基类，只处理 ASR 业务
services/tts.js              ← 继承基类，只处理 TTS 业务
services/translation.js      ← Claude Haiku，独立不继承基类
pipeline/interpretPipeline.js ← 串联三个服务，对外唯一入口
index.js                     ← WebSocket 服务，定义客户端协议
```

**WebSocket 基类扩展方式**

新增阿里云语音服务时，继承 `DashscopeWsClient`，实现两个方法：
```js
buildRunTaskPayload() { return { payload: { ... } }; }
onMessage(event, data) { /* 处理 result-generated 等事件 */ }
onBinary(buffer) { /* 可选，TTS 接收音频用 */ }
```

**客户端协议**（Flutter ↔ 服务端）

客户端发：
- `{ type: 'start', srcLang: 'auto'|'zh'|'en', tgtLang: 'zh'|'en' }` — 启动
- `{ type: 'stop' }` — 停止
- Binary PCM（16kHz/16bit/mono，每 100ms）— 音频流

服务端发：
- `{ type: 'started' }` — 就绪
- `{ type: 'transcript', text, isFinal }` — 原文字幕
- `{ type: 'translation', chunk }` — 译文 token 流
- Binary MP3 — TTS 音频块
- `{ type: 'error', message }` — 错误

## 代码规范

- ESM（`import/export`），不用 `require`
- 私有字段用 `#`（class private fields）
- 回调用选项对象传入，不用位置参数
- 不写注释解释"做什么"，只在"为什么"非显而易见时写
- 日志用 `createLogger(prefix)` 工厂，不直接用 `console.log`
- 错误向上抛，在 pipeline 层统一处理

## 前端（app/）— 待开发

Flutter，状态管理用 Riverpod 或 Provider（待定）。
麦克风库：`flutter_sound` 或 `record`。
WebSocket：`web_socket_channel`。
