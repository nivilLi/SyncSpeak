## ADDED Requirements

### Requirement: 双区字幕布局
页面 SHALL 分为上下两个字幕区：上方显示原文（transcript），下方显示译文（translation），中间有声波分隔线。

#### Scenario: 字幕正常显示
- **WHEN** 服务端发送 `{ type: 'transcript', text, isFinal }` 和 `{ type: 'translation', chunk }`
- **THEN** 原文显示在上方区域，译文显示在下方区域

### Requirement: 当前句大字加粗，历史句渐小渐淡
当前正在识别/翻译的句子 SHALL 以最大字号加粗显示，历史句按时间递减字号并降低透明度。

#### Scenario: 新句子到来
- **WHEN** 收到 `isFinal: true` 的 transcript
- **THEN** 该句进入历史列表，字号缩小、透明度降低；新的 partial 文本以大字号展示

#### Scenario: 空状态提示
- **WHEN** 未开始传译或无语音输入
- **THEN** 字幕区显示灰色提示文字（"等待语音输入..."）

### Requirement: 声波分隔线动画
传译进行中时，中间分隔线 SHALL 显示波形动画；停止后动画静止。

#### Scenario: 传译中
- **WHEN** 传译处于 started 状态
- **THEN** 分隔线显示 CSS 动画波形效果

### Requirement: 语言对选择和模式切换
顶部工具栏 SHALL 提供语言对下拉（中→英 / 英→中 / 自动）和输出模式切换（字幕 / TTS）。

#### Scenario: 切换语言对
- **WHEN** 用户在下拉选择语言对（未传译时）
- **THEN** 选项被记录，下次开始传译时生效

#### Scenario: 传译中禁用切换
- **WHEN** 传译正在进行
- **THEN** 语言对下拉禁用，防止状态混乱
