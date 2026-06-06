/// 应用配置常量
/// 修改 [wsUrl] 指向实际后端地址
class AppConfig {
  AppConfig._();

  /// WebSocket 服务端地址
  /// 本机调试：ws://localhost:3000
  /// iOS 模拟器访问 Mac 主机：ws://localhost:3000（自动映射）
  /// Android 模拟器访问 Mac 主机：ws://10.0.2.2:3000
  /// 真机调试：替换为局域网 IP，例如 ws://192.168.1.100:3000
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:3000',
  );
}
