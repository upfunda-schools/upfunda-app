import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/challenge_room_model.dart';
import '../../../providers/challenge_room_provider.dart';
import '../../../shared/widgets/app_button.dart';


class ChallengeRoomQuizScreen extends ConsumerStatefulWidget {
  const ChallengeRoomQuizScreen({super.key});

  @override
  ConsumerState<ChallengeRoomQuizScreen> createState() =>
      _ChallengeRoomQuizScreenState();
}

class _ChallengeRoomQuizScreenState
    extends ConsumerState<ChallengeRoomQuizScreen> {
  String? _selectedOptionId;
  bool _checked = false;
  int _elapsed = 0;
  late Stopwatch _stopwatch;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
    ref.read(challengeRoomProvider.notifier).submitAnswer(
          questionId,
          _selectedOptionId!,
          _elapsed,
        );
    setState(() {
      _selectedOptionId = null;
      _checked = false;
    });
    _stopwatch.reset();
    _stopwatch.start();
  }

  void _onSubmit(String questionId) {
    ref.read(challengeRoomProvider.notifier).submitAnswer(
          questionId,
          _selectedOptionId!,
          _elapsed,
        );
  }

  Future<void> _playSound(bool isCorrect) async {
    try {
      final source = isCorrect
          ? AssetSource('audio/correct_sound_effect.mp3')
          : AssetSource('audio/wrong_sound_effect.mp3');
      await _audioPlayer.stop();
      await _audioPlayer.play(source);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeRoomProvider);

    ref.listen<ChallengeRoomState>(challengeRoomProvider, (prev, next) {
      if (next.status == 'completed' ||
          (next.isQuizFinished && next.result?.status == 'completed')) {
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
    final isLastQuestion = index == questions.length - 1;

    return Scaffold(
      backgroundColor: AppColors.quizBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state, index, questions.length),
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

                    ...question.options
                        .map((opt) => _RoomOptionTile(
                              option: opt,
                              selected: _selectedOptionId == opt.optionId,
                              checked: _checked,
                              correctOptionId: question.correctOptionId,
                              onTap: () => _onOptionTap(opt.optionId),
                            )),
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

  Widget _buildNavigationButtons(RoomChallengeQuestion question, bool isLastQuestion) {
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
      ChallengeRoomState state, int index, int total) {
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

class _RoomOptionTile extends StatelessWidget {
  final ChallengeOption option;
  final bool selected;
  final bool checked;
  final String correctOptionId;
  final VoidCallback onTap;

  const _RoomOptionTile({
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
