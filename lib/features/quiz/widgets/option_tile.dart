import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OptionTile extends StatelessWidget {
  final String optionId;
  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final bool isHidden;
  final String? correctOptionId;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.optionId,
    required this.text,
    required this.index,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.isHidden = false,
    this.correctOptionId,
    this.onTap,
  });

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  Color get _bgColor {
    if (isHidden) return AppColors.grey100.withValues(alpha: 0.5);
    if (!showResult) {
      return isSelected
          ? AppColors.quizPrimary.withValues(alpha: 0.12)
          : Colors.white;
    }
    // Show result mode
    if (optionId == correctOptionId) {
      return AppColors.correct.withValues(alpha: 0.12);
    }
    if (isSelected && !isCorrect) {
      return AppColors.incorrect.withValues(alpha: 0.12);
    }
    return Colors.white;
  }

  Color get _borderColor {
    if (isHidden) return AppColors.grey200;
    if (!showResult) {
      return isSelected ? AppColors.quizPrimary : AppColors.grey200;
    }
    if (optionId == correctOptionId) return AppColors.correct;
    if (isSelected && !isCorrect) return AppColors.incorrect;
    return AppColors.grey200;
  }

  Color get _badgeColor {
    if (isHidden) return AppColors.grey400;
    if (!showResult) {
      return isSelected ? AppColors.quizPrimary : AppColors.grey400;
    }
    if (optionId == correctOptionId) return AppColors.correct;
    if (isSelected && !isCorrect) return AppColors.incorrect;
    return AppColors.grey400;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isHidden || showResult ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // Letter badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _badgeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  index < _letters.length ? _letters[index] : '${index + 1}',
                  style: TextStyle(
                    color: _badgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: isHidden ? AppColors.grey400 : AppColors.grey800,
                  decoration: isHidden ? TextDecoration.lineThrough : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (showResult && optionId == correctOptionId)
              const Icon(Icons.check_circle, color: AppColors.correct, size: 22),
            if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: AppColors.incorrect, size: 22),
          ],
        ),
      ),
    );
  }
}
