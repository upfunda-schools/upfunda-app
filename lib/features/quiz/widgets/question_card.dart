import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/quiz_model.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.quizPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Question $questionNumber of $totalQuestions',
              style: const TextStyle(
                color: AppColors.quizPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Question text (HTML)
          Html(
            data: question.text,
            style: {
              'p': Style(
                fontSize: FontSize(16),
                lineHeight: LineHeight(1.6),
                color: AppColors.grey800,
              ),
              'strong': Style(
                fontWeight: FontWeight.w700,
              ),
            },
          ),

          // Type indicator
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _typeLabel(question.type),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'MCQ':
        return 'Multiple Choice';
      case 'FILL_UP':
        return 'Fill in the Blank';
      case 'TRUE_FALSE':
        return 'True or False';
      case 'INTEGER':
        return 'Integer Type';
      default:
        return type;
    }
  }
}
