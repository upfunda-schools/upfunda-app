import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/quiz_provider.dart';
import '../../shared/widgets/loader_widget.dart';
import 'widgets/question_card.dart';
import 'widgets/option_tile.dart';
import 'widgets/fill_up_input.dart';
import 'widgets/quiz_timer.dart';
import 'widgets/navigation_buttons.dart';
import 'widgets/status_legend.dart';
import 'widgets/exit_dialog.dart';
import 'widgets/time_up_dialog.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String testId;
  const QuizScreen({super.key, required this.testId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _showedTimeUp = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(quizProvider.notifier).initializeQuiz(widget.testId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final isTablet = MediaQuery.of(context).size.width > 768;

    // Time up check
    if (quizState.remainingSeconds <= 0 &&
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
            const SizedBox(height: 8),

            // Status legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StatusLegend(
                answered: quizState.answeredCount,
                unanswered: quizState.unansweredCount,
                review: quizState.reviewCount,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ExitDialog(),
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
          // Timer
          QuizTimerWidget(
            timerDisplay: quizState.timerDisplay,
            remainingSeconds: quizState.remainingSeconds,
            totalSeconds: 600,
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
                  '50:50',
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
                  ? () => ref
                      .read(quizProvider.notifier)
                      .useFiftyFifty(quizState.currentQuestionId)
                  : null,
            ),
          // Exit button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ExitDialog(),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          QuestionCard(
            question: question,
            questionNumber: quizState.currentIndex + 1,
            totalQuestions: quizState.questions.length,
          ),
          const SizedBox(height: 16),
          _buildOptionsSection(quizState, question),
          const SizedBox(height: 8),
          const NavigationButtons(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(QuizState quizState, question) {
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
