import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/quiz_provider.dart';
import '../../../shared/widgets/app_button.dart';
import 'package:audioplayers/audioplayers.dart';
import 'submission_dialog.dart';

class NavigationButtons extends ConsumerStatefulWidget {
  const NavigationButtons({super.key});

  @override
  ConsumerState<NavigationButtons> createState() => _NavigationButtonsState();
}

class _NavigationButtonsState extends ConsumerState<NavigationButtons> {
  bool _isSubmitting = false;
  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
    final quizState = ref.watch(quizProvider);
    final currentAnswer = quizState.answers[quizState.currentQuestionId];
    final hasAnswer = currentAnswer?.selectedOption != null;
    final isChecked = quizState.checkDetails;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Check / Next button
          if (!isChecked) ...[
            Expanded(
              child: AppButton(
                label: 'Check',
                onPressed: hasAnswer
                    ? () {
                        final isCorrect = ref
                            .read(quizProvider.notifier)
                            .checkAnswer(quizState.currentQuestionId);
                        
                        _playSound(isCorrect);

                        ref
                            .read(quizProvider.notifier)
                            .submitAnswer(quizState.currentQuestionId);
                      }
                    : null,
                backgroundColor:
                    hasAnswer ? AppColors.quizPrimary : AppColors.grey400,
              ),
            ),
          ] else if (!quizState.isLastQuestion) ...[
            Expanded(
              child: AppButton(
                label: 'Next',
                icon: Icons.arrow_forward,
                onPressed: () => ref.read(quizProvider.notifier).goToNext(),
                backgroundColor: AppColors.quizPrimary,
              ),
            ),
          ] else if (quizState.pagination?.hasNext == true) ...[
            Expanded(
              child: AppButton(
                label: 'Next',
                icon: Icons.arrow_forward,
                onPressed: () =>
                    ref.read(quizProvider.notifier).loadNextPage(),
                backgroundColor: AppColors.quizPrimary,
              ),
            ),
          ] else ...[
            Expanded(
              child: AppButton(
                label: 'Submit',
                icon: Icons.check_circle_outline,
                isLoading: _isSubmitting,
                onPressed: () => _handleSubmit(context),
                backgroundColor: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(quizProvider.notifier).submitTest();
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SubmissionDialog(result: result),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
