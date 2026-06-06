import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// 麦克风采集服务
/// 采集 PCM 16kHz/16bit/mono 音频，每 100ms 回调一帧
class MicrophoneService {
  static const int _sampleRate = 16000;
  static const int _channels = 1;  // mono
  // 每 100ms 的样本数：16000 * 0.1 = 1600 样本 * 2 字节 = 3200 字节
  static const int _frameBytes = 3200;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSubscription;
  final List<int> _buffer = [];

  bool _isRecording = false;

  void Function(Uint8List pcmFrame)? onAudioFrame;
  void Function(String error)? onError;

  bool get isRecording => _isRecording;

  /// 请求麦克风权限
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  /// 检查是否有麦克风权限
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// 开始录音，以 PCM raw 格式输出
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPerms = await hasPermission();
    if (!hasPerms) {
      final granted = await requestPermission();
      if (!granted) {
        onError?.call('麦克风权限被拒绝');
        return;
      }
    }

    try {
      _buffer.clear();

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: _channels,
        ),
      );

      _isRecording = true;

      _audioSubscription = stream.listen(
        (data) {
          _buffer.addAll(data);
          // 每积累到 _frameBytes 字节就回调一帧
          while (_buffer.length >= _frameBytes) {
            final frame = Uint8List.fromList(_buffer.sublist(0, _frameBytes));
            _buffer.removeRange(0, _frameBytes);
            onAudioFrame?.call(frame);
          }
        },
        onError: (error) {
          onError?.call('录音错误: $error');
          _isRecording = false;
        },
        onDone: () {
          _isRecording = false;
        },
      );
    } catch (e) {
      _isRecording = false;
      onError?.call('启动录音失败: $e');
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    await _audioSubscription?.cancel();
    _audioSubscription = null;

    await _recorder.stop();
    _isRecording = false;
    _buffer.clear();
  }

  void dispose() {
    stopRecording();
    _recorder.dispose();
  }
}
