import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NearDoublesScreen extends StatefulWidget {
  const NearDoublesScreen({super.key});

  @override
  State<NearDoublesScreen> createState() => _NearDoublesScreenState();
}

class _NearDoublesScreenState extends State<NearDoublesScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────────
  int _baseNum = 1;
  int _firstNum = 1;
  int _secondNum = 2;
  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _isSoundEnabled = true;
  bool _isHintExpanded = true;

  // AnimatedSwitcher keys
  int _scoreKey = 0;
  int _streakKey = 0;

  final TextEditingController _answerController = TextEditingController();
  final Random _random = Random();

  // Question card animation
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  // ── Messages ──────────────────────────────────────────────────────────────────
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

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
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

  // ── Sound synthesis ──────────────────────────────────────────────────────────



  Future<void> _playCorrectSound() async {
    if (!_isSoundEnabled) return;
    try {
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) => player.dispose());
      await player.play(AssetSource('audio/correct_sound_effect.mp3'));
    } catch (_) {}
  }

  Future<void> _playWrongSound() async {
    if (!_isSoundEnabled) return;
    try {
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) => player.dispose());
      await player.play(AssetSource('audio/wrong_sound_effect.mp3'));
    } catch (_) {}
  }

  // ── Game logic ────────────────────────────────────────────────────────────────
  void _generateQuestion({bool initial = false}) {
    if (!initial) {
      _questionAnim.reverse().then((_) {
        _setNewQuestion();
        _questionAnim.forward();
      });
    } else {
      _setNewQuestion();
    }
  }

  void _setNewQuestion() {
    final base = _random.nextInt(12) + 1;
    final swapped = _random.nextBool();
    setState(() {
      _baseNum = base;
      _firstNum = swapped ? base + 1 : base;
      _secondNum = swapped ? base : base + 1;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });
    _answerController.clear();
  }

  void _checkAnswer() {
    final parsed = int.tryParse(_answerController.text.trim());
    if (parsed == null) {
      HapticFeedback.vibrate();
      return;
    }

    final correct = parsed == _firstNum + _secondNum;
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

    if (_isSoundEnabled) {
      correct
          ? HapticFeedback.lightImpact()
          : HapticFeedback.heavyImpact();
      correct ? _playCorrectSound() : _playWrongSound();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = _totalQuestions == 0
        ? 0.0
        : (_score / _totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  isSoundEnabled: _isSoundEnabled,
                  onSoundToggle: () =>
                      setState(() => _isSoundEnabled = !_isSoundEnabled),
                  onNewRound: _setNewQuestion,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HintCard(
                          isExpanded: _isHintExpanded,
                          onToggle: () => setState(
                              () => _isHintExpanded = !_isHintExpanded),
                        ),
                        const SizedBox(height: 16),
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
                              firstNum: _firstNum,
                              secondNum: _secondNum,
                              baseNum: _baseNum,
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

            // Feedback banner slides in from bottom
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
                  baseNum: _baseNum,
                  answer: _firstNum + _secondNum,
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isSoundEnabled,
    required this.onSoundToggle,
    required this.onNewRound,
  });

  final bool isSoundEnabled;
  final VoidCallback onSoundToggle;
  final VoidCallback onNewRound;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'Near Doubles Addition',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
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
              color: isSoundEnabled ? const Color(0xFF6C5CE7) : Colors.grey,
            ),
            onPressed: onSoundToggle,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF333333)),
            tooltip: 'New Round',
            onPressed: onNewRound,
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.isExpanded, required this.onToggle});

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Near Doubles Trick',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4C1D95),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF6C5CE7),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find the double of the smaller number, then add 1!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5B21B6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '7 + 8  →  think 7+7 = 14, then +1 = 15 ✓',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4C1D95),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
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
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCell(
              label: 'Score',
              value: '$score / $total',
              color: const Color(0xFF6C5CE7),
              animKey: scoreKey),
          _Divider(),
          _StatCell(
              label: 'Streak',
              value: '🔥 $streak',
              color: const Color(0xFFFF6B35),
              animKey: streakKey),
          _Divider(),
          _StatCell(
              label: 'Best',
              value: '⭐ $bestStreak',
              color: const Color(0xFFF59E0B),
              animKey: 0),
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
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9E9E9E))),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            value,
            key: ValueKey('$label-$animKey'),
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.firstNum,
    required this.secondNum,
    required this.baseNum,
    required this.isAnswered,
    required this.isCorrect,
  });

  final int firstNum, secondNum, baseNum;
  final bool isAnswered, isCorrect;

  @override
  Widget build(BuildContext context) {
    final answer = firstNum + secondNum;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: const Border(
          top: BorderSide(color: Color(0xFF6C5CE7), width: 6),
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
            '$firstNum + $secondNum = ?',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Color(0xFF222222),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          // Always-visible tip
          if (!isAnswered)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Tip: What\'s the double of $baseNum?',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
          // Explanation after answer
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isAnswered
                ? Padding(
                    key: const ValueKey('explanation'),
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '$firstNum + $secondNum = $answer\n'
                        '(near doubles: think $baseNum + $baseNum + 1)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
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
              color: Color(0xFF222222)),
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
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: Colors.grey.shade300, width: 2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                    color: Color(0xFF6C5CE7), width: 2.5)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: Colors.grey.shade200, width: 2)),
          ),
          onSubmitted: (_) => onSubmit?.call(),
        ),
        if (enabled) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
            ),
            child: const Text('Check Answer',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    required this.baseNum,
    required this.answer,
    required this.onNext,
  });

  final bool isCorrect;
  final String message;
  final int baseNum, answer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bg =
        isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final doubleOfBase = baseNum * 2;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
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
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Near-doubles breakdown
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$baseNum + $baseNum = $doubleOfBase,  then +1 = $answer',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
              child: const Text('Next Question →',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
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
    if (progress >= 0.5) return const Color(0xFF6C5CE7);
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
            const Text('Accuracy',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161))),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                key: ValueKey(progress.toStringAsFixed(2)),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7)),
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
