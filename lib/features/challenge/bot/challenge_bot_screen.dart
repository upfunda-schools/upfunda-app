import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../../providers/challenge_bot_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loader_widget.dart';


class ChallengeBotScreen extends ConsumerStatefulWidget {
  const ChallengeBotScreen({super.key});

  @override
  ConsumerState<ChallengeBotScreen> createState() => _ChallengeBotScreenState();
}

class _ChallengeBotScreenState extends ConsumerState<ChallengeBotScreen> {
  String? _selectedOptionId;
  bool _checked = false;
  int _elapsed = 0;
  late Stopwatch _stopwatch;

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
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  void _onOptionTap(String optionId) {
    if (_checked) return;
    setState(() {
      _selectedOptionId = optionId;
    });
  }

  void _onCheck(String correctOptionId) {
    _stopwatch.stop();
    _elapsed = _stopwatch.elapsed.inSeconds;
    final isCorrect = _selectedOptionId == correctOptionId;
    _playSound(isCorrect);
    setState(() => _checked = true);
  }

  void _onNext(String questionId) {
    ref
        .read(challengeBotProvider.notifier)
        .submitAnswer(questionId, _selectedOptionId!, _elapsed);
    setState(() {
      _selectedOptionId = null;
      _checked = false;
    });
    _startTimer();
  }

  void _onSubmit(String questionId) {
    ref
        .read(challengeBotProvider.notifier)
        .submitAnswer(questionId, _selectedOptionId!, _elapsed);
  }

  Future<void> _playSound(bool isCorrect) async {
    try {
      final source = isCorrect
          ? AssetSource('audio/correct_sound_effect.mp3')
          : AssetSource('audio/wrong_sound_effect.mp3');
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
      await player.play(source);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
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
    final isLastQuestion = index == questions.length - 1;

    return Scaffold(
      backgroundColor: AppColors.quizBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(session, index, questions.length),
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
                      data: question.questionText,
                      extensions: [
                        TagExtension(
                          tagsToExtend: {"img"},
                          builder: (extensionContext) {
                            final src = extensionContext.attributes["src"] ?? "";
                            if (src.isEmpty) return const SizedBox.shrink();
                            if (src.startsWith('data:')) {
                              try {
                                final bytes = base64Decode(src.split(',').last);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Image.memory(bytes, fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                );
                              } catch (_) {
                                return const SizedBox.shrink();
                              }
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Image.network(
                                src,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            );
                          },
                        ),
                      ],
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
                          checked: _checked,
                          correctOptionId: question.correctOptionId,
                          onTap: () => _onOptionTap(opt.optionId),
                        )),

                    const SizedBox(height: 16),
                    _BotStatusChip(
                        botTimeSecs: question.botBehavior.timeTakenSeconds),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(question, isLastQuestion),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BotQuestion question, bool isLastQuestion) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (!_checked)
            Expanded(
              child: AppButton(
                label: 'Check',
                onPressed: _selectedOptionId != null
                    ? () => _onCheck(question.correctOptionId)
                    : null,
                backgroundColor: _selectedOptionId != null
                    ? AppColors.quizPrimary
                    : AppColors.grey400,
              ),
            )
          else if (!isLastQuestion)
            Expanded(
              child: AppButton(
                label: 'Next',
                icon: Icons.arrow_forward,
                onPressed: () => _onNext(question.questionId),
                backgroundColor: AppColors.quizPrimary,
              ),
            )
          else
            Expanded(
              child: AppButton(
                label: 'Submit',
                icon: Icons.check_circle_outline,
                onPressed: () => _onSubmit(question.questionId),
                backgroundColor: AppColors.success,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BotChallengeSession session, int index, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
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
          _ChallengeTimer(stopwatch: _stopwatch),
        ],
      ),
    );
  }
}

class _ChallengeTimer extends StatefulWidget {
  final Stopwatch stopwatch;
  const _ChallengeTimer({required this.stopwatch});

  @override
  State<_ChallengeTimer> createState() => _ChallengeTimerState();
}

class _ChallengeTimerState extends State<_ChallengeTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.stopwatch.isRunning) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${widget.stopwatch.elapsed.inSeconds}s',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final ChallengeOption option;
  final bool selected;
  final bool checked;
  final String correctOptionId;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.selected,
    required this.checked,
    required this.correctOptionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.white24;
    Color bgColor = Colors.white.withValues(alpha: 0.06);
    Widget? trailingIcon;

    if (!checked) {
      if (selected) {
        borderColor = Colors.white54;
        bgColor = Colors.white.withValues(alpha: 0.15);
      }
    } else {
      final isThisCorrect = option.optionId == correctOptionId;
      if (isThisCorrect) {
        borderColor = AppColors.correct;
        bgColor = AppColors.correct.withValues(alpha: 0.15);
        trailingIcon = const Icon(Icons.check_circle, color: AppColors.correct, size: 22);
      } else if (selected) {
        borderColor = AppColors.incorrect;
        bgColor = AppColors.incorrect.withValues(alpha: 0.15);
        trailingIcon = const Icon(Icons.cancel, color: AppColors.incorrect, size: 22);
      }
    }

    return GestureDetector(
      onTap: checked ? null : onTap,
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
                extensions: [
                  TagExtension(
                    tagsToExtend: {"img"},
                    builder: (extensionContext) {
                      final src = extensionContext.attributes["src"] ?? "";
                      if (src.isEmpty) return const SizedBox.shrink();
                      if (src.startsWith('data:')) {
                        try {
                          final bytes = base64Decode(src.split(',').last);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Image.memory(bytes, fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                          );
                        } catch (_) {
                          return const SizedBox.shrink();
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Image.network(
                          src,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                ],
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
            if (trailingIcon != null) trailingIcon,
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
