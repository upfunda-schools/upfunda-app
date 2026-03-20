import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoublesAdditionScreen extends StatefulWidget {
  const DoublesAdditionScreen({super.key});

  @override
  State<DoublesAdditionScreen> createState() => _DoublesAdditionScreenState();
}

class _DoublesAdditionScreenState extends State<DoublesAdditionScreen>
    with TickerProviderStateMixin {
  // ── State ───────────────────────────────────────────────────────────────────
  int _currentNum = 1;
  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _isSoundEnabled = true;

  // Animation keys for AnimatedSwitcher pulse
  int _scoreKey = 0;
  int _streakKey = 0;

  final TextEditingController _answerController = TextEditingController();
  final Random _random = Random();

  // Question card animation
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  // ── Messages ─────────────────────────────────────────────────────────────────
  static const _correctMsgs = [
    "Amazing work! 🌟",
    "You're on fire! 🔥",
    "Brilliant! Keep it up! 💪",
    "Fantastic! You're a math star! ⭐",
    "Perfect! You're unstoppable! 🚀",
    "Excellent! You've got this! 🎯",
    "Super! Keep going! 🎉",
    "Outstanding! 🏆",
  ];

  static const _incorrectMsgs = [
    "Good try! You'll get it! 💪",
    "Almost! Try the next one! 🌟",
    "Keep going, you're learning! 📚",
    "Don't give up! You've got this! 🎯",
    "Nice effort! Math takes practice! ✨",
    "So close! Keep trying! 🔥",
    "Great attempt! Try again! 💡",
    "You're improving! Keep it up! 🌈",
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _questionAnim = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
      value: 1.0,
    );
    _questionFade = CurvedAnimation(
      parent: _questionAnim,
      curve: Curves.easeInOut,
    );
    _questionSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _questionAnim, curve: Curves.easeOut));

    _generateQuestion(initial: true);
  }

  @override
  void dispose() {
    _questionAnim.dispose();
    _answerController.dispose();
    super.dispose();
  }

  // ── Game logic ───────────────────────────────────────────────────────────────
  void _generateQuestion({bool initial = false}) {
    if (!initial) {
      // Fade/slide out, then update
      _questionAnim.reverse().then((_) {
        _setNewQuestion();
        _questionAnim.forward();
      });
    } else {
      _setNewQuestion();
    }
  }

  void _setNewQuestion() {
    setState(() {
      _currentNum = _random.nextInt(12) + 1;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });
    _answerController.clear();
  }

  void _checkAnswer() {
    final parsed = int.tryParse(_answerController.text.trim());
    if (parsed == null) {
      _shakeField();
      return;
    }

    final correct = parsed == _currentNum * 2;
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      _totalQuestions++;
      if (correct) {
        _score++;
        _streak++;
        _scoreKey++;
        _streakKey++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        _feedbackMessage = _correctMsgs[_random.nextInt(_correctMsgs.length)];
      } else {
        _streak = 0;
        _streakKey++;
        _feedbackMessage =
            _incorrectMsgs[_random.nextInt(_incorrectMsgs.length)];
      }
    });

    if (_isSoundEnabled) _playHaptic(correct);
  }

  void _playHaptic(bool correct) {
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _shakeField() {
    HapticFeedback.vibrate();
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress =
        _totalQuestions == 0 ? 0.0 : (_score / _totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  isSoundEnabled: _isSoundEnabled,
                  onSoundToggle: () =>
                      setState(() => _isSoundEnabled = !_isSoundEnabled),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ScoreRow(
                          score: _score,
                          total: _totalQuestions,
                          streak: _streak,
                          bestStreak: _bestStreak,
                          scoreKey: _scoreKey,
                          streakKey: _streakKey,
                        ),
                        const SizedBox(height: 24),
                        SlideTransition(
                          position: _questionSlide,
                          child: FadeTransition(
                            opacity: _questionFade,
                            child: _QuestionCard(
                              num: _currentNum,
                              isAnswered: _isAnswered,
                              isCorrect: _isCorrect,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _AnswerInput(
                          controller: _answerController,
                          enabled: !_isAnswered,
                          onSubmit: _isAnswered ? null : _checkAnswer,
                        ),
                        const SizedBox(height: 24),
                        _AccuracyBar(progress: progress),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Feedback banner (slides in from bottom) ──────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _isAnswered ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                child: _FeedbackBanner(
                  isCorrect: _isCorrect,
                  message: _feedbackMessage,
                  onNext: () => _generateQuestion(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isSoundEnabled,
    required this.onSoundToggle,
  });

  final bool isSoundEnabled;
  final VoidCallback onSoundToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF333333),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'Doubles Addition',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color:
                  isSoundEnabled ? const Color(0xFFFF6B35) : Colors.grey,
            ),
            onPressed: onSoundToggle,
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.score,
    required this.total,
    required this.streak,
    required this.bestStreak,
    required this.scoreKey,
    required this.streakKey,
  });

  final int score, total, streak, bestStreak, scoreKey, streakKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCell(
            label: 'Score',
            value: '$score / $total',
            color: const Color(0xFF6C5CE7),
            animKey: scoreKey,
          ),
          _Divider(),
          _StatCell(
            label: 'Streak',
            value: '🔥 $streak',
            color: const Color(0xFFFF6B35),
            animKey: streakKey,
          ),
          _Divider(),
          _StatCell(
            label: 'Best',
            value: '⭐ $bestStreak',
            color: const Color(0xFFF59E0B),
            animKey: 0,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.animKey,
  });

  final String label, value;
  final Color color;
  final int animKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9E9E9E),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            value,
            key: ValueKey('$label-$animKey'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.num,
    required this.isAnswered,
    required this.isCorrect,
  });

  final int num;
  final bool isAnswered, isCorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: const Border(
          top: BorderSide(color: Color(0xFFFF6B35), width: 6),
        ),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, 5))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      child: Column(
        children: [
          Text(
            '$num + $num = ?',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Color(0xFF222222),
              letterSpacing: 3,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isAnswered
                ? Padding(
                    key: const ValueKey('explanation'),
                    padding: const EdgeInsets.only(top: 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Double $num = ${num * 2}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isCorrect
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), height: 0),
          ),
        ],
      ),
    );
  }
}

class _AnswerInput extends StatelessWidget {
  const _AnswerInput({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: enabled,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
          decoration: InputDecoration(
            hintText: 'Type your answer…',
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 18),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: Colors.grey.shade300, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: Color(0xFFFF6B35), width: 2.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: Colors.grey.shade200, width: 2),
            ),
          ),
          onSubmitted: (_) => onSubmit?.call(),
        ),
        if (enabled) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: const Color(0xFFFF6B35).withValues(alpha: 0.4),
            ),
            child: const Text(
              'Check Answer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.isCorrect,
    required this.message,
    required this.onNext,
  });

  final bool isCorrect;
  final String message;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bg =
        isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 14, offset: Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Next Question →',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccuracyBar extends StatelessWidget {
  const _AccuracyBar({required this.progress});

  final double progress;

  Color get _barColor {
    if (progress >= 0.8) return const Color(0xFF4CAF50);
    if (progress >= 0.5) return const Color(0xFFFF6B35);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Accuracy',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF616161),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                key: ValueKey(progress.toStringAsFixed(2)),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 14,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
        ),
      ],
    );
  }
}
