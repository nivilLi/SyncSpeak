## ADDED Requirements

### Requirement: MP3 块队列播放
应用 SHALL 将收到的 Binary MP3 帧依次解码并排队播放，前一块结束后立即播放下一块，无明显停顿。

#### Scenario: 连续 MP3 块
- **WHEN** 服务端连续发送多个 Binary MP3 帧
- **THEN** 每帧通过 `AudioContext.decodeAudioData` 解码后加入队列，前一块播完立即触发下一块，无停顿

#### Scenario: 仅字幕模式
- **WHEN** 用户切换到"字幕模式"
- **THEN** 收到 MP3 Binary 帧时不播放，静默丢弃

### Requirement: 用户手势激活 AudioContext
AudioContext SHALL 在用户点击"开始"按钮时创建，满足 Chrome 自动播放策略。

#### Scenario: 点击开始后播放正常
- **WHEN** 用户点击开始按钮后服务端返回 TTS 音频
- **THEN** 音频正常播放，无 `AudioContext was not allowed to start` 错误
