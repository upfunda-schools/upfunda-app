import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/challenge_bot_provider.dart';

class ChallengeBotResultScreen extends ConsumerWidget {
  const ChallengeBotResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeBotProvider);
    final session = state.session;

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No result available'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/challenge'),
                child: const Text('Back to Challenge'),
              ),
            ],
          ),
        ),
      );
    }

    final userScore = state.userScore;
    final botScore = state.botScore;
    final total = session.questions.length;
    final isWin = userScore > botScore;
    final isDraw = userScore == botScore;

    return Scaffold(
      backgroundColor: AppColors.quizBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Result banner
              _ResultBanner(isWin: isWin, isDraw: isDraw),
              const SizedBox(height: 32),

              // Player vs Bot cards
              Row(
                children: [
                  Expanded(
                    child: _ScoreCard(
                      name: 'You',
                      score: userScore,
                      total: total,
                      isWinner: isWin,
                      color: AppColors.quizPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScoreCard(
                      name: session.opponent.name,
                      score: botScore,
                      total: total,
                      isWinner: !isWin && !isDraw,
                      color: AppColors.accent,
                      isBot: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Per-question breakdown
              _QuestionBreakdown(state: state),
              const SizedBox(height: 32),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.quizPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    ref.read(challengeBotProvider.notifier).reset();
                    context.pushReplacement('/challenge/bot');
                  },
                  child: const Text('Play Again',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    ref.read(challengeBotProvider.notifier).reset();
                    context.go('/student-home');
                  },
                  child: const Text('Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool isWin;
  final bool isDraw;

  const _ResultBanner({required this.isWin, required this.isDraw});

  @override
  Widget build(BuildContext context) {
    final label = isDraw ? 'Draw!' : (isWin ? 'You Win!' : 'You Lose');
    final icon =
        isDraw ? Icons.handshake_rounded : (isWin ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded);
    final color = isDraw
        ? AppColors.review
        : (isWin ? AppColors.correct : AppColors.incorrect);

    return Column(
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String name;
  final int score;
  final int total;
  final bool isWinner;
  final Color color;
  final bool isBot;

  const _ScoreCard({
    required this.name,
    required this.score,
    required this.total,
    required this.isWinner,
    required this.color,
    this.isBot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isWinner ? color : Colors.white12, width: 1.5),
      ),
      child: Column(
        children: [
          if (isWinner)
            Icon(Icons.workspace_premium_rounded, color: color, size: 20),
          Icon(
            isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
            color: color,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            '$score / $total',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBreakdown extends StatelessWidget {
  final ChallengeBotState state;

  const _QuestionBreakdown({required this.state});

  @override
  Widget build(BuildContext context) {
    final questions = state.session?.questions ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Breakdown',
            style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questions.asMap().entries.map((e) {
              final q = e.value;
              final userAnswer = state.answers[q.questionId];
              final userCorrect = userAnswer == q.correctOptionId;
              final botCorrect = q.botBehavior.willAnswerCorrectly;
              return _QuestionDot(
                number: e.key + 1,
                userCorrect: userCorrect,
                botCorrect: botCorrect,
                answered: userAnswer != null,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(color: AppColors.correct, label: 'You correct'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.incorrect, label: 'You wrong'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionDot extends StatelessWidget {
  final int number;
  final bool userCorrect;
  final bool botCorrect;
  final bool answered;

  const _QuestionDot({
    required this.number,
    required this.userCorrect,
    required this.botCorrect,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    final color = !answered
        ? Colors.white24
        : (userCorrect ? AppColors.correct : AppColors.incorrect);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        '$number',
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
