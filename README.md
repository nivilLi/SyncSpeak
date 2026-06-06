# Simultaneous Interpretation Assistant

中英双向实时同声传译应用，Flutter 前端 + Node.js 后端。

## 架构总览

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App (iOS/Android)          │
│  麦克风采集 PCM → WebSocket → 字幕展示 + TTS 音频播放  │
└───────────────────────┬─────────────────────────────┘
                        │ WebSocket (binary: PCM/MP3, text: JSON)
┌───────────────────────▼─────────────────────────────┐
│                   Node.js Server                     │
│                                                     │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────┐  │
│  │  AsrService │→  │TranslationSvc│→  │TtsService│  │
│  │ (FunASR WS) │   │ (Claude Haiku│   │(CosyVoice│  │
│  │  流式识别   │   │  流式翻译)   │   │  WS流式) │  │
│  └─────────────┘   └──────────────┘   └──────────┘  │
│         ↑                 ↑                  ↑       │
│         └─────── InterpretPipeline ──────────┘       │
└─────────────────────────────────────────────────────┘
                        │
         ┌──────────────┼──────────────┐
         ▼              ▼              ▼
   阿里云百炼        Anthropic      阿里云百炼
   FunASR ASR      Claude Haiku    CosyVoice TTS
```

## 数据流

```
麦克风 PCM (16kHz/16bit/mono)
  → WebSocket 二进制帧 → 服务端
  → AsrService (FunASR WebSocket)
  → onPartial(text)  → 前端实时字幕
  → onFinal(text)    → TranslationService (Claude Haiku stream)
                       → onTranslation(chunk) → 前端翻译字幕
                       → TtsService.sendText(chunk)  ← token 级流式送入
                         → onAudio(buffer) → 前端 WebSocket 二进制帧
                           → Flutter 音频播放器
```

## 目录结构

```
simultaneousInterpretation/
├── server/                        # Node.js 后端
│   ├── src/
│   │   ├── index.js               # WebSocket 服务入口
│   │   ├── pipeline/
│   │   │   └── interpretPipeline.js  # 串联 ASR→翻译→TTS
│   │   ├── services/
│   │   │   ├── asr.js             # 阿里云 FunASR 流式识别
│   │   │   ├── tts.js             # 阿里云 CosyVoice 流式合成
│   │   │   └── translation.js     # Claude Haiku 流式翻译
│   │   └── utils/
│   │       ├── dashscopeWsClient.js  # 阿里云 WS 基类（ASR/TTS 复用）
│   │       └── logger.js          # 日志工具
│   ├── .env.example
│   └── package.json
└── app/                           # Flutter 前端（待开发）
```

## 关键抽象

| 类/模块 | 职责 |
|--------|------|
| `DashscopeWsClient` | 阿里云 WebSocket 基类：连接、认证、task 生命周期 |
| `AsrService` | 继承基类，封装 FunASR 流式识别，回调 partial/final |
| `TtsService` | 继承基类，封装 CosyVoice 流式合成，接收二进制音频帧 |
| `TranslationService` | Claude Haiku 流式翻译，滑动上下文窗口保持连贯 |
| `InterpretPipeline` | 串联三个服务，管理 TTS 音频队列顺序，对外暴露简洁接口 |

## WebSocket 协议（Server ↔ Flutter）

**客户端 → 服务端**

| 帧类型 | 格式 | 说明 |
|--------|------|------|
| 控制指令 | JSON `{ type: 'start', srcLang, tgtLang }` | 启动传译 |
| 控制指令 | JSON `{ type: 'stop' }` | 停止传译 |
| 音频数据 | Binary (PCM 16kHz/16bit/mono) | 麦克风音频块，每 100ms |

**服务端 → 客户端**

| 帧类型 | 格式 | 说明 |
|--------|------|------|
| 状态 | JSON `{ type: 'started' }` | 管道就绪 |
| 原文字幕 | JSON `{ type: 'transcript', text, isFinal }` | 实时识别结果 |
| 译文字幕 | JSON `{ type: 'translation', chunk }` | 翻译 token 流 |
| TTS 音频 | Binary (MP3) | 合成音频块，直接送播放器 |
| 错误 | JSON `{ type: 'error', message }` | 错误信息 |

## 快速开始

```bash
cd server
cp .env.example .env   # 填入 API Key
npm install
npm run dev            # 启动（node --watch 热重载）
```

## 环境变量

| 变量 | 说明 |
|------|------|
| `DASHSCOPE_API_KEY` | 阿里云百炼 API Key |
| `ANTHROPIC_API_KEY` | Anthropic API Key |
| `PORT` | 服务端口，默认 3000 |
| `LOG_LEVEL` | 日志级别 debug/info/warn/error，默认 info |
