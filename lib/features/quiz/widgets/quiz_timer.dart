import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QuizTimerWidget extends StatelessWidget {
  final String timerDisplay;
  final int remainingSeconds;
  final int totalSeconds;

  const QuizTimerWidget({
    super.key,
    required this.timerDisplay,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  Color get _timerColor {
    if (remainingSeconds <= 30) return AppColors.incorrect;
    if (remainingSeconds <= 60) return AppColors.review;
    return AppColors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _timerColor == AppColors.white
            ? Colors.white.withValues(alpha: 0.15)
            : _timerColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: _timerColor, size: 18),
          const SizedBox(width: 6),
          Text(
            timerDisplay,
            style: TextStyle(
              color: _timerColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
