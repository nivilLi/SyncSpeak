import 'package:flutter/material.dart';

import '../models/app_state.dart';

/// 底部开始/停止大圆按钮
class ControlButton extends StatefulWidget {
  final SessionState sessionState;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const ControlButton({
    super.key,
    required this.sessionState,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ControlButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessionState == SessionState.started) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.sessionState == SessionState.started;
    final isLoading = widget.sessionState == SessionState.connecting ||
        widget.sessionState == SessionState.stopping;

    return Center(
      child: ScaleTransition(
        scale: isActive ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: GestureDetector(
          onTap: isLoading
              ? null
              : (isActive ? widget.onStop : widget.onStart),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive
                  ? const RadialGradient(colors: [
                      Color(0xFFE53935),
                      Color(0xFFB71C1C),
                    ])
                  : const RadialGradient(colors: [
                      Color(0xFF7B2FBE),
                      Color(0xFF4A0E8F),
                    ]),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? const Color(0xFFE53935).withValues(alpha: 0.5)
                      : const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    isActive ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
          ),
        ),
      ),
    );
  }
}
