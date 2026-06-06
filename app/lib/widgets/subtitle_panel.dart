import 'package:flutter/material.dart';

import '../models/app_state.dart';

/// 字幕面板：历史句渐小渐淡，当前句大字加粗
class SubtitlePanel extends StatefulWidget {
  final List<SubtitleEntry> history;
  final String currentText;
  final Color backgroundColor;
  final Color textColor;
  final String emptyHint;

  const SubtitlePanel({
    super.key,
    required this.history,
    required this.currentText,
    required this.backgroundColor,
    required this.textColor,
    required this.emptyHint,
  });

  @override
  State<SubtitlePanel> createState() => _SubtitlePanelState();
}

class _SubtitlePanelState extends State<SubtitlePanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(SubtitlePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 有新内容时滚动到底部
    if (oldWidget.history.length != widget.history.length ||
        oldWidget.currentText != widget.currentText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty =
        widget.history.isEmpty && widget.currentText.isEmpty;

    if (isEmpty) {
      return Container(
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: Text(
          widget.emptyHint,
          style: TextStyle(
            color: widget.textColor.withValues(alpha: 0.35),
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      color: widget.backgroundColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: widget.history.length + (widget.currentText.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          final isCurrentItem = widget.currentText.isNotEmpty &&
              index == widget.history.length;

          if (isCurrentItem) {
            return _buildCurrentLine(widget.currentText);
          }

          final entry = widget.history[index];
          // 距当前越远越淡越小
          final distanceFromEnd = widget.history.length - 1 - index;
          return _buildHistoryLine(entry.text, distanceFromEnd);
        },
      ),
    );
  }

  Widget _buildCurrentLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: widget.textColor,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildHistoryLine(String text, int distanceFromEnd) {
    // 越远越小（最小 14）越淡
    final fontSize = (26.0 - distanceFromEnd * 2.5).clamp(14.0, 26.0);
    final opacity = (1.0 - distanceFromEnd * 0.18).clamp(0.2, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: widget.textColor.withValues(alpha: opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
      ),
    );
  }
}
