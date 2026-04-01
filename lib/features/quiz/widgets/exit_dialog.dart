import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/quiz_provider.dart';

class ExitDialog extends ConsumerWidget {
  final String subjectId;
  const ExitDialog({super.key, this.subjectId = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Exit Quiz?'),
      content: const Text(
        'Are you sure you want to exit? Your progress will be saved.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            await ref.read(quizProvider.notifier).pauseQuiz();
            router.go(subjectId.isNotEmpty ? '/worksheets-list/$subjectId' : '/worksheets');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.incorrect,
          ),
          child: const Text('Exit', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
