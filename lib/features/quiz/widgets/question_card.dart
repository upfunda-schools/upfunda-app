import 'dart:convert';
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
            extensions: [
              TagExtension(
                tagsToExtend: {"img"},
                builder: (extensionContext) {
                  final src = extensionContext.attributes["src"] ?? "";
                  if (src.isEmpty) return const SizedBox.shrink();
                  if (src.startsWith('data:')) {
                    try {
                      final base64Str = src.split(',').last;
                      final bytes = base64Decode(base64Str);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.network(
                      src,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ],
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


        ],
      ),
    );
  }


}
