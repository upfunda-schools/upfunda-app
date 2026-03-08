import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0-100
  final double height;
  final Color? activeColor;
  final Color? backgroundColor;

  const ProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.activeColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100) / 100;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.grey200,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: activeColor ?? AppColors.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
