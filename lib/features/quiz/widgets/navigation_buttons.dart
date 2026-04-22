import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/quiz_provider.dart';
import 'submission_dialog.dart';

class NavigationButtons extends ConsumerStatefulWidget {
  const NavigationButtons({super.key});

  @override
  ConsumerState<NavigationButtons> createState() => _NavigationButtonsState();
}

class _NavigationButtonsState extends ConsumerState<NavigationButtons> {
  // Use a static player or a more persistent one to avoid "sometimes" issues on Web
  static final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (_isPlayerInitialized) return;
    try {
      // Pre-set some properties for better web compatibility
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      _isPlayerInitialized = true;
    } catch (e) {
      debugPrint('Audio initialization error: $e');
    }
  }

  Future<void> _playSound(bool isCorrect) async {
    final soundFile = isCorrect ? 'correct_sound_effect.mp3' : 'wrong_sound_effect.mp3';
    try {
      debugPrint('Playing sound: $soundFile');
      // On Web, sometimes play() needs a fresh source or explicit stop
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/$soundFile'), volume: 1.0);
    } catch (e) {
      debugPrint('Error playing sound ($soundFile): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final isMuted = ref.watch(quizMuteProvider);
    final currentAnswer = quizState.answers[quizState.currentQuestionId];
    final hasAnswer = currentAnswer?.selectedOption != null;
    final isChecked = quizState.checkDetails;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Check / Next / Submit button
          if (!isChecked) ...[
            Expanded(
              child: _build3DButton(
                text: 'Check',
                color: const Color(0xFF398DEF),
                shadowColor: const Color(0xFF1E70BF),
                onPressed: hasAnswer
                    ? () {
                        final isCorrect = ref
                            .read(quizProvider.notifier)
                            .checkAnswer(quizState.currentQuestionId);
                        
                        if (!isMuted) {
                          _playSound(isCorrect);
                        }
          
                        ref
                            .read(quizProvider.notifier)
                            .submitAnswer(quizState.currentQuestionId);
                      }
                    : null,
              ),
            ),
          ] else if (!quizState.isLastQuestion) ...[
            Expanded(
              child: _build3DButton(
                text: 'Next',
                icon: Icons.arrow_forward,
                color: const Color(0xFF398DEF),
                shadowColor: const Color(0xFF1E70BF),
                onPressed: () => ref.read(quizProvider.notifier).goToNext(),
              ),
            ),
          ] else ...[
            Expanded(
              child: _build3DButton(
                text: 'Submit Quiz',
                color: const Color(0xFF10B981), // Green for submit
                shadowColor: const Color(0xFF047857),
                onPressed: () async {
                  final result = await ref.read(quizProvider.notifier).submitTest();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => SubmissionDialog(result: result),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _build3DButton({
    required String text,
    required Color color,
    required Color shadowColor,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    final bool isEnabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isEnabled ? shadowColor : const Color(0xFF1E70BF).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isEnabled ? color : const Color(0xFF398DEF).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: GoogleFonts.montserrat(
                    color: isEnabled ? Colors.white : Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 12),
                  Icon(icon, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
