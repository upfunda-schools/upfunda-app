import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../../providers/challenge_bot_provider.dart';
import '../../../shared/widgets/loader_widget.dart';

String _stripBase64Images(String html) {
  return html.replaceAll(
    RegExp(r'<img[^>]+src="data:[^"]*base64[^"]*"[^>]*(/)?>',
        caseSensitive: false),
    '',
  );
}

class ChallengeBotScreen extends ConsumerStatefulWidget {
  const ChallengeBotScreen({super.key});

  @override
  ConsumerState<ChallengeBotScreen> createState() => _ChallengeBotScreenState();
}

class _ChallengeBotScreenState extends ConsumerState<ChallengeBotScreen> {
  String? _selectedOptionId;
  bool _answered = false;
  late Stopwatch _stopwatch;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    Future.microtask(
      () => ref.read(challengeBotProvider.notifier).startChallenge(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  void _onOptionTap(String optionId, String questionId) {
    if (_answered) return;
    setState(() {
      _selectedOptionId = optionId;
      _answered = true;
    });
    _stopwatch.stop();
    _ticker?.cancel();
    final elapsed = _stopwatch.elapsed.inSeconds;

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      ref
          .read(challengeBotProvider.notifier)
          .submitAnswer(questionId, optionId, elapsed);
      setState(() {
        _selectedOptionId = null;
        _answered = false;
      });
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeBotProvider);

    // Start timer when session first loads
    ref.listen<ChallengeBotState>(challengeBotProvider, (prev, next) {
      if (prev?.session == null && next.session != null) {
        _startTimer();
      }
      if (next.isFinished) {
        _ticker?.cancel();
        context.pushReplacement('/challenge/bot/result');
      }
    });

    if (state.isLoading) {
      return const Scaffold(
        body: LoaderWidget(message: 'Preparing challenge...'),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.incorrect),
                const SizedBox(height: 16),
                Text(state.error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref
                      .read(challengeBotProvider.notifier)
                      .startChallenge(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final session = state.session;
    if (session == null) return const Scaffold(body: SizedBox());

    final questions = session.questions;
    final index = state.currentIndex;
    if (index >= questions.length) {
      return const Scaffold(body: LoaderWidget(message: 'Loading results...'));
    }

    final question = questions[index];
    final progress = (index + 1) / questions.length;
    final elapsed = _stopwatch.elapsed.inSeconds;

    return Scaffold(
      backgroundColor: AppColors.quizBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(session, index, questions.length, elapsed),
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
                        value: progress,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.quizPrimary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Question
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

                    // Options
                    ...question.options.map((opt) =>
                        _OptionTile(
                          option: opt,
                          selected: _selectedOptionId == opt.optionId,
                          answered: _answered,
                          correctOptionId: question.correctOptionId,
                          onTap: () =>
                              _onOptionTap(opt.optionId, question.questionId),
                        )),

                    const SizedBox(height: 16),
                    _BotStatusChip(
                        botTimeSecs: question.botBehavior.timeTakenSeconds),
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
      BotChallengeSession session, int index, int total, int elapsed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _ticker?.cancel();
              ref.read(challengeBotProvider.notifier).reset();
              context.pop();
            },
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'vs ${session.opponent.name}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$index / $total answered',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
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

class _OptionTile extends StatelessWidget {
  final ChallengeOption option;
  final bool selected;
  final bool answered;
  final String correctOptionId;
  final VoidCallback onTap;

  const _OptionTile({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _BotStatusChip extends StatelessWidget {
  final int botTimeSecs;

  const _BotStatusChip({required this.botTimeSecs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy_rounded,
              size: 16, color: Colors.white54),
          const SizedBox(width: 6),
          Text(
            'Bot answers in ~${botTimeSecs}s',
            style:
                const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
