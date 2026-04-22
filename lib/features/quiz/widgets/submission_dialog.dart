import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/quiz_provider.dart';
import '../../../data/models/submit_model.dart';

class SubmissionDialog extends ConsumerWidget {
  final SubmitTestResponse result;

  const SubmissionDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incorrect = result.totalCount - result.correctCount;
    final scorePercentage = result.totalCount > 0 
        ? (result.correctCount * 100 ~/ result.totalCount) 
        : 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main Dialog Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF2D327C), // Deep purple from reference
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40), // Space for rocket overlap
                
                // Title
                Image.asset(
                  'assets/images/quiz/Quiz Completed.png',
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'Quiz Completed',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFB396FF),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Score Card Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Score',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF6CF9F9),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress Ring
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: 45,
                                startDegreeOffset: 270,
                                sections: [
                                  PieChartSectionData(
                                    color: const Color(0xFF10B981), // Green/Cyan
                                    value: result.correctCount.toDouble(),
                                    title: '',
                                    radius: 10,
                                  ),
                                  PieChartSectionData(
                                    color: const Color(0xFF314DB0), // Darker Blue
                                    value: incorrect.toDouble(),
                                    title: '',
                                    radius: 10,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${result.correctCount}/${result.totalCount}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '$scorePercentage%',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Motivation Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '✨ Keep practicing to improve your score! ✨',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Continue Button (3D Sprite)
                GestureDetector(
                  onTap: () {
                    final subjectId = ref.read(quizProvider).subjectId;
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.go(subjectId.isNotEmpty
                        ? '/worksheets-list/$subjectId'
                        : '/worksheets');
                  },
                  child: Image.asset(
                    'assets/images/quiz/Group 91.png',
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF047857),
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Continue to worksheets',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Rocket
          Positioned(
            top: -60,
            child: Image.asset(
              'assets/images/quiz/streamline-emojis_rocket.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

