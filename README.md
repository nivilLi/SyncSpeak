# SyncSpeak — 同声传译助手

中英双向实时同声传译应用，Flutter（iOS/Android）+ Node.js 后端 + 阿里云语音 API。

## 演示视频

[📹 查看演示视频](https://pan.quark.cn/s/69e66bd3b3bc)

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
            阿里云百炼（DASHSCOPE_API_KEY 统一鉴权）
   FunASR ASR      Qwen-MT Flash   CosyVoice TTS
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
├── app/                           # Flutter 前端（iOS / Android）
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config.dart              # WS 地址配置
│   │   ├── models/app_state.dart
│   │   ├── providers/               # Riverpod 状态管理
│   │   ├── services/                # WebSocket / 麦克风 / 音频播放
│   │   ├── screens/                 # 主界面
│   │   └── widgets/                 # 字幕面板 / 声波动画 / 控制按钮
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
└── web/                           # Web 前端（Vue 3 + Vite + Naive UI）
    ├── index.html
    ├── package.json
    ├── vite.config.js
    └── src/
        ├── App.vue                  # 根组件（布局 + 状态）
        ├── composables/
        │   ├── useWebSocket.js      # WebSocket 连接管理
        │   ├── useAudioCapture.js   # 麦克风采集（16kHz PCM）
        │   └── useAudioPlayer.js    # TTS MP3 队列播放
        └── components/
            ├── SubtitlePanel.vue    # 字幕区（历史渐小渐淡）
            ├── WaveformDivider.vue  # 声波分隔线动画
            └── ControlBar.vue      # 底部控制栏
```

## 关键抽象

| 类/模块 | 职责 |
|--------|------|
| `DashscopeWsClient` | 阿里云 WebSocket 基类：连接、认证、task 生命周期 |
| `AsrService` | 继承基类，封装 FunASR 流式识别，回调 partial/final |
| `TtsService` | 继承基类，封装 CosyVoice 流式合成，接收二进制音频帧 |
| `TranslationService` | Qwen-MT Flash 流式翻译，OpenAI 兼容接口 |
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
| `DASHSCOPE_API_KEY` | 阿里云百炼 API Key（ASR + 翻译 + TTS 共用） |
| `PORT` | 服务端口，默认 3000 |
| `LOG_LEVEL` | 日志级别 debug/info/warn/error，默认 info |

## 前端运行

**Flutter（iOS / Android）**
```bash
cd app
flutter pub get
# 连接真机后
flutter run --dart-define=WS_URL=ws://<Mac局域网IP>:3000
```

**Web（Chrome）**
```bash
cd web
npm install
npm run dev
# 浏览器访问 http://localhost:5173
# 修改 src/composables/useWebSocket.js 顶部 WS_URL 指向服务端
```

## 当前状态

- ✅ 后端完整管道（ASR → 翻译 → TTS）联调通过
- ✅ Flutter Android 真机测试通过
- ✅ Web 端（Chrome）测试通过
- 🚧 iOS 待测试
- 🚧 服务端云部署
