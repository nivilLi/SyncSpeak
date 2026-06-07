## Why

SyncSpeak 目前只有 Flutter 移动端，无法在电脑浏览器中使用。Web 端让用户无需安装 App 即可直接在 Chrome 中完成同声传译，覆盖会议、课堂等桌面使用场景。

## What Changes

- 新增 `web/` 目录，基于 **Vue 3 + Vite + Naive UI** 构建 Web 前端
- Web 端对接现有 WebSocket 服务端，协议不变
- 浏览器原生 API 替代 Flutter 插件：`ScriptProcessorNode` 采集麦克风 PCM、`AudioContext` 播放 TTS MP3
- UI 交互参考 Otter.ai 风格：上方原文字幕区 + 下方译文字幕区，底部麦克风控制栏，历史句渐小渐淡
- 仅支持 Chrome（利用 Chrome 对 Web Audio API 的完整支持）

## Capabilities

### New Capabilities

- `web-app`: Web 前端整体应用，包含页面结构、样式、WebSocket 连接管理
- `web-audio-capture`: 浏览器麦克风采集，输出 16kHz/16bit/mono PCM 帧（每 100ms）
- `web-audio-playback`: 基于 AudioContext 的 MP3 块队列播放，无缝衔接 TTS 音频流
- `web-subtitle-ui`: 字幕展示组件，当前句大字加粗 + 历史句渐小渐淡，双语分区布局

### Modified Capabilities

## Impact

- 新增顶层目录 `web/`，不影响 `app/`（Flutter）和 `server/`（Node.js）
- 服务端代码零修改，复用现有 WebSocket 协议
- 新增前端依赖：`vue`、`naive-ui`、`vite`（仅 `web/` 目录，不影响 server/app）
- `.gitignore` 新增 `web/node_modules/` 和 `web/dist/`
