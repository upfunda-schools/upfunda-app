import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/quiz_provider.dart';
import 'submission_dialog.dart';

class TimeUpDialog extends ConsumerWidget {
  const TimeUpDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.timer_off, color: AppColors.incorrect),
          const SizedBox(width: 8),
          const Text("Time's Up!"),
        ],
      ),
      content: const Text(
        'Your time has run out. The quiz will be submitted automatically.',
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            final result = await ref.read(quizProvider.notifier).submitTest();
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => SubmissionDialog(result: result),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('View Results',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
