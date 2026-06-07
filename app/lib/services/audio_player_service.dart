import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// TTS 音频播放服务
/// 接收 MP3 二进制块，通过 ConcatenatingAudioSource 无缝排队播放，
/// 避免每块都执行 setFilePath 导致的 150-450ms 解码器初始化延迟。
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  ConcatenatingAudioSource? _playlist;
  bool _isStarted = false;
  int _fileCounter = 0;

  bool get isPlaying => _isStarted;

  /// 将 MP3 音频块写入临时文件并追加到播放列表
  Future<void> enqueue(Uint8List mp3Data) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/tts_${_fileCounter++}.mp3');
    await file.writeAsBytes(mp3Data);

    final source = AudioSource.file(file.path);

    if (!_isStarted || _playlist == null) {
      // 首块：新建 playlist，setAudioSource 后立即播放
      _playlist = ConcatenatingAudioSource(children: [source]);
      _isStarted = true;
      await _player.setAudioSource(_playlist!);
      _player.play(); // 不 await，让播放与后续入队并发进行

      // 播放完毕后重置状态，以便下次 enqueue 重新 setAudioSource
      _player.playerStateStream
          .where((s) => s.processingState == ProcessingState.completed)
          .first
          .then((_) {
        _isStarted = false;
        _playlist = null;
      }).catchError((_) {});
    } else {
      // 后续块：直接追加，just_audio 自动无缝衔接
      await _playlist!.add(source);
    }

    // 播放完后异步删除临时文件
    _player.playerStateStream
        .where((s) => s.processingState == ProcessingState.completed)
        .first
        .then((_) => file.delete())
        .catchError((_) => file);
  }

  /// 清空队列并停止播放；重置状态以便下次重新 setAudioSource
  Future<void> stop() async {
    _isStarted = false;
    _playlist = null;
    await _player.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
