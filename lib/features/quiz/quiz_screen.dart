import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/quiz_provider.dart' show quizProvider, QuizState, quizMuteProvider;
import '../../data/models/quiz_model.dart';
import '../../shared/widgets/loader_widget.dart';
import 'widgets/question_card.dart';
import 'widgets/option_tile.dart';
import 'widgets/fill_up_input.dart';
import 'widgets/navigation_buttons.dart';
import 'widgets/status_legend.dart';
import 'widgets/exit_dialog.dart';
import 'widgets/time_up_dialog.dart';
import 'package:google_fonts/google_fonts.dart';



class QuizScreen extends ConsumerStatefulWidget {
  final String testId;
  final String subjectId;
  const QuizScreen({super.key, required this.testId, this.subjectId = ''});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _showedTimeUp = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(quizProvider.notifier).initializeQuiz(widget.testId, subjectId: widget.subjectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final isTablet = MediaQuery.of(context).size.width > 768;

    // Time up check — only if the quiz is timed (server sent non-zero duration)
    if (quizState.isTimed &&
        quizState.remainingSeconds <= 0 &&
        quizState.questions.isNotEmpty &&
        !_showedTimeUp) {
      _showedTimeUp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const TimeUpDialog(),
          );
        }
      });
    }

    if (quizState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.quizBg,
        body: LoaderWidget(message: 'Loading quiz...'),
      );
    }

    if (quizState.error != null) {
      return Scaffold(
        backgroundColor: AppColors.quizBg,
        body: Center(
          child: Text(
            'Error: ${quizState.error}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentQ = quizState.currentQuestion;
    if (currentQ == null) {
      return const Scaffold(
        backgroundColor: AppColors.quizBg,
        body: Center(
          child: Text('No questions', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.quizBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(quizState),

            // Progress bar
            LinearProgressIndicator(
              value: (() {
                final total = quizState.pagination?.totalQuestions ?? quizState.questions.length;
                if (total == 0) return 0.0;
                return (quizState.answeredCount / total).clamp(0.0, 1.0);
              })(),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 4,
            ),
            const SizedBox(height: 12),

            // Topic Heading
            if (quizState.testName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  quizState.testName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cherryBombOne(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Status legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatusLegend(
                correct: quizState.correctCount,
                incorrect: quizState.incorrectCount,
              ),
            ),
            const SizedBox(height: 12),

            // Main content
            Expanded(
              child: isTablet
                  ? _buildTabletLayout(quizState, currentQ)
                  : _buildPhoneLayout(quizState, currentQ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(QuizState quizState) {
    final isMuted = ref.watch(quizMuteProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ExitDialog(subjectId: widget.subjectId),
              );
            },
          ),
          // Question counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${quizState.currentIndex + 1}/${quizState.questions.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const Spacer(),
          // Mute button
          IconButton(
            icon: Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white70,
            ),
            onPressed: () async {
              final newMute = !isMuted;
              ref.read(quizMuteProvider.notifier).state = newMute;
              
              if (!newMute) {
                // Play a sample sound when unmuting so the user knows it's working
                try {
                  // Using a fresh instance for every effect is the most robust way on Web
                  AudioPlayer().play(AssetSource('audio/correct_sound_effect.mp3'), volume: 0.4);
                } catch (e) {
                  debugPrint('Error playing unmute sound: $e');
                }
              }
            },
          ),
          const SizedBox(width: 8),

          // 50-50 button
          if (quizState.currentQuestion != null &&
              !quizState.currentQuestion!.isFillType)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: quizState.canUseFiftyFifty
                      ? AppColors.review.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mystic Eraser',
                  style: TextStyle(
                    color: quizState.canUseFiftyFifty
                        ? AppColors.review
                        : AppColors.grey400,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              onPressed: quizState.canUseFiftyFifty
                  ? () {
                      showDialog(
                        context: context,
                        builder: (context) => MysticEraserDialog(
                          remainingUses: quizState.fiftyFiftyLimit -
                              quizState.fiftyFiftyUsageCount,
                          onConfirm: () {
                            ref
                                .read(quizProvider.notifier)
                                .useFiftyFifty(quizState.currentQuestionId);
                          },
                        ),
                      );
                    }
                  : null,

            ),
          // Exit button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ExitDialog(subjectId: widget.subjectId),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(QuizState quizState, question) {
    return Row(
      children: [
        // Left - Question
        Expanded(
          flex: 65,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
            child: SingleChildScrollView(
              child: QuestionCard(
                question: question,
                questionNumber: quizState.currentIndex + 1,
                totalQuestions: quizState.questions.length,
              ),
            ),
          ),
        ),
        // Right - Options + Navigation
        Expanded(
          flex: 35,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildOptionsSection(quizState, question),
                  ),
                ),
                const NavigationButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(QuizState quizState, question) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                QuestionCard(
                  question: question,
                  questionNumber: quizState.currentIndex + 1,
                  totalQuestions: quizState.questions.length,
                ),
                const SizedBox(height: 16),
                _buildOptionsSection(quizState, question),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: NavigationButtons(),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(QuizState quizState, question) {
    if (quizState.checkDetails) {
      final currentAnswer = quizState.answers[quizState.currentQuestionId];
      
      String yourAnswerText = '';
      String correctAnswerText = '';

      if (question.isFillType) {
        yourAnswerText = currentAnswer?.selectedOption ?? 'No answer';
        correctAnswerText = question.solution?.answer ?? '';
      } else {
        QuestionOption? selectedOpt;
        for (var o in question.options) {
          if (o.optionId == currentAnswer?.selectedOption) {
            selectedOpt = o;
            break;
          }
        }
        yourAnswerText = selectedOpt?.text ?? 'No answer';
        
        QuestionOption? correctOpt;
        for (var o in question.options) {
          if (o.optionId == question.solution?.correctOptionId) {
            correctOpt = o;
            break;
          }
        }
        correctAnswerText = correctOpt?.text ?? '';
      }

      return SolutionPanel(
        isCorrect: currentAnswer?.isCorrect ?? false,
        yourAnswer: yourAnswerText,
        correctAnswer: correctAnswerText,
        explanation: question.solution?.explanation ?? '',
        questionId: quizState.currentQuestionId,
      );
    }

    final currentAnswer = quizState.answers[quizState.currentQuestionId];
    final hiddenOpts =
        quizState.hiddenOptions[quizState.currentQuestionId] ?? [];

    if (question.isFillType) {
      return FillUpInput(
        currentValue: currentAnswer?.selectedOption,
        showResult: quizState.checkDetails,
        isCorrect: currentAnswer?.isCorrect ?? false,
        correctAnswer: question.solution?.answer,
        isIntegerType: question.type == 'INTEGER',
        onChanged: (value) {
          ref
              .read(quizProvider.notifier)
              .answerQuestion(quizState.currentQuestionId, value);
        },
      );
    }

    return Column(
      children: List.generate(question.options.length, (i) {
        final opt = question.options[i];
        final isHidden = hiddenOpts.contains(opt.optionId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OptionTile(
            optionId: opt.optionId,
            text: opt.text,
            index: i,
            isSelected: currentAnswer?.selectedOption == opt.optionId,
            isCorrect: currentAnswer?.isCorrect ?? false,
            showResult: quizState.checkDetails,
            isHidden: isHidden,
            correctOptionId: question.solution?.correctOptionId,
            onTap: quizState.checkDetails
                ? null
                : () {
                    ref
                        .read(quizProvider.notifier)
                        .answerQuestion(quizState.currentQuestionId, opt.optionId);
                  },
          ),
        );
      }),
    );
  }
}

class MysticEraserDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final int remainingUses;

  const MysticEraserDialog({
    super.key,
    required this.onConfirm,
    this.remainingUses = 2,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.92).clamp(300.0, 400.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main White Box
          Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_outlined,
                      color: Color(0xFFA358FF),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use Mystic Eraser?',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Warning Box (Points...)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD97706),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Point Reduction Warning',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: const Color(0xFFB45309),
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                      text:
                                          'Using this clue will reduce your points for this question from '),
                                  TextSpan(
                                    text: '+10 UP',
                                    style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const TextSpan(text: ' to '),
                                  TextSpan(
                                    text: '+5 UP.',
                                    style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bullet list (What it does)
                Text(
                  'What the Mystic Eraser does:',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('Eliminates 2 wrong answer options'),
                _buildBulletPoint(
                    'Leaves you with 2 choices (including the correct answer)'),
                _buildBulletPoint('Can only be used once per question'),
                _buildBulletPoint('Limited to 20% of quiz questions'),

                const SizedBox(height: 18),
                Text(
                  'You have $remainingUses choices remaining in this quiz.',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Are you sure you want to use the Mystic Eraser?',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 28),

                // Actions: Cancel / Yes
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: Text(
                          'Cancel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA358FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          'Yes, Use Eraser',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Corner close button
          Positioned(
            right: -8,
            top: -8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B98),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SolutionPanel extends StatelessWidget {
  final bool isCorrect;
  final String yourAnswer;
  final String correctAnswer;
  final String explanation;
  final String? questionId;

  static const List<String> quotes = [
    "Great job! You got it right! 🌟",
    "Awesome work! You're so smart! ⭐",
    "Perfect! You're doing amazing! 🎉",
    "Excellent! Keep up the good work! 👏",
    "Wonderful! You're a star! ✨",
    "Fantastic! You nailed it! 🚀",
    "Super! You're brilliant! 💫",
    "Amazing! You're getting better! 🎯",
    "Outstanding! Well done! 🏆",
    "Incredible! You rock! 🌈",
    "Brilliant! You're awesome! 💎",
    "Terrific! You're learning fast! 🌸",
    "Marvelous! Keep going! 🦄",
    "Splendid! You're a champion! 🎪",
    "Fabulous! You're unstoppable! 🎨"
  ];

  const SolutionPanel({
    super.key,
    required this.isCorrect,
    required this.yourAnswer,
    required this.correctAnswer,
    required this.explanation,
    this.questionId,
  });

  String _stripHtml(String html) {
    if (html.isEmpty) return '';
    // Replace layout tags with newlines to preserve basic structure
    String text = html
        .replaceAll(RegExp(r'</p>|</div>|<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n+'), '\n')
        .trim();
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final cleanYourAnswer = _stripHtml(yourAnswer);
    final cleanCorrectAnswer = _stripHtml(correctAnswer);
    final cleanExplanation = _stripHtml(explanation);

    // Random quote for correct answer
    String? quote;
    if (isCorrect) {
      final seed = questionId?.hashCode ?? Random().nextInt(1000);
      quote = quotes[Random(seed).nextInt(quotes.length)];
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Answer and Solution',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700, // BOLD
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          // Notice Box
          isCorrect
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7), // Light green
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF22C55E), width: 4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          quote ?? "Great job! You got it right! 🌟",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700, // BOLD
                            color: const Color(0xFF166534), // Dark green
                          ),
                        ),
                      ),
                      const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFFBBF7D0), size: 24),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Icon(Icons.celebration, color: Color(0xFF4ADE80), size: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3), // Light yellow
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEF08A), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.rocket_launch, color: Color(0xFFEAB308), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "You're learning! Check the details below!",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700, // BOLD
                            color: const Color(0xFF854D0E),
                          ),
                        ),
                      ),
                      const Icon(Icons.auto_awesome, color: Color(0xFFFEF08A), size: 16),
                    ],
                  ),
                ),
          const SizedBox(height: 20),

          // Answer details
          _buildInfoRow('Your answer:', cleanYourAnswer, isCorrect ? AppColors.success : AppColors.incorrect),
          const SizedBox(height: 8),
          _buildInfoRow('Correct answer:', cleanCorrectAnswer, AppColors.success),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE5E7EB)),
          ),

          // Explanation
          if (cleanExplanation.isNotEmpty) ...[
            Text(
              'Explanation:',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w700, // BOLD
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cleanExplanation,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600, // SEMI-BOLD
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700, // BOLD
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700, // BOLD
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

