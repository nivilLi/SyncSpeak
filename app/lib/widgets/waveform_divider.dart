import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 中央分隔线：录音时显示声波动画，停止时显示静态线
class WaveformDivider extends StatefulWidget {
  final bool isActive;
  final Color color;

  const WaveformDivider({
    super.key,
    required this.isActive,
    this.color = const Color(0xFF7B2FBE),
  });

  @override
  State<WaveformDivider> createState() => _WaveformDividerState();
}

class _WaveformDividerState extends State<WaveformDivider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(WaveformDivider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WaveformPainter(
              progress: _controller.value,
              isActive: widget.isActive,
              color: widget.color,
            ),
            size: const Size(double.infinity, 48),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final Color color;

  const _WaveformPainter({
    required this.progress,
    required this.isActive,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!isActive) {
      // 静态横线
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint..color = color.withValues(alpha: 0.5),
      );
      return;
    }

    // 声波动画：多条正弦波叠加
    const barCount = 32;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      // 不同频率正弦叠加
      final amplitude = size.height * 0.35 *
          (0.5 + 0.5 * math.sin(i * 0.4 + progress * math.pi * 2)) *
          (0.6 + 0.4 * math.sin(i * 0.7 - progress * math.pi * 1.5));

      canvas.drawLine(
        Offset(x, size.height / 2 - amplitude),
        Offset(x, size.height / 2 + amplitude),
        paint..color = color.withValues(alpha: 0.7 + 0.3 * math.sin(i * 0.3)),
      );
    }

    // 叠加一条连续曲线
    final wavePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final wavePath = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final t = x / size.width;
      final y = size.height / 2 +
          math.sin(t * math.pi * 6 + progress * math.pi * 2) *
              size.height *
              0.2;
      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isActive != isActive;
}
