import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/challenge_room_model.dart';
import '../../../providers/challenge_room_provider.dart';

String _stripBase64Images(String html) {
  return html.replaceAll(
    RegExp(r'<img[^>]+src="data:[^"]*base64[^"]*"[^>]*(/)?>',
        caseSensitive: false),
    '',
  );
}

class ChallengeRoomQuizScreen extends ConsumerStatefulWidget {
  const ChallengeRoomQuizScreen({super.key});

  @override
  ConsumerState<ChallengeRoomQuizScreen> createState() =>
      _ChallengeRoomQuizScreenState();
}

class _ChallengeRoomQuizScreenState
    extends ConsumerState<ChallengeRoomQuizScreen> {
  String? _selectedOptionId;
  bool _answered = false;
  late Stopwatch _stopwatch;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onOptionTap(RoomChallengeQuestion question, String optionId) {
    if (_answered) return;
    setState(() {
      _selectedOptionId = optionId;
      _answered = true;
    });
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsed.inSeconds;

    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      await ref.read(challengeRoomProvider.notifier).submitAnswer(
            question.questionId,
            optionId,
            elapsed,
          );
      if (mounted) {
        setState(() {
          _selectedOptionId = null;
          _answered = false;
        });
        _stopwatch.reset();
        _stopwatch.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeRoomProvider);

    ref.listen<ChallengeRoomState>(challengeRoomProvider, (prev, next) {
      if (next.status == 'completed' ||
          (next.isQuizFinished && next.result?.status == 'completed')) {
        _ticker?.cancel();
        context.pushReplacement('/challenge/room/result');
      }
    });

    final questions = state.questions;
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final index = state.currentIndex;
    if (index >= questions.length) {
      return Scaffold(
        backgroundColor: AppColors.quizBg,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Waiting for opponent...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final question = questions[index];
    final elapsed = _stopwatch.elapsed.inSeconds;

    return Scaffold(
      backgroundColor: AppColors.quizBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state, index, questions.length, elapsed),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (index + 1) / questions.length,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.quizPrimary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Q${question.questionNumber}.',
                      style: const TextStyle(
                          color: AppColors.quizPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Html(
                      data: _stripBase64Images(question.questionText),
                      style: {
                        'body': Style(
                          color: Colors.white,
                          fontSize: FontSize(18),
                          fontWeight: FontWeight.w600,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        'p': Style(
                          color: Colors.white,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                        '*': Style(color: Colors.white),
                      },
                    ),
                    const SizedBox(height: 24),

                    ...question.options
                        .map((opt) => _RoomOptionTile(
                              option: opt,
                              selected:
                                  _selectedOptionId == opt.optionId,
                              answered: _answered,
                              correctOptionId: question.correctOptionId,
                              onTap: () =>
                                  _onOptionTap(question, opt.optionId),
                            )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      ChallengeRoomState state, int index, int total, int elapsed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Quit Challenge?'),
                  content: const Text(
                      'Your opponent will win if you quit now.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Quit',
                            style:
                                TextStyle(color: AppColors.incorrect))),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                _ticker?.cancel();
                await ref
                    .read(challengeRoomProvider.notifier)
                    .quit();
                if (mounted) context.go('/challenge');
              }
            },
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Challenge Room',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  'You: ${state.myAnsweredCount}/$total  •  Opp: ${state.opponentAnsweredCount}/$total',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${elapsed}s',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomOptionTile extends StatelessWidget {
  final ChallengeOption option;
  final bool selected;
  final bool answered;
  final String correctOptionId;
  final VoidCallback onTap;

  const _RoomOptionTile({
    required this.option,
    required this.selected,
    required this.answered,
    required this.correctOptionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.white24;
    Color bgColor = Colors.white.withValues(alpha: 0.06);

    if (selected) {
      final isCorrect = option.optionId == correctOptionId;
      borderColor = isCorrect ? AppColors.correct : AppColors.incorrect;
      bgColor = isCorrect
          ? AppColors.correct.withValues(alpha: 0.15)
          : AppColors.incorrect.withValues(alpha: 0.15);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                option.optionLabel,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Html(
                data: option.optionText,
                style: {
                  'body': Style(
                    color: Colors.white,
                    fontSize: FontSize(15),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  'p': Style(
                    color: Colors.white,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  '*': Style(color: Colors.white),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
