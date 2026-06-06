import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_state.dart';
import '../services/audio_player_service.dart';
import '../services/microphone_service.dart';
import '../services/websocket_service.dart';

/// 传译状态快照（不可变）
class InterpreterState {
  final SessionState sessionState;
  final LanguagePair languagePair;
  final OutputMode outputMode;

  /// 原文字幕历史（已确认的 final 条目）
  final List<SubtitleEntry> transcriptHistory;

  /// 当前原文（可能是 partial）
  final String currentTranscript;

  /// 译文历史（已确认的完整句子）
  final List<SubtitleEntry> translationHistory;

  /// 当前正在拼接的译文
  final String currentTranslation;

  /// 错误信息
  final String? errorMessage;

  const InterpreterState({
    this.sessionState = SessionState.idle,
    this.languagePair = LanguagePair.zhToEn,
    this.outputMode = OutputMode.subtitle,
    this.transcriptHistory = const [],
    this.currentTranscript = '',
    this.translationHistory = const [],
    this.currentTranslation = '',
    this.errorMessage,
  });

  InterpreterState copyWith({
    SessionState? sessionState,
    LanguagePair? languagePair,
    OutputMode? outputMode,
    List<SubtitleEntry>? transcriptHistory,
    String? currentTranscript,
    List<SubtitleEntry>? translationHistory,
    String? currentTranslation,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InterpreterState(
      sessionState: sessionState ?? this.sessionState,
      languagePair: languagePair ?? this.languagePair,
      outputMode: outputMode ?? this.outputMode,
      transcriptHistory: transcriptHistory ?? this.transcriptHistory,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      translationHistory: translationHistory ?? this.translationHistory,
      currentTranslation: currentTranslation ?? this.currentTranslation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 传译核心 Notifier
class InterpreterNotifier extends Notifier<InterpreterState> {
  late final WebSocketService _wsService;
  late final MicrophoneService _micService;
  late final AudioPlayerService _audioService;

  @override
  InterpreterState build() {
    _wsService = WebSocketService();
    _micService = MicrophoneService();
    _audioService = AudioPlayerService();

    // 注册 WebSocket 回调
    _wsService.onStarted = _onStarted;
    _wsService.onTranscript = _onTranscript;
    _wsService.onTranslation = _onTranslation;
    _wsService.onAudio = _onAudio;
    _wsService.onError = _onWsError;
    _wsService.onDisconnected = _onDisconnected;

    // 注册麦克风回调
    _micService.onAudioFrame = _onAudioFrame;
    _micService.onError = _onMicError;

    // 清理资源
    ref.onDispose(() {
      _micService.dispose();
      _wsService.disconnect();
      _audioService.dispose();
    });

    return const InterpreterState();
  }

  // ──────────────────────────────────────────
  // 公开操作
  // ──────────────────────────────────────────

  /// 开始传译
  Future<void> startSession() async {
    if (state.sessionState != SessionState.idle &&
        state.sessionState != SessionState.error) {
      return;
    }

    state = state.copyWith(
      sessionState: SessionState.connecting,
      transcriptHistory: [],
      currentTranscript: '',
      translationHistory: [],
      currentTranslation: '',
      clearError: true,
    );

    try {
      await _wsService.connect();
      _wsService.sendStart(
        srcLang: state.languagePair.srcLang,
        tgtLang: state.languagePair.tgtLang,
      );
      // 等待服务端 started 消息后再开始录音（由 _onStarted 处理）
    } catch (e) {
      state = state.copyWith(
        sessionState: SessionState.error,
        errorMessage: '连接失败: $e',
      );
    }
  }

  /// 停止传译
  Future<void> stopSession() async {
    if (state.sessionState != SessionState.started) return;

    state = state.copyWith(sessionState: SessionState.stopping);

    await _micService.stopRecording();
    await _wsService.disconnect();
    await _audioService.stop();

    state = state.copyWith(sessionState: SessionState.idle);
  }

  /// 切换语言对
  void setLanguagePair(LanguagePair pair) {
    if (state.sessionState == SessionState.idle ||
        state.sessionState == SessionState.error) {
      state = state.copyWith(languagePair: pair);
    }
  }

  /// 切换输出模式
  void setOutputMode(OutputMode mode) {
    state = state.copyWith(outputMode: mode);
  }

  // ──────────────────────────────────────────
  // WebSocket 回调
  // ──────────────────────────────────────────

  void _onStarted() {
    state = state.copyWith(sessionState: SessionState.started);
    _micService.startRecording();
  }

  void _onTranscript(String text, bool isFinal) {
    if (isFinal && text.isNotEmpty) {
      // 把 final 结果加入历史
      final updated = List<SubtitleEntry>.from(state.transcriptHistory)
        ..add(SubtitleEntry(
          text: text,
          isFinal: true,
          timestamp: DateTime.now(),
        ));
      state = state.copyWith(
        transcriptHistory: updated,
        currentTranscript: '',
      );
    } else {
      state = state.copyWith(currentTranscript: text);
    }
  }

  void _onTranslation(String chunk) {
    // 检测句子结束标志（句号、换行），将当前译文存入历史
    final updated = state.currentTranslation + chunk;
    final sentenceEnders = RegExp(r'[。！？\.\!\?\n]');

    if (sentenceEnders.hasMatch(chunk)) {
      final history = List<SubtitleEntry>.from(state.translationHistory)
        ..add(SubtitleEntry(
          text: updated.trim(),
          isFinal: true,
          timestamp: DateTime.now(),
        ));
      state = state.copyWith(
        translationHistory: history,
        currentTranslation: '',
      );
    } else {
      state = state.copyWith(currentTranslation: updated);
    }
  }

  void _onAudio(Uint8List audioData) {
    if (state.outputMode == OutputMode.tts) {
      _audioService.enqueue(audioData);
    }
  }

  void _onWsError(String message) {
    state = state.copyWith(
      sessionState: SessionState.error,
      errorMessage: message,
    );
    _micService.stopRecording();
    _audioService.stop();
  }

  void _onDisconnected() {
    if (state.sessionState == SessionState.started ||
        state.sessionState == SessionState.connecting) {
      state = state.copyWith(
        sessionState: SessionState.error,
        errorMessage: '服务端连接断开',
      );
      _micService.stopRecording();
      _audioService.stop();
    }
  }

  // ──────────────────────────────────────────
  // 麦克风回调
  // ──────────────────────────────────────────

  void _onAudioFrame(Uint8List pcmFrame) {
    if (state.sessionState == SessionState.started) {
      _wsService.sendAudioFrame(pcmFrame);
    }
  }

  void _onMicError(String error) {
    state = state.copyWith(
      sessionState: SessionState.error,
      errorMessage: '麦克风错误: $error',
    );
  }
}

/// 全局 Provider
final interpreterProvider =
    NotifierProvider<InterpreterNotifier, InterpreterState>(
  InterpreterNotifier.new,
);
