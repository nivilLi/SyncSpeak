import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_state.dart';
import '../providers/interpreter_provider.dart';
import '../widgets/control_button.dart';
import '../widgets/subtitle_panel.dart';
import '../widgets/waveform_divider.dart';

class InterpreterScreen extends ConsumerWidget {
  const InterpreterScreen({super.key});

  static const Color _topBg = Color(0xFF1a1a2e);
  static const Color _accentColor = Color(0xFF7B2FBE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interpreterProvider);
    final notifier = ref.read(interpreterProvider.notifier);
    final isActive = state.sessionState == SessionState.started;

    return Scaffold(
      backgroundColor: _topBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 顶部工具栏 ──────────────────────────────
            _TopBar(
              languagePair: state.languagePair,
              outputMode: state.outputMode,
              sessionState: state.sessionState,
              onLanguagePairChanged: notifier.setLanguagePair,
              onOutputModeChanged: notifier.setOutputMode,
            ),

            // ── 原文区（上半屏）─────────────────────────
            Expanded(
              child: SubtitlePanel(
                history: state.transcriptHistory,
                currentText: state.currentTranscript,
                backgroundColor: _topBg,
                textColor: Colors.white,
                emptyHint: '等待语音输入...',
              ),
            ),

            // ── 声波分隔线 ─────────────────────────────
            WaveformDivider(
              isActive: isActive,
              color: _accentColor,
            ),

            // ── 译文区（下半屏）─────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF16213e),
                      Color(0xFF1a0533),
                    ],
                  ),
                ),
                child: SubtitlePanel(
                  history: state.translationHistory,
                  currentText: state.currentTranslation,
                  backgroundColor: Colors.transparent,
                  textColor: const Color(0xFFCE93D8),
                  emptyHint: '译文将在此显示...',
                ),
              ),
            ),

            // ── 错误提示 ───────────────────────────────
            if (state.errorMessage != null)
              _ErrorBanner(message: state.errorMessage!),

            // ── 底部控制区 ─────────────────────────────
            _BottomControls(
              sessionState: state.sessionState,
              onStart: notifier.startSession,
              onStop: notifier.stopSession,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// 顶部工具栏
// ──────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final LanguagePair languagePair;
  final OutputMode outputMode;
  final SessionState sessionState;
  final void Function(LanguagePair) onLanguagePairChanged;
  final void Function(OutputMode) onOutputModeChanged;

  const _TopBar({
    required this.languagePair,
    required this.outputMode,
    required this.sessionState,
    required this.onLanguagePairChanged,
    required this.onOutputModeChanged,
  });

  bool get _canChange =>
      sessionState == SessionState.idle ||
      sessionState == SessionState.error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 语言对下拉
          Expanded(
            child: _LanguagePairSelector(
              value: languagePair,
              enabled: _canChange,
              onChanged: onLanguagePairChanged,
            ),
          ),
          const SizedBox(width: 12),
          // 输出模式切换
          _ModeToggle(
            outputMode: outputMode,
            onChanged: onOutputModeChanged,
          ),
        ],
      ),
    );
  }
}

class _LanguagePairSelector extends StatelessWidget {
  final LanguagePair value;
  final bool enabled;
  final void Function(LanguagePair) onChanged;

  const _LanguagePairSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a4a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LanguagePair>(
          value: value,
          dropdownColor: const Color(0xFF2a2a4a),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7B2FBE)),
          isExpanded: true,
          onChanged: enabled ? (v) => onChanged(v!) : null,
          items: LanguagePair.values
              .map((pair) => DropdownMenuItem(
                    value: pair,
                    child: Text(pair.label),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final OutputMode outputMode;
  final void Function(OutputMode) onChanged;

  const _ModeToggle({
    required this.outputMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a4a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            icon: Icons.subtitles_outlined,
            label: '字幕',
            isSelected: outputMode == OutputMode.subtitle,
            onTap: () => onChanged(OutputMode.subtitle),
          ),
          _ModeButton(
            icon: Icons.volume_up_outlined,
            label: 'TTS',
            isSelected: outputMode == OutputMode.tts,
            onTap: () => onChanged(OutputMode.tts),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7B2FBE)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// 错误横幅
// ──────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFB71C1C).withValues(alpha: 0.85),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// 底部控制区
// ──────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final SessionState sessionState;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _BottomControls({
    required this.sessionState,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF16213e),
            Color(0xFF0d0d1a),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ControlButton(
            sessionState: sessionState,
            onStart: onStart,
            onStop: onStop,
          ),
          const SizedBox(height: 10),
          Text(
            _statusLabel(sessionState),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(SessionState state) {
    return switch (state) {
      SessionState.idle => '点击开始传译',
      SessionState.connecting => '正在连接...',
      SessionState.started => '传译中，点击停止',
      SessionState.stopping => '正在停止...',
      SessionState.error => '发生错误，点击重试',
    };
  }
}
