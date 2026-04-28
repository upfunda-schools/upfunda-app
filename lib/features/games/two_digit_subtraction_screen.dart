import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TwoDigitSubtractionScreen extends StatefulWidget {
  const TwoDigitSubtractionScreen({super.key});

  @override
  State<TwoDigitSubtractionScreen> createState() =>
      _TwoDigitSubtractionScreenState();
}

class _TwoDigitSubtractionScreenState
    extends State<TwoDigitSubtractionScreen> with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────────
  int _minuend = 0;
  int _subtrahend = 0;
  int _tensPart = 0;
  int _intermediate = 0;
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
  bool _showChart = false;
  int _userAnswerValue = 0;

  int _scoreKey = 0;
  int _streakKey = 0;

  final TextEditingController _answerController = TextEditingController();
  final Random _random = Random();

  // Animations
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  late final AnimationController _chartAnim;
  late final Animation<double> _chartFade;
  late final Animation<Offset> _chartSlide;

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

  static const _blue = Color(0xFF1976D2);

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

    _chartAnim = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _chartFade =
        CurvedAnimation(parent: _chartAnim, curve: Curves.easeInOut);
    _chartSlide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _chartAnim, curve: Curves.easeOut));

    _generateQuestion(initial: true);
  }

  @override
  void dispose() {
    _questionAnim.dispose();
    _chartAnim.dispose();
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
    _answerController.clear();

    final minuend = _random.nextInt(89) + 11; // 11–99
    final subtrahend = _random.nextInt(minuend - 1) + 1; // 1 to minuend-1
    final tensPart = (subtrahend ~/ 10) * 10;
    final onesPart = subtrahend % 10;
    final intermediate = minuend - tensPart;
    final answer = minuend - subtrahend;

    String explanation;
    if (tensPart > 0 && onesPart > 0) {
      explanation =
          'Subtract $tensPart from $minuend (= $intermediate), then subtract $onesPart (= $answer)';
    } else if (tensPart == 0) {
      explanation = 'Subtract $onesPart from $minuend (= $answer)';
    } else {
      explanation = 'Subtract $tensPart from $minuend (= $answer)';
    }

    setState(() {
      _minuend = minuend;
      _subtrahend = subtrahend;
      _tensPart = tensPart;
      _intermediate = intermediate;
      _correctAnswer = answer;
      _explanationText = explanation;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
      _userAnswerValue = 0;
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
      _userAnswerValue = parsed;
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
      correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
      correct ? _playCorrectSound() : _playWrongSound();
    }
  }

  void _toggleChart() {
    if (_showChart) {
      _chartAnim.reverse().then((_) => setState(() => _showChart = false));
    } else {
      setState(() => _showChart = true);
      _chartAnim.forward();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = _totalQuestions == 0
        ? 0.0
        : (_score / _totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
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
                        if (_showChart)
                          SlideTransition(
                            position: _chartSlide,
                            child: FadeTransition(
                              opacity: _chartFade,
                              child: _buildChart(),
                            ),
                          ),
                        if (_showChart) const SizedBox(height: 14),
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
              'Two-Digit Subtraction',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _isSoundEnabled ? _blue : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF333333)),
            tooltip: 'New Round',
            onPressed: () => _generateQuestion(),
          ),
          GestureDetector(
            onTap: _toggleChart,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _showChart ? _blue : const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _blue.withValues(alpha: 0.5)),
              ),
              child: Text(
                _showChart ? 'Hide Chart' : 'Show Chart',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _showChart ? Colors.white : _blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1–100 Chart ───────────────────────────────────────────────────────────────
  Widget _buildChart() {
    final showIntermediate =
        _isAnswered && _tensPart > 0 && _intermediate != _minuend;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1–100 Chart',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333))),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            itemCount: 100,
            itemBuilder: (context, index) {
              final n = index + 1;
              Color bg = const Color(0xFFE3F2FD);
              Color fg = const Color(0xFF333333);

              if (n == _minuend) {
                bg = const Color(0xFFFFF176); // yellow — start
              }
              if (_isAnswered) {
                if (showIntermediate && n == _intermediate) {
                  bg = const Color(0xFFFFCC80); // orange — after tens step
                  fg = const Color(0xFF333333);
                }
                if (n == _correctAnswer) {
                  bg = const Color(0xFFA5D6A7); // green — answer
                  fg = Colors.white;
                }
                if (!_isCorrect &&
                    n == _userAnswerValue &&
                    _userAnswerValue >= 1 &&
                    _userAnswerValue <= 100) {
                  bg = const Color(0xFFEF9A9A); // red — wrong answer
                  fg = Colors.white;
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Center(
                  child: Text('$n',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: fg)),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _Legend(
                  color: const Color(0xFFFFF176),
                  label: 'Start ($_minuend)'),
              if (_isAnswered && showIntermediate)
                _Legend(
                    color: const Color(0xFFFFCC80),
                    label: 'After tens (−$_tensPart)'),
              _Legend(
                  color: const Color(0xFFA5D6A7),
                  label: 'Answer'),
              if (_isAnswered &&
                  !_isCorrect &&
                  _userAnswerValue >= 1 &&
                  _userAnswerValue <= 100)
                _Legend(
                    color: const Color(0xFFEF9A9A),
                    label: 'Your answer ($_userAnswerValue)'),
            ],
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
              color: _blue,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: const Border(top: BorderSide(color: _blue, width: 6)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, 5))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        children: [
          Text(
            '$_minuend − $_subtrahend = ?',
            style: const TextStyle(
              fontSize: 48,
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
                          fontSize: 15,
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
                borderSide:
                    const BorderSide(color: _blue, width: 2.5)),
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
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: _blue.withValues(alpha: 0.4),
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
              _explanationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4),
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
      barColor = _blue;
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
                    color: _blue),
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
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF1976D2).withValues(alpha: 0.35), width: 1.5),
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
                      'Two-Digit Subtraction Trick',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D47A1)),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF1976D2),
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
                      'Split the number you\'re subtracting into tens and ones. Subtract the tens first, then the ones!',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1565C0),
                          height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '75 − 32  →  75 − 30 = 45, then 45 − 2 = 43',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D47A1)),
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

// ── Shared helpers ────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Color(0xFF757575))),
      ],
    );
  }
}

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
