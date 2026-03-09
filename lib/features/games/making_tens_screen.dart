import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _QuestionMode { singleDigit, nextTen }

class MakingTensScreen extends StatefulWidget {
  const MakingTensScreen({super.key});

  @override
  State<MakingTensScreen> createState() => _MakingTensScreenState();
}

class _MakingTensScreenState extends State<MakingTensScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────────
  _QuestionMode _mode = _QuestionMode.singleDigit;
  String _questionText = '';
  int _correctAnswer = 0;
  String _explanationText = '';
  int _firstNum = 0; // used for number bond visual (Mode A)

  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _isAnswered = false;
  bool _isCorrect = false;
  String _feedbackMessage = '';
  bool _isSoundEnabled = true;
  bool _isHintExpanded = true;

  int _scoreKey = 0;
  int _streakKey = 0;

  final TextEditingController _answerController = TextEditingController();
  final Random _random = Random();

  // Question card animation
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  // Number bond animation (scale + fade in after correct answer)
  late final AnimationController _bondAnim;
  late final Animation<double> _bondFade;
  late final Animation<double> _bondScale;

  // "?" pulse animation
  late final AnimationController _pulseAnim;
  late final Animation<double> _pulseScale;

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
        duration: const Duration(milliseconds: 350), vsync: this, value: 1.0);
    _questionFade =
        CurvedAnimation(parent: _questionAnim, curve: Curves.easeInOut);
    _questionSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _questionAnim, curve: Curves.easeOut));

    _bondAnim = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _bondFade =
        CurvedAnimation(parent: _bondAnim, curve: Curves.easeIn);
    _bondScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _bondAnim, curve: Curves.easeOutBack));

    _pulseAnim = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));

    _generateQuestion(initial: true);
  }

  @override
  void dispose() {
    _questionAnim.dispose();
    _bondAnim.dispose();
    _pulseAnim.dispose();
    _answerController.dispose();
    super.dispose();
  }

  // ── Question generation ───────────────────────────────────────────────────────
  void _generateQuestion({bool initial = false}) {
    if (!initial) {
      _questionAnim.reverse().then((_) {
        _buildQuestion();
        _questionAnim.forward();
      });
    } else {
      _buildQuestion();
    }
  }

  void _buildQuestion() {
    _bondAnim.reset();
    _answerController.clear();

    final useSingleDigit = _random.nextBool();

    if (useSingleDigit) {
      // Mode A — Making 10s
      final first = _random.nextInt(9) + 1; // 1–9
      setState(() {
        _mode = _QuestionMode.singleDigit;
        _firstNum = first;
        _questionText = '$first + ? = 10';
        _correctAnswer = 10 - first;
        _explanationText = '$first + ${10 - first} = 10';
        _isAnswered = false;
        _isCorrect = false;
        _feedbackMessage = '';
      });
    } else {
      // Mode B — Making the Next Ten
      final tens = (_random.nextInt(9) + 1) * 10; // 10–90
      final ones = _random.nextInt(9) + 1; // 1–9
      final base = tens + ones;
      final target = tens + 10;
      final add = 10 - ones;

      final useSubFormat2 = _random.nextBool();

      if (useSubFormat2) {
        // Sub-format 2: find missing number
        setState(() {
          _mode = _QuestionMode.nextTen;
          _firstNum = base;
          _questionText = '$base + ? = $target';
          _correctAnswer = target - base;
          _explanationText = '$base + ${target - base} = $target';
          _isAnswered = false;
          _isCorrect = false;
          _feedbackMessage = '';
        });
      } else {
        // Sub-format 1: solve the sum
        setState(() {
          _mode = _QuestionMode.nextTen;
          _firstNum = base;
          _questionText = '$base + $add = ?';
          _correctAnswer = base + add;
          _explanationText =
              '$base + $add = $target (making the next ten)';
          _isAnswered = false;
          _isCorrect = false;
          _feedbackMessage = '';
        });
      }
    }
  }

  // ── Answer checking ───────────────────────────────────────────────────────────
  void _checkAnswer() {
    final parsed = int.tryParse(_answerController.text.trim());
    if (parsed == null) {
      HapticFeedback.vibrate();
      return;
    }

    final correct = parsed == _correctAnswer;
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
        if (_mode == _QuestionMode.singleDigit) _bondAnim.forward();
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
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = _totalQuestions == 0
        ? 0.0
        : (_score / _totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAFA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildModeBadge(),
                        const SizedBox(height: 12),
                        _HintCard(
                          isExpanded: _isHintExpanded,
                          onToggle: () => setState(
                              () => _isHintExpanded = !_isHintExpanded),
                        ),
                        const SizedBox(height: 14),
                        _buildScoreRow(),
                        const SizedBox(height: 22),
                        SlideTransition(
                          position: _questionSlide,
                          child: FadeTransition(
                            opacity: _questionFade,
                            child: _buildQuestionCard(),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _buildAnswerInput(),
                        // Number bond visual (Mode A, after correct answer)
                        if (_isAnswered &&
                            _isCorrect &&
                            _mode == _QuestionMode.singleDigit) ...[
                          const SizedBox(height: 20),
                          FadeTransition(
                            opacity: _bondFade,
                            child: ScaleTransition(
                              scale: _bondScale,
                              child: _NumberBond(
                                total: 10,
                                left: _firstNum,
                                right: _correctAnswer,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildProgressBar(progress),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Feedback banner
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset: _isAnswered ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                child: _buildFeedbackBanner(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'Making 10s',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _isSoundEnabled
                  ? const Color(0xFF00BCD4)
                  : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBadge() {
    final isSingle = _mode == _QuestionMode.singleDigit;
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_mode),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSingle
                ? const Color(0xFF2196F3)
                : const Color(0xFF9C27B0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isSingle ? 'Single Digits' : 'Next Ten',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow() {
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
              value: '$_score / $_totalQuestions',
              color: const Color(0xFF00BCD4),
              animKey: _scoreKey),
          _RowDivider(),
          _StatCell(
              label: 'Streak',
              value: '🔥 $_streak',
              color: const Color(0xFFFF6B35),
              animKey: _streakKey),
          _RowDivider(),
          _StatCell(
              label: 'Best',
              value: '⭐ $_bestStreak',
              color: const Color(0xFFF59E0B),
              animKey: 0),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    // Parse display parts to highlight "?"
    final parts = _questionText.split('?');
    final hasQuestion = parts.length == 2;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border:
            const Border(top: BorderSide(color: Color(0xFF00BCD4), width: 6)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, 5))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
      child: Column(
        children: [
          // Question with pulsing "?"
          hasQuestion
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      parts[0],
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF222222),
                        letterSpacing: 2,
                      ),
                    ),
                    if (!_isAnswered)
                      ScaleTransition(
                        scale: _pulseScale,
                        child: const Text(
                          '?',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00BCD4),
                            letterSpacing: 2,
                          ),
                        ),
                      )
                    else
                      Text(
                        '$_correctAnswer',
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00BCD4),
                          letterSpacing: 2,
                        ),
                      ),
                    Text(
                      parts[1],
                      style: const TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF222222),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                )
              : Text(
                  _questionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF222222),
                    letterSpacing: 2,
                  ),
                ),

          // Explanation after answer
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isAnswered
                ? Padding(
                    key: const ValueKey('exp'),
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isCorrect
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _explanationText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: _isCorrect
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

  Widget _buildAnswerInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _answerController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !_isAnswered,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222)),
          decoration: InputDecoration(
            hintText: 'What is ?',
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
                    color: Color(0xFF00BCD4), width: 2.5)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: Colors.grey.shade200, width: 2)),
          ),
          onSubmitted: (_) => _isAnswered ? null : _checkAnswer(),
        ),
        if (!_isAnswered) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: const Color(0xFF00BCD4).withOpacity(0.4),
            ),
            child: const Text('Check Answer',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  Widget _buildFeedbackBanner() {
    final bg =
        _isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
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
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _feedbackMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _explanationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _generateQuestion(),
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

  Widget _buildProgressBar(double progress) {
    Color barColor;
    if (progress >= 0.8) {
      barColor = const Color(0xFF4CAF50);
    } else if (progress >= 0.5) {
      barColor = const Color(0xFF00BCD4);
    } else {
      barColor = const Color(0xFFF44336);
    }

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
                    color: Color(0xFF00BCD4)),
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
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared stat cell ──────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell(
      {required this.label,
      required this.value,
      required this.color,
      required this.animKey});
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
          child: Text(value,
              key: ValueKey('$label-$animKey'),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
}

// ── Hint card ─────────────────────────────────────────────────────────────────

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
          color: const Color(0xFFFFF9C4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF00BCD4).withOpacity(0.4), width: 1.5),
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
                      'Making 10s Trick',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00838F)),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF00BCD4),
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
                      'Find what\'s missing to reach 10 (or the next 10)!',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF006064),
                          height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '7 + ? = 10  →  7 needs 3 more to make 10',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00838F)),
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

// ── Number Bond Visual ────────────────────────────────────────────────────────

class _NumberBond extends StatelessWidget {
  const _NumberBond(
      {required this.total, required this.left, required this.right});
  final int total, left, right;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Number Bond',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(height: 12),
        CustomPaint(
          size: const Size(200, 110),
          painter: _BondPainter(),
          child: SizedBox(
            width: 200,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top circle — total
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(child: _BondCircle(label: '$total', large: true)),
                ),
                // Bottom-left — left part
                Positioned(
                  bottom: 0,
                  left: 10,
                  child: _BondCircle(label: '$left'),
                ),
                // Bottom-right — right part
                Positioned(
                  bottom: 0,
                  right: 10,
                  child: _BondCircle(label: '$right'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BondCircle extends StatelessWidget {
  const _BondCircle({required this.label, this.large = false});
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 54.0 : 46.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00BCD4), width: 2.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00BCD4).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
              fontSize: large ? 20 : 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF006064)),
        ),
      ),
    );
  }
}

class _BondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00BCD4).withOpacity(0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final topCenter = Offset(size.width / 2, 27);
    final bottomLeft = Offset(33, size.height - 23);
    final bottomRight = Offset(size.width - 33, size.height - 23);

    canvas.drawLine(topCenter, bottomLeft, paint);
    canvas.drawLine(topCenter, bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
