/// 传译会话状态枚举
enum SessionState {
  idle,        // 未开始
  connecting,  // 连接中
  started,     // 传译中
  stopping,    // 停止中
  error,       // 错误
}

/// 字幕条目
class SubtitleEntry {
  final String text;
  final bool isFinal;
  final DateTime timestamp;

  const SubtitleEntry({
    required this.text,
    required this.isFinal,
    required this.timestamp,
  });

  SubtitleEntry copyWith({String? text, bool? isFinal}) {
    return SubtitleEntry(
      text: text ?? this.text,
      isFinal: isFinal ?? this.isFinal,
      timestamp: timestamp,
    );
  }
}

/// 语言对配置
enum LanguagePair {
  zhToEn(srcLang: 'zh', tgtLang: 'en', label: '中 → 英'),
  enToZh(srcLang: 'en', tgtLang: 'zh', label: '英 → 中'),
  autoToEn(srcLang: 'auto', tgtLang: 'en', label: '自动 → 英'),
  autoToZh(srcLang: 'auto', tgtLang: 'zh', label: '自动 → 中');

  const LanguagePair({
    required this.srcLang,
    required this.tgtLang,
    required this.label,
  });

  final String srcLang;
  final String tgtLang;
  final String label;
}

/// 输出模式
enum OutputMode {
  subtitle, // 字幕模式
  tts,      // TTS 音频模式
}
