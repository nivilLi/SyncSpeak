import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// TTS 音频播放服务
/// 接收 MP3 二进制块，写入临时文件后顺序播放
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final List<Uint8List> _queue = [];
  bool _isPlaying = false;
  int _fileCounter = 0;

  bool get isPlaying => _isPlaying;

  /// 将 MP3 音频块加入播放队列
  void enqueue(Uint8List mp3Data) {
    _queue.add(mp3Data);
    if (!_isPlaying) {
      _playNext();
    }
  }

  Future<void> _playNext() async {
    if (_queue.isEmpty) {
      _isPlaying = false;
      return;
    }

    _isPlaying = true;
    final data = _queue.removeAt(0);

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tts_${_fileCounter++}.mp3');
      await file.writeAsBytes(data);

      await _player.setFilePath(file.path);
      await _player.play();

      // 等待播放完毕
      await _player.playerStateStream.firstWhere(
        (state) =>
            state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle,
      );

      // 清理临时文件（异步，不阻塞）
      file.delete().catchError((_) => file);
    } catch (_) {
      // 播放失败时继续下一段
    }

    _playNext();
  }

  /// 清空队列并停止播放
  Future<void> stop() async {
    _queue.clear();
    _isPlaying = false;
    await _player.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
