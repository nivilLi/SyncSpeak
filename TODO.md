# TODO — 同声传译助手开发进度

## 已完成

### 后端（Node.js）
- [x] 项目骨架与目录结构
- [x] `DashscopeWsClient` — 阿里云 WebSocket 基类（连接/认证/task 生命周期）
- [x] `AsrService` — FunASR 流式语音识别（partial + final 回调）
- [x] `TtsService` — CosyVoice 流式语音合成（二进制音频流输出）
- [x] `TranslationService` — Claude Haiku 流式翻译（滑动上下文窗口）
- [x] `InterpretPipeline` — 串联 ASR→翻译→TTS，TTS 队列保序
- [x] `index.js` — WebSocket 服务入口，定义客户端协议
- [x] Logger 工具
- [x] README 架构文档
- [x] CLAUDE.md 代码规范

---

## 待完成

### 后端
- [x] **联调测试** — ASR / 翻译 / TTS 三个服务单独测试全部通过
- [x] **完整管道测试** — ASR→翻译→TTS 端到端打通，生成 pipeline-output.mp3
- [ ] **VAD 集成** — 服务端检测静音，自动分句（降低 ASR 误触）
- [ ] **错误重试** — WebSocket 断连后自动重连（指数退避）
- [ ] **语言自动检测优化** — 当前用简单正则，可换 `franc` 库
- [ ] **配置热更新** — 运行时切换语言对，无需重启管道

### 前端（Flutter）
- [x] **项目初始化** — 手动创建 `app/` 目录结构与 pubspec.yaml
- [x] **WebSocket 客户端** — `lib/services/websocket_service.dart`，连接/发控制指令/收 JSON+Binary
- [x] **麦克风采集** — `lib/services/microphone_service.dart`，PCM 16kHz/16bit/mono，每 100ms 发一帧（3200 字节）
- [x] **UI：主界面** — `lib/screens/interpreter_screen.dart`，上下分屏深色主题
- [x] **UI：字幕显示** — `lib/widgets/subtitle_panel.dart`，当前句大字加粗 + 历史句渐小渐淡
- [x] **UI：分隔线动画** — `lib/widgets/waveform_divider.dart`，录音中声波动画 / 停止时静态线
- [x] **UI：模式切换** — 字幕模式 / TTS 音频模式，顶部切换按钮
- [x] **UI：语言对选择** — 中→英 / 英→中 / 自动→英 / 自动→中 下拉选择
- [x] **TTS 音频播放** — `lib/services/audio_player_service.dart`，接收 MP3 帧写临时文件后顺序播放
- [x] **状态管理** — `lib/providers/interpreter_provider.dart`，Riverpod Notifier，完整生命周期
- [x] **配置文件** — `lib/config.dart`，WS 地址通过 `--dart-define=WS_URL=...` 覆盖

### 发布
- [x] iOS 打包配置（`ios/Runner/Info.plist` 麦克风权限 + 后台音频）
- [x] Android 打包配置（`android/app/src/main/AndroidManifest.xml` 麦克风 + 网络权限）
- [ ] 服务端部署（Docker / 云服务器）

---

## 技术决策记录

| 决策 | 选择 | 原因 |
|------|------|------|
| 后端语言 | Node.js | 快速开发，WebSocket 生态成熟 |
| 前端 | Flutter | 一套代码打包 iOS/Android |
| ASR | 阿里云 FunASR (`paraformer-realtime-v2`) | 中文最强，流式低延迟 |
| 翻译 | 阿里云百炼 `qwen-mt-flash` | OpenAI 兼容接口，流式输出，同一 Key |
| TTS | 阿里云 CosyVoice (`cosyvoice-v3-flash`) | 中文音质最好，首包 150ms |
| 通信协议 | WebSocket | 全双工，适合实时音频流 |
| TTS 音频格式 | MP3（服务端→客户端）| 压缩率高，减少带宽 |
| ASR 音频格式 | PCM 16kHz/16bit/mono（客户端→服务端）| FunASR 原生格式，无需转码 |
