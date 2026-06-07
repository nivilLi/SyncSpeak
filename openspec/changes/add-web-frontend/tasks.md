## 1. 项目初始化（Vue 3 + Vite + Naive UI）

- [x] 1.1 创建 `web/` 目录，`npm create vite@latest` 初始化 Vue 3 项目
- [x] 1.2 安装依赖：`naive-ui`、`vfonts`（Naive UI 字体）
- [x] 1.3 配置 `main.js`：挂载 Vue 应用，全局注册 Naive UI dark theme
- [x] 1.4 在 `App.vue` 中搭建页面骨架：顶部工具栏、原文区、声波分隔线、译文区、底部控制栏
- [x] 1.5 在 `.gitignore` 添加 `web/node_modules/` 和 `web/dist/`

## 2. 样式与组件

- [x] 2.1 配置 Naive UI `darkTheme` + 自定义 `themeOverrides`（主色 `#7B2FBE`，背景 `#1a1a2e`）
- [x] 2.2 `SubtitlePanel.vue`：双区字幕布局（上下分屏各 flex 1），历史句渐小渐淡
- [x] 2.3 `WaveformDivider.vue`：声波分隔线 CSS 动画，传译中播放
- [x] 2.4 `ControlBar.vue`：开始/停止按钮 + 状态文字，使用 `n-button`
- [x] 2.5 顶部工具栏：语言对 `n-select` + 模式切换 `n-radio-group`

## 3. 麦克风采集（web-audio-capture）

- [x] 3.1 实现 `getUserMedia` 申请麦克风权限，权限拒绝时显示错误
- [x] 3.2 创建 `AudioContext({ sampleRate: 16000 })`，接入麦克风流
- [x] 3.3 用 `ScriptProcessorNode` 捕获 Float32 PCM，转换为 Int16（Little-Endian）
- [x] 3.4 每 100ms 收集 3200 字节，通过 WebSocket 发送 Binary 帧

## 4. WebSocket 连接管理（web-app）

- [x] 4.1 在 `app.js` 顶部定义 `WS_URL` 常量
- [x] 4.2 实现点击"开始"时建立 WebSocket，发送 `{ type: 'start', srcLang, tgtLang }`
- [x] 4.3 处理 `started` / `error` / `stopped` 控制帧，更新 UI 状态
- [x] 4.4 处理 `transcript` 帧（partial + final），更新原文字幕区
- [x] 4.5 处理 `translation` 帧（chunk 流），追加到译文字幕区
- [x] 4.6 实现点击"停止"：发送 `{ type: 'stop' }`，关闭 WebSocket 和 AudioContext

## 5. TTS 音频播放（web-audio-playback）

- [x] 5.1 收到 Binary 帧时调用 `AudioContext.decodeAudioData` 解码 MP3
- [x] 5.2 实现 `AudioBufferSourceNode` 播放队列：前一块 `onended` 时触发下一块
- [x] 5.3 字幕模式下静默丢弃 Binary 帧（不解码不播放）

## 6. UI 交互（web-subtitle-ui）

- [x] 6.1 实现语言对下拉（中→英 / 英→中 / 自动），传译中禁用
- [x] 6.2 实现输出模式切换按钮（字幕 / TTS）
- [x] 6.3 实现字幕区历史管理：final 句入历史列表，列表渲染时应用渐淡样式
- [x] 6.4 实现空状态提示文字（未开始时显示）

## 7. 测试验证

- [x] 7.1 `npm run dev` 启动 Vite 开发服务器，Chrome 访问验证页面加载
- [x] 7.2 启动服务端，端到端测试：说中文 → 原文字幕 → 英文译文 → TTS 播放
- [x] 7.3 验证 TTS 模式和字幕模式切换正常
- [x] 7.4 验证连接失败和麦克风权限拒绝的错误提示
