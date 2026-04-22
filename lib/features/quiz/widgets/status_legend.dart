import 'package:flutter/material.dart';

class StatusLegend extends StatelessWidget {
  final int correct;
  final int incorrect;

  const StatusLegend({
    super.key,
    required this.correct,
    required this.incorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF43329D).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(
            asset: 'assets/images/quiz/mdi_tick-circle.png',
            label: 'Correct',
            count: correct,
          ),
          const SizedBox(width: 24),
          Container(
            height: 24,
            width: 1.5,
            color: Colors.white24,
          ),
          const SizedBox(width: 24),
          _LegendItem(
            asset: 'assets/images/quiz/icon-park-solid_close-one.png',
            label: 'Incorrect',
            count: incorrect,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String asset;
  final String label;
  final int count;

  const _LegendItem({
    required this.asset,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(asset, height: 24),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
