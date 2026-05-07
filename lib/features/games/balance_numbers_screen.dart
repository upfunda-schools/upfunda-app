import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BalanceNumbersScreen extends StatefulWidget {
  const BalanceNumbersScreen({super.key});

  @override
  State<BalanceNumbersScreen> createState() => _BalanceNumbersScreenState();
}

class _BalanceNumbersScreenState extends State<BalanceNumbersScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────────
  int _targetSum = 0;
  int _givenNumber = 0;
  int _correctAnswer = 0;
  List<int> _options = [];
  int? _selectedAnswer;
  bool _isBalanced = false;
  bool _isAnswered = false;

  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  int _bestStreak = 0;
  String _feedbackMessage = '';
  bool _isSoundEnabled = true;

  int _scoreKey = 0;
  int _streakKey = 0;

  final Random _random = Random();

  // Tilt animation
  late final AnimationController _tiltController;
  late Animation<double> _tiltAnim;

  // Question card animation
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  // ── Difficulty ────────────────────────────────────────────────────────────────
  int get _difficultyLevel => (_totalQuestions ~/ 5).clamp(0, 4);

  static const _difficultyRanges = [
    (minT: 10, maxT: 25, maxM: 15),
    (minT: 15, maxT: 35, maxM: 20),
    (minT: 20, maxT: 45, maxM: 25),
    (minT: 25, maxT: 60, maxM: 30),
    (minT: 30, maxT: 80, maxM: 40),
  ];

  static const _levelColors = [
    Color(0xFF4CAF50), // 1 - green
    Color(0xFF2196F3), // 2 - blue
    Color(0xFFFF9800), // 3 - orange
    Color(0xFF9C27B0), // 4 - purple
    Color(0xFFF44336), // 5 - red
  ];

  // ── Messages ──────────────────────────────────────────────────────────────────
  static const _correctMsgs = [
    "Amazing work! 🌟", "You're on fire! 🔥", "Brilliant! Keep it up! 💪",
    "Fantastic! You're a math star! ⭐", "Perfect! You're unstoppable! 🚀",
    "Excellent! You've got this! 🎯", "Super! Keep going! 🎉", "Outstanding! 🏆",
  ];
  static const _incorrectMsgs = [
    "Good try! You'll get it! 💪", "Almost! Try the next one! 🌟",
    "Keep going, you're learning! 📚", "Don't give up! You've got this! 🎯",
    "Nice effort! Math takes practice! ✨", "So close! Keep trying! 🔥",
    "Great attempt! Try again! 💡", "You're improving! Keep it up! 🌈",
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _tiltController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _tiltAnim = const AlwaysStoppedAnimation(0.0);

    _questionAnim = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this, value: 1.0);
    _questionFade =
        CurvedAnimation(parent: _questionAnim, curve: Curves.easeInOut);
    _questionSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _questionAnim, curve: Curves.easeOut));

    _generateQuestion(initial: true);
  }

  @override
  void dispose() {
    _tiltController.dispose();
    _questionAnim.dispose();
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

  // ── Tilt ──────────────────────────────────────────────────────────────────────
  double _computeRawTilt(int left, int right) =>
      (left - right) * 1.5;

  void _animateTilt(double newTilt) {
    final from = _tiltAnim.value;
    final to = newTilt.clamp(-15.0, 15.0);
    _tiltAnim = Tween<double>(begin: from, end: to)
        .animate(CurvedAnimation(parent: _tiltController, curve: Curves.easeOut));
    _tiltController.forward(from: 0);
  }

  // ── Question generation ───────────────────────────────────────────────────────
  void _generateQuestion({bool initial = false}) {
    final level = _difficultyLevel;
    final r = _difficultyRanges[level];

    int targetSum, givenNumber, correctAnswer;

    // Try primary generation
    targetSum = _random.nextInt(r.maxT - r.minT + 1) + r.minT;
    final minAns = max(1, min(5, targetSum - 1));
    final maxAns = min(r.maxM, targetSum - 1);

    if (minAns <= maxAns) {
      correctAnswer = _random.nextInt(maxAns - minAns + 1) + minAns;
      givenNumber = targetSum - correctAnswer;
    } else {
      targetSum = _random.nextInt(30) + 15;
      givenNumber = _random.nextInt(max(1, targetSum - 5)) + 1;
      correctAnswer = targetSum - givenNumber;
    }

    // Validate, fallback if needed
    if (givenNumber < 1 || givenNumber >= targetSum) {
      targetSum = _random.nextInt(30) + 15;
      givenNumber = _random.nextInt(max(1, targetSum - 5)) + 1;
      correctAnswer = targetSum - givenNumber;
    }

    final options = [
      correctAnswer,
      ..._generateWrongOptions(correctAnswer, targetSum, givenNumber, level)
    ]..shuffle(_random);

    final initialTilt =
        _computeRawTilt(targetSum, givenNumber).clamp(-15.0, 15.0);

    setState(() {
      _targetSum = targetSum;
      _givenNumber = givenNumber;
      _correctAnswer = correctAnswer;
      _options = options;
      _selectedAnswer = null;
      _isBalanced = false;
      _isAnswered = false;
      _feedbackMessage = '';
    });

    if (!initial) {
      _animateTilt(initialTilt);
      _questionAnim.forward(from: 0);
    } else {
      _tiltAnim = AlwaysStoppedAnimation(initialTilt);
    }
  }

  List<int> _generateWrongOptions(
      int correct, int target, int given, int level) {
    final Set<int> c = {};
    final near = level >= 2 ? 4 : 2;
    for (int d = 1; d <= near; d++) {
      c.add(correct + d);
      c.add(correct - d);
    }
    c.add(target ~/ 2);
    c.add(correct * 2);
    c.add(given);
    c.add(target);
    c.removeWhere((n) => n < 1 || n == correct);

    final list = c.toList()..shuffle(_random);
    final result = list.take(3).toList();

    // Pad to 3 if needed
    int pad = 1;
    while (result.length < 3 && pad < 30) {
      final cand = correct + (pad.isEven ? pad : -pad);
      if (cand >= 1 && cand != correct && !result.contains(cand)) {
        result.add(cand);
      }
      pad++;
    }
    return result;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────────
  void _resetGame() {
    setState(() {
      _score = 0;
      _totalQuestions = 0;
      _streak = 0;
      _bestStreak = 0;
      _scoreKey = 0;
      _streakKey = 0;
    });
    _generateQuestion();
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Round?'),
        content: const Text('Score, streak and best will be reset.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Answer checking ───────────────────────────────────────────────────────────
  void _onOptionTap(int answer) {
    if (_isAnswered) return;
    final correct = answer == _correctAnswer;
    final newTilt = correct
        ? 0.0
        : _computeRawTilt(_targetSum, _givenNumber + answer);

    setState(() {
      _selectedAnswer = answer;
      _isBalanced = correct;
      _isAnswered = true;
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

    _animateTilt(newTilt);

    if (_isSoundEnabled) {
      correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
      correct ? _playCorrectSound() : _playWrongSound();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = _totalQuestions == 0
        ? 0.0
        : (_score / _totalQuestions).clamp(0.0, 1.0);
    final level = _difficultyLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
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
                        // Difficulty badge
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              key: ValueKey(level),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: _levelColors[level],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Level ${level + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildScoreRow(),
                        const SizedBox(height: 20),

                        // Question text
                        SlideTransition(
                          position: _questionSlide,
                          child: FadeTransition(
                            opacity: _questionFade,
                            child: Column(
                              children: [
                                _buildQuestionText(),
                                const SizedBox(height: 16),

                                // Balance scale
                                AnimatedBuilder(
                                  animation: _tiltController,
                                  builder: (_, __) => _BalanceScale(
                                    tilt: _tiltAnim.value,
                                    targetSum: _targetSum,
                                    givenNumber: _givenNumber,
                                    selectedAnswer: _selectedAnswer,
                                    isBalanced: _isBalanced,
                                  ),
                                ),
                                if (_isBalanced) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    '⚖️ Balanced!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2x2 option grid
                        _buildOptionGrid(),
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
              'Balance Numbers',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 19,
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
                  ? const Color(0xFFFF9800)
                  : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF333333)),
            tooltip: 'New Round',
            onPressed: _showResetDialog,
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
              color: const Color(0xFFFF9800),
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

  // ── Question text ─────────────────────────────────────────────────────────────
  Widget _buildQuestionText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFF333333)),
        children: [
          TextSpan(text: 'Balance the scale!\n$_givenNumber + '),
          const TextSpan(
            text: '?',
            style: TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 36,
                fontWeight: FontWeight.w900),
          ),
          TextSpan(text: ' = $_targetSum'),
        ],
      ),
    );
  }

  // ── Option grid ───────────────────────────────────────────────────────────────
  Widget _buildOptionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: _options
          .map((opt) => _OptionButton(
                value: opt,
                isSelected: _selectedAnswer == opt,
                isAnswered: _isAnswered,
                isCorrect: opt == _correctAnswer,
                onTap: () => _onOptionTap(opt),
              ))
          .toList(),
    );
  }

  // ── Feedback banner ───────────────────────────────────────────────────────────
  Widget _buildFeedbackBanner() {
    final bg =
        _isBalanced ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final explanation =
        '$_givenNumber + $_correctAnswer = $_targetSum';

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
              color: Colors.white.withValues(alpha: 0.4),
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
      barColor = const Color(0xFFFF9800);
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
                    color: Color(0xFFFF9800)),
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
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
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

// ── Balance Scale Widget ──────────────────────────────────────────────────────

class _BalanceScale extends StatelessWidget {
  const _BalanceScale({
    required this.tilt,
    required this.targetSum,
    required this.givenNumber,
    required this.selectedAnswer,
    required this.isBalanced,
  });

  final double tilt;
  final int targetSum;
  final int givenNumber;
  final int? selectedAnswer;
  final bool isBalanced;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: CustomPaint(
        painter: _ScalePainter(
          tilt: tilt,
          targetSum: targetSum,
          givenNumber: givenNumber,
          selectedAnswer: selectedAnswer,
          isBalanced: isBalanced,
        ),
      ),
    );
  }
}

class _ScalePainter extends CustomPainter {
  _ScalePainter({
    required this.tilt,
    required this.targetSum,
    required this.givenNumber,
    required this.selectedAnswer,
    required this.isBalanced,
  });

  final double tilt; // −15 to 15 degrees
  final int targetSum;
  final int givenNumber;
  final int? selectedAnswer;
  final bool isBalanced;

  @override
  void paint(Canvas canvas, Size size) {
    const toRad = pi / 180;
    final cx = size.width / 2;
    final pivotY = 36.0;

    // ── Pole ──────────────────────────────────────────────────────────────
    canvas.drawLine(
      Offset(cx, 4),
      Offset(cx, pivotY),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(cx, pivotY),
      9,
      Paint()..color = const Color(0xFF4E342E)..style = PaintingStyle.fill,
    );

    // ── Beam ──────────────────────────────────────────────────────────────
    final beamAngle = -tilt * 0.5 * toRad;
    final beamHalf = size.width * 0.34;

    final lx = cx + (-beamHalf) * cos(beamAngle);
    final ly = pivotY + (-beamHalf) * sin(beamAngle);
    final rx = cx + beamHalf * cos(beamAngle);
    final ry = pivotY + beamHalf * sin(beamAngle);

    canvas.drawLine(
      Offset(lx, ly),
      Offset(rx, ry),
      Paint()
        ..color =
            isBalanced ? const Color(0xFF4CAF50) : const Color(0xFF5D4037)
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // ── Strings & pans ────────────────────────────────────────────────────
    const stringLen = 42.0;
    const panR = 34.0;

    final lDrop = max(0.0, tilt * 1.5);
    final rDrop = max(0.0, -tilt * 1.5);

    final lPan = Offset(lx, ly + stringLen + lDrop + panR);
    final rPan = Offset(rx, ry + stringLen + rDrop + panR);

    final stringPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(lx, ly), Offset(lx, lPan.dy - panR), stringPaint);
    canvas.drawLine(Offset(rx, ry), Offset(rx, rPan.dy - panR), stringPaint);

    // Glow when balanced
    if (isBalanced) {
      final glowPaint = Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lPan, panR + 9, glowPaint);
      canvas.drawCircle(rPan, panR + 9, glowPaint);
    }

    // Left pan — orange (targetSum)
    final lColor =
        isBalanced ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    canvas.drawCircle(lPan, panR, Paint()..color = lColor);
    canvas.drawCircle(
        lPan,
        panR,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // Right pan — blue
    final rColor =
        isBalanced ? const Color(0xFF4CAF50) : const Color(0xFF42A5F5);
    canvas.drawCircle(rPan, panR, Paint()..color = rColor);
    canvas.drawCircle(
        rPan,
        panR,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // ── Labels ────────────────────────────────────────────────────────────
    _drawText(canvas, '$targetSum', lPan, fontSize: 22);

    // Right pan: two lines
    final line1 = '$givenNumber +';
    final line2 = selectedAnswer != null ? '$selectedAnswer' : '?';
    _drawTwoLine(canvas, line1, line2, rPan);
  }

  void _drawText(Canvas canvas, String text, Offset center,
      {double fontSize = 16}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawTwoLine(
      Canvas canvas, String top, String bottom, Offset center) {
    final tp1 = TextPainter(
      text: TextSpan(
          text: top,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    final tp2 = TextPainter(
      text: TextSpan(
          text: bottom,
          style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();

    const gap = 1.0;
    final totalH = tp1.height + gap + tp2.height;
    tp1.paint(
        canvas, Offset(center.dx - tp1.width / 2, center.dy - totalH / 2));
    tp2.paint(canvas,
        Offset(center.dx - tp2.width / 2, center.dy - totalH / 2 + tp1.height + gap));
  }

  @override
  bool shouldRepaint(_ScalePainter old) =>
      old.tilt != tilt ||
      old.selectedAnswer != selectedAnswer ||
      old.isBalanced != isBalanced ||
      old.targetSum != targetSum;
}

// ── Option button ─────────────────────────────────────────────────────────────

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.value,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.onTap,
  });

  final int value;
  final bool isSelected, isAnswered, isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color border = const Color(0xFFFFB300);
    Color text = const Color(0xFF333333);

    if (isAnswered) {
      if (isCorrect) {
        bg = const Color(0xFF4CAF50);
        border = const Color(0xFF4CAF50);
        text = Colors.white;
      } else if (isSelected) {
        bg = const Color(0xFFF44336);
        border = const Color(0xFFF44336);
        text = Colors.white;
      } else {
        bg = const Color(0xFFF5F5F5);
        border = Colors.grey.shade300;
        text = Colors.grey;
      }
    } else if (isSelected) {
      bg = const Color(0xFFFF9800);
      border = const Color(0xFFFF9800);
      text = Colors.white;
    }

    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
                color: border.withValues(alpha: isAnswered && isCorrect ? 0.3 : 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: text),
          ),
        ),
      ),
    );
  }
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
