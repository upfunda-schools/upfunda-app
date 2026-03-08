import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StatusLegend extends StatelessWidget {
  final int answered;
  final int unanswered;
  final int review;

  const StatusLegend({
    super.key,
    required this.answered,
    required this.unanswered,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LegendItem(
            color: AppColors.success,
            label: 'Answered',
            count: answered,
          ),
          _LegendItem(
            color: AppColors.grey400,
            label: 'Unanswered',
            count: unanswered,
          ),
          _LegendItem(
            color: AppColors.review,
            label: 'Review',
            count: review,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count $label',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
