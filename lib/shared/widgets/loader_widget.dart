import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoaderWidget extends StatelessWidget {
  final String? message;

  const LoaderWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.grey600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
