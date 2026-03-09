import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _SubFormat { solveSum, findMissing }

class MakingNextTenScreen extends StatefulWidget {
  const MakingNextTenScreen({super.key});

  @override
  State<MakingNextTenScreen> createState() => _MakingNextTenScreenState();
}

class _MakingNextTenScreenState extends State<MakingNextTenScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────────
  _SubFormat _subFormat = _SubFormat.findMissing;
  int _base = 0;
  int _add = 0;
  int _target = 0;
  int _ones = 0;
  String _questionText = '';
  int _correctAnswer = 0;
  String _explanationText = '';

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

  // Question card fade+slide
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  // Number line slide-in
  late final AnimationController _numberLineAnim;
  late final Animation<Offset> _numberLineSlide;
  late final Animation<double> _numberLineFade;

  // Arrow draw progress
  late final AnimationController _arrowAnim;
  late final Animation<double> _arrowProgress;

  // "?" pulse
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

    _numberLineAnim = AnimationController(
        duration: const Duration(milliseconds: 450), vsync: this);
    _numberLineSlide = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _numberLineAnim, curve: Curves.easeOut));
    _numberLineFade =
        CurvedAnimation(parent: _numberLineAnim, curve: Curves.easeIn);

    _arrowAnim = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _arrowProgress =
        CurvedAnimation(parent: _arrowAnim, curve: Curves.easeOut);

    _pulseAnim = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.13).animate(
        CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut));

    _generateQuestion(initial: true);
  }

  @override
  void dispose() {
    _questionAnim.dispose();
    _numberLineAnim.dispose();
    _arrowAnim.dispose();
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
    _numberLineAnim.reset();
    _arrowAnim.reset();
    _answerController.clear();

    final tens = (_random.nextInt(9) + 1) * 10; // 10–90
    final ones = _random.nextInt(9) + 1; // 1–9
    final base = tens + ones;
    final add = 10 - ones;
    final target = tens + 10;
    final useSubFormat2 = _random.nextBool();

    setState(() {
      _base = base;
      _add = add;
      _target = target;
      _ones = ones;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';

      if (useSubFormat2) {
        _subFormat = _SubFormat.findMissing;
        _questionText = '$base + ? = $target';
        _correctAnswer = add;
        _explanationText = '$base + $add = $target';
      } else {
        _subFormat = _SubFormat.solveSum;
        _questionText = '$base + $add = ?';
        _correctAnswer = target;
        _explanationText = '$base + $add = $target (making the next ten)';
      }
    });
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
      } else {
        _streak = 0;
        _streakKey++;
        _feedbackMessage =
            _incorrectMsgs[_random.nextInt(_incorrectMsgs.length)];
      }
    });

    // Animate number line in
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        _numberLineAnim.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _arrowAnim.forward();
        });
      }
    });

    if (_isSoundEnabled) {
      correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = _totalQuestions == 0
        ? 0.0
        : (_score / _totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
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
                        // Number line after submission
                        if (_isAnswered) ...[
                          const SizedBox(height: 22),
                          SlideTransition(
                            position: _numberLineSlide,
                            child: FadeTransition(
                              opacity: _numberLineFade,
                              child: _NumberLine(
                                base: _base,
                                target: _target,
                                add: _add,
                                progress: _arrowProgress,
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

  // ── Top bar ───────────────────────────────────────────────────────────────────
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
              'Making Next 10',
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
              color:
                  _isSoundEnabled ? const Color(0xFF9C27B0) : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
        ],
      ),
    );
  }

  // ── Score row ─────────────────────────────────────────────────────────────────
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
              color: const Color(0xFF9C27B0),
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

  // ── Question card ─────────────────────────────────────────────────────────────
  Widget _buildQuestionCard() {
    const purple = Color(0xFF9C27B0);
    const dark = Color(0xFF222222);

    // Split on "?" to render it highlighted
    final hasMissing = _subFormat == _SubFormat.findMissing && !_isAnswered;
    final parts = _questionText.split('?');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: const Border(top: BorderSide(color: purple, width: 6)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, 5))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        children: [
          // Question text with optional highlighted "?"
          hasMissing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(parts[0],
                        style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: dark,
                            letterSpacing: 2)),
                    ScaleTransition(
                      scale: _pulseScale,
                      child: const Text('?',
                          style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: purple,
                              letterSpacing: 2)),
                    ),
                    Text(parts[1],
                        style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: dark,
                            letterSpacing: 2)),
                  ],
                )
              : _isAnswered && _subFormat == _SubFormat.findMissing
                  // Show answered value in purple
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(parts[0],
                            style: const TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                color: dark,
                                letterSpacing: 2)),
                        Text('$_add',
                            style: const TextStyle(
                                fontSize: 54,
                                fontWeight: FontWeight.w900,
                                color: purple,
                                letterSpacing: 2)),
                        Text(parts[1],
                            style: const TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                color: dark,
                                letterSpacing: 2)),
                      ],
                    )
                  : Text(
                      _isAnswered && _subFormat == _SubFormat.solveSum
                          ? _questionText.replaceAll('?', '$_correctAnswer')
                          : _questionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          color: dark,
                          letterSpacing: 2)),

          // Hint below question (always visible before answer)
          if (!_isAnswered) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Hint: ones digit is $_ones, next ten is $_target',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7B1FA2)),
              ),
            ),
          ],

          // Explanation after answer
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isAnswered
                ? Padding(
                    key: const ValueKey('exp'),
                    padding: const EdgeInsets.only(top: 18),
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
                                : const Color(0xFFC62828)),
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), height: 0),
          ),
        ],
      ),
    );
  }

  // ── Answer input ──────────────────────────────────────────────────────────────
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
                    color: Color(0xFF9C27B0), width: 2.5)),
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
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: const Color(0xFF9C27B0).withOpacity(0.4),
            ),
            child: const Text('Check Answer',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }

  // ── Feedback banner ───────────────────────────────────────────────────────────
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

  // ── Progress bar ──────────────────────────────────────────────────────────────
  Widget _buildProgressBar(double progress) {
    Color barColor;
    if (progress >= 0.8) {
      barColor = const Color(0xFF4CAF50);
    } else if (progress >= 0.5) {
      barColor = const Color(0xFF9C27B0);
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
                    color: Color(0xFF9C27B0)),
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
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF9C27B0).withOpacity(0.35), width: 1.5),
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
                      'Making the Next Ten',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6A1B9A)),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF9C27B0),
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
                      'Look at the ones digit — how much does it need to reach 10?',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A148C),
                          height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '73 + ? = 80  →  ones digit is 3, needs 7 more',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A1B9A)),
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

// ── Number line visual ────────────────────────────────────────────────────────

class _NumberLine extends StatelessWidget {
  const _NumberLine({
    required this.base,
    required this.target,
    required this.add,
    required this.progress,
  });

  final int base, target, add;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Number Jump',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9E9E)),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: progress,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 70),
              painter: _NumberLinePainter(
                base: base,
                target: target,
                add: add,
                progress: progress.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({
    required this.base,
    required this.target,
    required this.add,
    required this.progress,
  });

  final int base, target, add;
  final double progress;

  static const _purple = Color(0xFF9C27B0);
  static const _dark = Color(0xFF333333);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFBBBBBB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = _purple
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = _purple
      ..style = PaintingStyle.fill;

    const leftPad = 32.0;
    const rightPad = 32.0;
    final lineY = size.height * 0.62;
    final lineStart = leftPad;
    final lineEnd = size.width - rightPad;

    // Base and target x positions
    const baseX = leftPad + 10.0;
    final targetX = size.width - rightPad - 10.0;

    // ── Horizontal line ──────────────────────────────────────────────────────
    canvas.drawLine(
        Offset(lineStart, lineY), Offset(lineEnd, lineY), linePaint);

    // ── Tick marks ────────────────────────────────────────────────────────────
    const tickH = 10.0;
    for (final x in [baseX, targetX]) {
      canvas.drawLine(
          Offset(x, lineY - tickH), Offset(x, lineY + tickH), linePaint);
    }

    // ── Dots on ticks ─────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(baseX, lineY), 5, dotPaint);
    canvas.drawCircle(
        Offset(targetX, lineY), 5, dotPaint..color = _purple.withOpacity(progress));

    // ── Animated arc arrow (above the line) ──────────────────────────────────
    final arcWidth = (targetX - baseX) * progress;
    final arcEndX = baseX + arcWidth;
    final arcTop = lineY - 36.0;

    if (progress > 0.01) {
      final path = Path()
        ..moveTo(baseX, lineY - 6)
        ..cubicTo(
          baseX + arcWidth * 0.1, arcTop,
          baseX + arcWidth * 0.9, arcTop,
          arcEndX, lineY - 6,
        );
      canvas.drawPath(path, arrowPaint);

      // Arrowhead at end
      if (progress > 0.85) {
        const arrowSize = 8.0;
        final arrowOpacity = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
        final arrowTip = Offset(arcEndX, lineY - 6);
        final arrowLeft =
            Offset(arcEndX - arrowSize, lineY - 6 - arrowSize * 0.6);
        final arrowRight =
            Offset(arcEndX - arrowSize, lineY - 6 + arrowSize * 0.6);
        final headPaint = Paint()
          ..color = _purple.withOpacity(arrowOpacity)
          ..strokeWidth = 2.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(arrowTip, arrowLeft, headPaint);
        canvas.drawLine(arrowTip, arrowRight, headPaint);
      }

      // "+{add}" label on arc midpoint
      if (progress > 0.45) {
        final labelOpacity = ((progress - 0.45) / 0.3).clamp(0.0, 1.0);
        final labelX = baseX + arcWidth * 0.5;
        final labelY = arcTop - 4;
        final tp = TextPainter(
          text: TextSpan(
            text: '+$add',
            style: TextStyle(
              color: _purple.withOpacity(labelOpacity),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(labelX - tp.width / 2, labelY - tp.height));
      }
    }

    // ── Labels below ticks ────────────────────────────────────────────────────
    void drawLabel(String text, double x) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
              color: _dark, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(x - tp.width / 2, lineY + tickH + 4));
    }

    drawLabel('$base', baseX);
    drawLabel('$target', targetX);
  }

  @override
  bool shouldRepaint(_NumberLinePainter old) =>
      old.progress != progress ||
      old.base != base ||
      old.target != target;
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
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
