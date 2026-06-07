## ADDED Requirements

### Requirement: 麦克风权限申请
应用 SHALL 在用户点击开始时通过 `getUserMedia` 申请麦克风权限，权限被拒绝时显示错误提示。

#### Scenario: 权限授予
- **WHEN** 用户点击开始，浏览器弹出麦克风权限请求，用户允许
- **THEN** 麦克风开始采集，页面进入传译状态

#### Scenario: 权限拒绝
- **WHEN** 用户拒绝麦克风权限
- **THEN** 页面显示"需要麦克风权限"错误，停止连接流程

### Requirement: 16kHz PCM 帧采集
应用 SHALL 以 16kHz 采样率、16bit、mono 格式采集麦克风音频，每 100ms 发送一帧（3200 字节）到服务端。

#### Scenario: 正常采集
- **WHEN** 麦克风权限已授予，传译已启动
- **THEN** 每 100ms 通过 WebSocket 发送一个 3200 字节的 Binary 帧（16kHz/16bit/mono PCM）

#### Scenario: 停止采集
- **WHEN** 用户点击停止
- **THEN** 停止采集，关闭 AudioContext，发送 `{ type: 'stop' }` 到服务端
