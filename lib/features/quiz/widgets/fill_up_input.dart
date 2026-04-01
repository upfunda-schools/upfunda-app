import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FillUpInput extends StatelessWidget {
  final String? currentValue;
  final bool showResult;
  final bool isCorrect;
  final String? correctAnswer;
  final bool isIntegerType;
  final ValueChanged<String> onChanged;

  const FillUpInput({
    super.key,
    this.currentValue,
    this.showResult = false,
    this.isCorrect = false,
    this.correctAnswer,
    this.isIntegerType = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          enabled: !showResult,
          keyboardType:
              isIntegerType ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          controller: TextEditingController(text: currentValue)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: currentValue?.length ?? 0),
            ),
          decoration: InputDecoration(
            hintText: isIntegerType ? 'Enter a number...' : 'Type your answer...',
            filled: true,
            fillColor: showResult
                ? (isCorrect
                    ? AppColors.correct.withValues(alpha: 0.08)
                    : AppColors.incorrect.withValues(alpha: 0.08))
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: showResult
                    ? (isCorrect ? AppColors.correct : AppColors.incorrect)
                    : AppColors.grey200,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: showResult
                    ? (isCorrect ? AppColors.correct : AppColors.incorrect)
                    : AppColors.grey200,
                width: 1.5,
              ),
            ),
            suffixIcon: showResult
                ? Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? AppColors.correct : AppColors.incorrect,
                  )
                : null,
          ),
        ),
        if (showResult && !isCorrect && correctAnswer != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.correct.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 16, color: AppColors.correct),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Correct answer: ${correctAnswer?.replaceAll(RegExp(r'<[^>]*>'), '')}',
                    style: const TextStyle(
                      color: AppColors.correct,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
