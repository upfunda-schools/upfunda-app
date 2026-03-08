import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ExitDialog extends StatelessWidget {
  const ExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/worksheets');
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
