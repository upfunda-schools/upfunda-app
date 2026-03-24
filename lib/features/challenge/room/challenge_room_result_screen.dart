import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/challenge_room_model.dart';
import '../../../providers/challenge_room_provider.dart';

class ChallengeRoomResultScreen extends ConsumerWidget {
  const ChallengeRoomResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeRoomProvider);
    final result = state.result;

    if (result == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Result not available yet'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(challengeRoomProvider.notifier).reset();
                  context.go('/challenge');
                },
                child: const Text('Back to Challenge'),
              ),
            ],
          ),
        ),
      );
    }

    final players = result.players;
    final winner = result.winner;
    final isDraw = winner == null && result.status == 'completed';

    return Scaffold(
      backgroundColor: AppColors.quizBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Result banner
              _ResultBanner(winner: winner, isDraw: isDraw),
              const SizedBox(height: 8),

              // Result reason
              if (result.resultReason.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatReason(result.resultReason),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 28),

              // Player cards
              if (players.length >= 2)
                Row(
                  children: [
                    Expanded(
                        child: _PlayerCard(
                            player: players[0], color: AppColors.quizPrimary)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _PlayerCard(
                            player: players[1], color: AppColors.accent)),
                  ],
                )
              else if (players.length == 1)
                _PlayerCard(
                    player: players[0], color: AppColors.quizPrimary),

              const SizedBox(height: 24),

              // Per-question results
              if (players.isNotEmpty) _QuestionResults(players: players),

              const SizedBox(height: 32),

              // Actions
              if (result.actions.rematchAllowed)
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
                      ref.read(challengeRoomProvider.notifier).reset();
                      context.pushReplacement('/challenge/room/lobby');
                    },
                    child: const Text('Rematch',
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
                    ref.read(challengeRoomProvider.notifier).reset();
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

  String _formatReason(String reason) {
    switch (reason) {
      case 'higher_score':
        return 'Won by Higher Score';
      case 'faster_time':
        return 'Won by Faster Time';
      case 'draw':
        return "It's a Draw!";
      case 'opponent_quit':
        return 'Opponent Quit';
      default:
        return reason;
    }
  }
}

class _ResultBanner extends StatelessWidget {
  final ChallengeRoomWinner? winner;
  final bool isDraw;

  const _ResultBanner({this.winner, required this.isDraw});

  @override
  Widget build(BuildContext context) {
    if (isDraw) {
      return Column(children: [
        const Icon(Icons.handshake_rounded,
            size: 56, color: AppColors.review),
        const SizedBox(height: 8),
        Text("It's a Draw!",
            style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.review)),
      ]);
    }
    if (winner != null) {
      return Column(children: [
        const Icon(Icons.emoji_events_rounded,
            size: 56, color: AppColors.correct),
        const SizedBox(height: 8),
        Text('${winner!.name} Wins!',
            style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.correct),
            textAlign: TextAlign.center),
      ]);
    }
    return const SizedBox();
  }
}

class _PlayerCard extends StatelessWidget {
  final ChallengeRoomPlayer player;
  final Color color;

  const _PlayerCard({required this.player, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: player.isWinner ? color : Colors.white12, width: 1.5),
      ),
      child: Column(
        children: [
          if (player.isWinner)
            Icon(Icons.workspace_premium_rounded, color: color, size: 18),
          if (player.hasQuit)
            const Icon(Icons.exit_to_app_rounded,
                color: AppColors.incorrect, size: 18),
          const SizedBox(height: 4),
          Icon(Icons.person_rounded, color: color, size: 32),
          const SizedBox(height: 6),
          Text(
            player.name,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${player.score}',
            style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                  icon: Icons.check_rounded,
                  value: '${player.correct}',
                  color: AppColors.correct),
              const SizedBox(width: 6),
              _StatChip(
                  icon: Icons.close_rounded,
                  value: '${player.wrong}',
                  color: AppColors.incorrect),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${player.totalTime.toStringAsFixed(1)}s',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatChip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _QuestionResults extends StatelessWidget {
  final List<ChallengeRoomPlayer> players;

  const _QuestionResults({required this.players});

  @override
  Widget build(BuildContext context) {
    final maxQ = players.fold<int>(
        0, (m, p) => p.questionResults.length > m ? p.questionResults.length : m);
    if (maxQ == 0) return const SizedBox();

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
            'Per-Question Results',
            style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 60),
              ...List.generate(
                  maxQ,
                  (i) => Expanded(
                        child: Text(
                          'Q${i + 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      )),
            ],
          ),
          const SizedBox(height: 8),
          ...players.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        p.name,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...List.generate(maxQ, (i) {
                      final res = i < p.questionResults.length
                          ? p.questionResults[i]
                          : null;
                      final color = res == null
                          ? Colors.white12
                          : (res ? AppColors.correct : AppColors.incorrect);
                      return Expanded(
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 1),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
