## ADDED Requirements

### Requirement: 单页应用入口
Web 前端 SHALL 以单个 HTML 页面形式存在于 `web/index.html`，无需构建工具，可通过任意静态文件服务直接访问。

#### Scenario: 直接打开页面
- **WHEN** 用户通过 Chrome 访问 `web/index.html`
- **THEN** 页面加载完成，显示完整 UI，无 JS 报错

### Requirement: WebSocket 连接管理
应用 SHALL 在用户点击"开始"时建立 WebSocket 连接，点击"停止"或页面关闭时断开连接。

#### Scenario: 连接成功
- **WHEN** 用户点击开始按钮，服务端正常运行
- **THEN** WebSocket 连接建立，发送 `{ type: 'start', srcLang, tgtLang }`，收到 `{ type: 'started' }` 后 UI 切换为"传译中"状态

#### Scenario: 连接失败
- **WHEN** 服务端未启动或地址错误
- **THEN** 页面显示错误信息，按钮恢复为可点击状态

#### Scenario: 语言方向设置
- **WHEN** 用户在下拉菜单选择语言对（中→英 / 英→中 / 自动）
- **THEN** start 指令携带对应的 `srcLang` / `tgtLang` 参数

### Requirement: 服务端地址可配置
`web/app.js` 顶部 SHALL 提供 `WS_URL` 常量，用户修改后刷新生效。

#### Scenario: 修改服务地址
- **WHEN** 用户修改 `app.js` 中的 `WS_URL` 并刷新页面
- **THEN** 应用连接到新地址
