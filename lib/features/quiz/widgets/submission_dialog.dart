import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/submit_model.dart';
import '../../../providers/quiz_provider.dart';

class SubmissionDialog extends ConsumerWidget {
  final SubmitTestResponse result;

  const SubmissionDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incorrect = result.totalCount - result.correctCount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Quiz Complete!',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Pie chart
              SizedBox(
                height: 160,
                width: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 45,
                        sections: [
                          PieChartSectionData(
                            color: AppColors.correct,
                            value: result.correctCount.toDouble(),
                            title: '',
                            radius: 28,
                          ),
                          PieChartSectionData(
                            color: AppColors.incorrect,
                            value: incorrect.toDouble(),
                            title: '',
                            radius: 28,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${result.totalCount > 0 ? (result.correctCount * 100 ~/ result.totalCount) : 0}%',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Score summary
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ScoreBadge(
                    color: AppColors.correct,
                    label: 'Correct',
                    count: result.correctCount,
                  ),
                  const SizedBox(width: 24),
                  _ScoreBadge(
                    color: AppColors.incorrect,
                    label: 'Incorrect',
                    count: incorrect,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${result.correctCount}/${result.totalCount}',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: 24),

              // Leaderboard
              if (result.leaderboard.isNotEmpty) ...[
                Text(
                  'Leaderboard',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...result.leaderboard.take(3).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: entry.rank == 1
                                ? const Color(0xFFFFF8E1)
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(12),
                            border: entry.rank == 1
                                ? Border.all(
                                    color: const Color(0xFFE4B500),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              _RankBadge(rank: entry.rank),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.score.round()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
              ],

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final subjectId = ref.read(quizProvider).subjectId;
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.go(subjectId.isNotEmpty
                        ? '/worksheets-list/$subjectId'
                        : '/worksheets');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to Worksheets',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _ScoreBadge({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = {
      1: const Color(0xFFE4B500),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: colors[rank] ?? AppColors.grey400,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
