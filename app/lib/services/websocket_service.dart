import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../config.dart';

/// WebSocket 连接到后端的服务封装
/// 处理 JSON 控制消息和二进制音频帧的收发
class WebSocketService {
  // 可修改 WebSocket 服务端地址，见 lib/config.dart
  static const String defaultWsUrl = AppConfig.wsUrl;

  final String wsUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // 对外暴露的回调
  void Function()? onStarted;
  void Function(String text, bool isFinal)? onTranscript;
  void Function(String chunk)? onTranslation;
  void Function(Uint8List audioData)? onAudio;
  void Function(String message)? onError;
  void Function()? onDisconnected;

  bool get isConnected => _channel != null;

  WebSocketService({this.wsUrl = defaultWsUrl});

  Future<void> connect() async {
    if (_channel != null) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          onError?.call('WebSocket 错误: $error');
          _cleanup();
        },
        onDone: () {
          onDisconnected?.call();
          _cleanup();
        },
      );
    } catch (e) {
      _cleanup();
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    if (message is List<int> || message is Uint8List) {
      // 二进制帧 = MP3 音频块
      final audioData = message is Uint8List
          ? message
          : Uint8List.fromList(message as List<int>);
      onAudio?.call(audioData);
      return;
    }

    if (message is String) {
      try {
        final json = jsonDecode(message) as Map<String, dynamic>;
        final type = json['type'] as String?;

        switch (type) {
          case 'started':
            onStarted?.call();
          case 'transcript':
            final text = json['text'] as String? ?? '';
            final isFinal = json['isFinal'] as bool? ?? false;
            onTranscript?.call(text, isFinal);
          case 'translation':
            final chunk = json['chunk'] as String? ?? '';
            onTranslation?.call(chunk);
          case 'error':
            final msg = json['message'] as String? ?? '未知错误';
            onError?.call(msg);
          default:
            // 忽略未知类型
            break;
        }
      } catch (_) {
        // JSON 解析失败，忽略
      }
    }
  }

  /// 发送启动指令
  void sendStart({required String srcLang, required String tgtLang}) {
    _sendJson({'type': 'start', 'srcLang': srcLang, 'tgtLang': tgtLang});
  }

  /// 发送停止指令
  void sendStop() {
    _sendJson({'type': 'stop'});
  }

  /// 发送 PCM 音频帧（二进制）
  void sendAudioFrame(Uint8List pcmData) {
    _channel?.sink.add(pcmData);
  }

  void _sendJson(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  Future<void> disconnect() async {
    _sendStop();
    await _channel?.sink.close(ws_status.normalClosure);
    _cleanup();
  }

  void _sendStop() {
    try {
      _sendJson({'type': 'stop'});
    } catch (_) {}
  }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
  }
}
