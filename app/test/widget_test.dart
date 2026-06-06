import 'package:flutter_test/flutter_test.dart';
import 'package:simultaneous_interpretation/models/app_state.dart';

void main() {
  group('SubtitleEntry', () {
    test('copyWith preserves timestamp', () {
      final entry = SubtitleEntry(
        text: 'hello',
        isFinal: false,
        timestamp: DateTime(2024),
      );
      final updated = entry.copyWith(text: 'world', isFinal: true);
      expect(updated.text, 'world');
      expect(updated.isFinal, true);
      expect(updated.timestamp, entry.timestamp);
    });
  });

  group('LanguagePair', () {
    test('zhToEn has correct langs', () {
      expect(LanguagePair.zhToEn.srcLang, 'zh');
      expect(LanguagePair.zhToEn.tgtLang, 'en');
    });

    test('enToZh has correct langs', () {
      expect(LanguagePair.enToZh.srcLang, 'en');
      expect(LanguagePair.enToZh.tgtLang, 'zh');
    });
  });
}
