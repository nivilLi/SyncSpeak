## Context

现有服务端已提供完整的 WebSocket 协议（JSON 控制帧 + Binary PCM/MP3），Flutter 移动端已验证端到端流程。Web 前端只需实现"浏览器侧的客户端"，协议层无需改动。

目录结构：
```
web/
├── index.html
├── package.json          # vue + naive-ui + vite
├── vite.config.js
└── src/
    ├── main.js           # Vue 应用挂载
    ├── App.vue           # 根组件（布局）
    ├── composables/
    │   ├── useWebSocket.js   # WebSocket 连接管理
    │   ├── useAudioCapture.js  # 麦克风采集
    │   └── useAudioPlayer.js   # TTS 播放队列
    └── components/
        ├── SubtitlePanel.vue   # 字幕区（含历史渐淡）
        ├── WaveformDivider.vue # 声波分隔线
        └── ControlBar.vue      # 底部控制栏
```

## Goals / Non-Goals

**Goals:**
- 在 Chrome 中完整复现移动端同传功能（ASR 字幕 + 译文字幕 + TTS 播放）
- 麦克风采集输出与服务端协议匹配的 PCM（16kHz/16bit/mono，100ms/帧）
- TTS 音频无缝排队播放，与移动端体验一致
- UI 参考 Otter.ai：双栏字幕 + 历史渐淡 + 底部控制栏

**Non-Goals:**
- Safari / Firefox 兼容（Chrome only）
- 构建工具 / bundler（直接用原生 ES Modules）
- 用户账号 / 持久化历史记录
- 多人 / 会议室模式

## Decisions

### D1：Vue 3 + Vite + Naive UI

**选择**：Vue 3 作为 UI 框架，Vite 作为构建工具，Naive UI 作为组件库。  
**理由**：
- Vue 3 Composition API + `composables` 模式天然适合封装 WebSocket、AudioContext 等有状态逻辑，代码组织清晰
- Naive UI 内置深色主题，与 Flutter 端深色风格一致，直接用 `n-select`、`n-button`、`n-tag` 等组件省去样式工作
- Vite 开发体验好（HMR），生产构建输出静态文件，部署方式与 Vanilla JS 相同
**备选**：Vanilla JS — 状态管理和组件复用会变成手动 DOM 操作，维护成本高。

### D2：MediaRecorder → ScriptProcessor 降采样，输出 16kHz PCM

**选择**：`AudioContext`（采样率锁定 16000Hz）+ `ScriptProcessorNode`（即将废弃但 Chrome 完整支持）采集 Float32 → 转 Int16 PCM。  
**理由**：Chrome 允许在 `AudioContext` 创建时指定 `sampleRate: 16000`，省去重采样步骤；`ScriptProcessorNode` 虽已废弃但在 Chrome 上稳定，`AudioWorklet` 实现更复杂且收益有限。  
**备选**：`MediaRecorder` 输出 WebM/Opus → 服务端解码 — 需改动服务端，违反"零修改服务端"原则。

### D3：AudioContext.decodeAudioData + 手动队列播放 MP3

**选择**：收到 MP3 Binary 帧 → `decodeAudioData` → 推入 `AudioBufferSourceNode` 队列，前一节点 `onended` 时播放下一个。  
**理由**：与移动端 `ConcatenatingAudioSource` 语义等价；Chrome 原生解码 MP3 无需额外库。  
**备选**：`<audio>` 元素 + Blob URL — 无法精确控制队列衔接时机，停顿明显。

### D4：UI 布局参考 Otter.ai，上下分屏

```
┌─────────────────────────────────────────────┐
│  SyncSpeak   [中→英 ▾]   [字幕|TTS]         │  ← 顶部工具栏
├─────────────────────────────────────────────┤
│                                             │
│   原文字幕（历史句渐小渐淡）                   │  ← 上半区（深色）
│                                             │
├──────────── 声波分隔线 ─────────────────────┤
│                                             │
│   译文字幕（历史句渐小渐淡）                   │  ← 下半区（深紫渐变）
│                                             │
├─────────────────────────────────────────────┤
│         [● 开始传译]   状态文字              │  ← 底部控制栏
└─────────────────────────────────────────────┘
```

与移动端 Flutter UI 保持视觉一致（同色系、同字幕层级逻辑）。

## Risks / Trade-offs

- **ScriptProcessorNode 废弃风险** → Chrome 短期内不会移除，项目 MVP 阶段可接受；未来可替换为 AudioWorklet。
- **AudioContext 需用户手势激活** → 点击"开始"按钮时创建 AudioContext，满足浏览器自动播放策略。
- **16kHz AudioContext 创建失败**（极少数系统不支持）→ 捕获异常并提示用户。
- **服务端地址硬编码** → 页面顶部 `const WS_URL` 常量，用户修改后刷新生效，MVP 阶段够用。

## Migration Plan

1. 创建 `web/` 目录，实现三个文件
2. 本地用 `python -m http.server` 验证
3. 连接已有 Node.js 服务端测试完整链路
4. 合并 PR

无需数据迁移，无回滚风险（纯新增目录）。
