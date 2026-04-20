import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoublesHalvesScreen extends StatefulWidget {
  const DoublesHalvesScreen({super.key});

  @override
  State<DoublesHalvesScreen> createState() => _DoublesHalvesScreenState();
}

class _DoublesHalvesScreenState extends State<DoublesHalvesScreen>
    with TickerProviderStateMixin {
  // ── Question state ───────────────────────────────────────────────────────────
  int _base1 = 16;
  int _base2 = 25;
  int _half1 = 8;
  int _double2 = 50;
  int _correctAnswer = 400;

  // ── Game state ───────────────────────────────────────────────────────────────
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isHintExpanded = true;
  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  int _bestStreak = 0;
  String _feedbackMessage = '';
  bool _isSoundEnabled = true;

  int _scoreKey = 0;
  int _streakKey = 0;

  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();
  Timer? _feedbackTimer;

  // ── Number pools ─────────────────────────────────────────────────────────────
  static const _base1Pool = [12, 14, 16, 18, 24, 26, 28, 32, 34, 36];
  static const _base2Pool = [25, 50, 75, 125, 250];

  // ── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  late final AnimationController _stepsAnim;
  late final Animation<double> _step1Reveal;
  late final Animation<double> _step2Reveal;
  late final Animation<double> _step3Reveal;

  // ── Messages ─────────────────────────────────────────────────────────────────
  static const _correctMsgs = [
    "Amazing! You're a math wizard! ✅",
    "Fantastic work! Keep going! ✅",
    "Brilliant! You're on fire! ✅",
    "Excellent! Math genius! ✅",
    "Wonderful! You've got this! ✅",
    "Magical! Perfect answer! ✅",
    "Bullseye! Great job! ✅",
    "Rainbow perfect! Amazing! ✅",
  ];
  static const _incorrectMsgs = [
    "Good try! Let's learn together!",
    "Almost there! Keep practicing!",
    "Great effort! Try again!",
    "You're learning! That's awesome!",
    "Creative thinking! Let's try again!",
    "Keep flowing! You'll get it!",
    "Nice attempt! Practice makes perfect!",
    "Dream big! Try once more!",
  ];

  // ── Step colors ──────────────────────────────────────────────────────────────
  static const _stepColors = [
    Color(0xFF0097A7),
    Color(0xFFFF7043),
    Color(0xFF43A047),
  ];

  // ── Lifecycle ────────────────────────────────────────────────────────────────
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

    _stepsAnim = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _step1Reveal = CurvedAnimation(
        parent: _stepsAnim,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut));
    _step2Reveal = CurvedAnimation(
        parent: _stepsAnim,
        curve: const Interval(0.30, 0.68, curve: Curves.easeOut));
    _step3Reveal = CurvedAnimation(
        parent: _stepsAnim,
        curve: const Interval(0.60, 1.00, curve: Curves.easeOut));

    _answerController.addListener(() => setState(() {}));
    _generateQuestion();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _questionAnim.dispose();
    _stepsAnim.dispose();
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Sound synthesis ──────────────────────────────────────────────────────────

  static Uint8List _makeToneWav(double hz, int durationMs, double vol) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final buffer = ByteData(44 + numSamples * 2);
    final bytes = buffer.buffer.asUint8List();

    // RIFF / WAVE header
    bytes.setRange(0, 4, [0x52, 0x49, 0x46, 0x46]); // 'RIFF'
    buffer.setInt32(4, 36 + numSamples * 2, Endian.little);
    bytes.setRange(8, 12, [0x57, 0x41, 0x56, 0x45]); // 'WAVE'
    bytes.setRange(12, 16, [0x66, 0x6D, 0x74, 0x20]); // 'fmt '
    buffer.setInt32(16, 16, Endian.little); // fmt chunk size
    buffer.setInt16(20, 1, Endian.little); // PCM
    buffer.setInt16(22, 1, Endian.little); // mono
    buffer.setInt32(24, sampleRate, Endian.little);
    buffer.setInt32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setInt16(32, 2, Endian.little); // block align
    buffer.setInt16(34, 16, Endian.little); // bits per sample
    bytes.setRange(36, 40, [0x64, 0x61, 0x74, 0x61]); // 'data'
    buffer.setInt32(40, numSamples * 2, Endian.little);

    // PCM samples with 20 ms linear fade-in / fade-out envelope
    final maxAmp = (32767 * vol).round();
    final fadeSamples = (sampleRate * 0.02).round();
    for (int i = 0; i < numSamples; i++) {
      double env = 1.0;
      if (i < fadeSamples) {
        env = i / fadeSamples;
      } else if (i > numSamples - fadeSamples) {
        env = (numSamples - i) / fadeSamples;
      }
      final t = i / sampleRate;
      final sample =
          (sin(2 * pi * hz * t) * maxAmp * env).round().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  // Correct: ascending chime C5 → E5 → G5
  Future<void> _playCorrectSound() async {
    if (!_isSoundEnabled) return;
    const tones = [523.25, 659.25, 783.99];
    for (final hz in tones) {
      final player = AudioPlayer();
      await player.play(BytesSource(_makeToneWav(hz, 180, 0.08)));
      await Future.delayed(const Duration(milliseconds: 210));
      player.dispose();
    }
  }

  // Wrong: gentle descending tones
  Future<void> _playWrongSound() async {
    if (!_isSoundEnabled) return;
    const tones = [350.0, 220.0];
    for (final hz in tones) {
      final player = AudioPlayer();
      await player.play(BytesSource(_makeToneWav(hz, 260, 0.06)));
      await Future.delayed(const Duration(milliseconds: 290));
      player.dispose();
    }
  }

  // Button tap: short click
  void _playTapSound() {
    if (!_isSoundEnabled) return;
    final player = AudioPlayer();
    player.play(BytesSource(_makeToneWav(800.0, 55, 0.05)));
    Future.delayed(const Duration(milliseconds: 300), player.dispose);
  }

  // ── Game logic ───────────────────────────────────────────────────────────────

  void _generateQuestion() {
    _feedbackTimer?.cancel();
    final b1 = _base1Pool[_random.nextInt(_base1Pool.length)];
    final b2 = _base2Pool[_random.nextInt(_base2Pool.length)];

    setState(() {
      _base1 = b1;
      _base2 = b2;
      _half1 = b1 ~/ 2;
      _double2 = b2 * 2;
      _correctAnswer = b1 * b2;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });

    _answerController.clear();
    _stepsAnim.reset();
    _questionAnim.forward(from: 0);
  }

  void _checkAnswer() {
    final userAnswer = int.tryParse(_answerController.text.trim());
    if (userAnswer == null || _isAnswered) return;

    _playTapSound();
    final correct = userAnswer == _correctAnswer;

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

    _stepsAnim.forward(from: 0);
    _focusNode.unfocus();

    if (correct) {
      _playCorrectSound();
    } else {
      _playWrongSound();
    }

    // Auto-dismiss after 3 seconds
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _generateQuestion();
    });
  }

  void _resetGame() {
    _playTapSound();
    _feedbackTimer?.cancel();
    setState(() {
      _score = 0;
      _totalQuestions = 0;
      _streak = 0;
      _bestStreak = 0;
      _scoreKey = 0;
      _streakKey = 0;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });
    _generateQuestion();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final progress = _totalQuestions == 0
        ? 0.0
        : (_score / _totalQuestions).clamp(0.0, 1.0);
    final hasInput = _answerController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F6),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHintCard(),
                        const SizedBox(height: 16),
                        _buildScoreRow(),
                        const SizedBox(height: 20),
                        SlideTransition(
                          position: _questionSlide,
                          child: FadeTransition(
                            opacity: _questionFade,
                            child: _buildQuestionCard(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnswerField(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                hasInput && !_isAnswered ? _checkAnswer : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009688),
                              disabledBackgroundColor:
                                  const Color(0xFFB2DFDB),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white60,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            child: const Text('Check Answer',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildProgressBar(progress),
                        const SizedBox(height: 20),
                        _buildResetButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Feedback banner (slides up from bottom)
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

  // ── Top bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
              'Doubles & Halves',
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
                  ? const Color(0xFF009688)
                  : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
        ],
      ),
    );
  }

  // ── Hint card ────────────────────────────────────────────────────────────────

  Widget _buildHintCard() {
    return GestureDetector(
      onTap: () => setState(() => _isHintExpanded = !_isHintExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9C4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF009688), width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Halving & Doubling Trick',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF004D40)),
                    ),
                  ),
                  Icon(
                    _isHintExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF009688),
                    size: 22,
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
                    Container(
                      height: 1,
                      color: const Color(0xFF009688).withValues(alpha: 0.2),
                      margin: const EdgeInsets.only(bottom: 10),
                    ),
                    const Text(
                      'Smart multiplication: halve one, double the other — the answer stays the same!',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF37474F)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009688).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '16 × 25  →  8 × 50 = 400',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004D40),
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isHintExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 260),
            ),
          ],
        ),
      ),
    );
  }

  // ── Score row ────────────────────────────────────────────────────────────────

  Widget _buildScoreRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCell(
              label: 'Score',
              value: '$_score / $_totalQuestions',
              color: const Color(0xFF009688),
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

  // ── Question card ────────────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF009688), width: 2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF009688).withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$_base1 × $_base2 = ?',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Color(0xFF263238),
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF009688).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Smart multiplication: halve one, double the other',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF009688)),
            ),
          ),
          if (_isAnswered) ...[
            const SizedBox(height: 20),
            _buildStepRow(
                stepNum: 1,
                formula: '$_base1 ÷ 2',
                result: '$_half1',
                reveal: _step1Reveal,
                color: _stepColors[0],
                hideResult: false),
            _buildStepRow(
                stepNum: 2,
                formula: '$_base2 × 2',
                result: '$_double2',
                reveal: _step2Reveal,
                color: _stepColors[1],
                hideResult: false),
            _buildStepRow(
                stepNum: 3,
                formula: '$_half1 × $_double2',
                result: '$_correctAnswer',
                reveal: _step3Reveal,
                color: _stepColors[2],
                hideResult: false),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required int stepNum,
    required String formula,
    required String result,
    required Animation<double> reveal,
    required Color color,
    required bool hideResult,
  }) {
    return AnimatedBuilder(
      animation: reveal,
      builder: (_, __) {
        final t = reveal.value;
        final bg =
            Color.lerp(const Color(0xFFF5F5F5), color.withValues(alpha: 0.10), t)!;
        final borderCol = Color.lerp(
            const Color(0xFFE0E0E0), color.withValues(alpha: 0.45), t)!;
        final textCol = Color.lerp(
            const Color(0xFFBDBDBD), const Color(0xFF424242), t)!;
        final resultCol =
            Color.lerp(const Color(0xFFBDBDBD), color, t)!;
        final badgeCol =
            Color.lerp(const Color(0xFFCFD8DC), color, t)!;

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderCol, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration:
                    BoxDecoration(color: badgeCol, shape: BoxShape.circle),
                child: Center(
                  child: Text('$stepNum',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '$formula = ',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textCol),
                    ),
                    Text(
                      hideResult ? '?' : result,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color:
                              hideResult ? const Color(0xFFBDBDBD) : resultCol),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Answer field ─────────────────────────────────────────────────────────────

  Widget _buildAnswerField() {
    final borderColor = _isAnswered
        ? (_isCorrect
            ? const Color(0xFF4CAF50)
            : const Color(0xFFF44336))
        : const Color(0xFF009688);

    return TextField(
      controller: _answerController,
      focusNode: _focusNode,
      enabled: !_isAnswered,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF263238)),
      decoration: InputDecoration(
        hintText: 'Type your answer…',
        hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade400),
        filled: true,
        fillColor: _isAnswered
            ? (_isCorrect
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE))
            : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF009688), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF009688), width: 2.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      onSubmitted: (_) => _checkAnswer(),
    );
  }

  // ── Feedback banner ──────────────────────────────────────────────────────────

  Widget _buildFeedbackBanner() {
    final bg =
        _isCorrect ? const Color(0xFF43A047) : const Color(0xFFFF5722);
    final explanation =
        '$_base1 × $_base2 = $_half1 × $_double2 = $_correctAnswer';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 14, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
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
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          // Always show the explanation step
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Next question in 3 s — or tap below',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateQuestion,
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

  // ── Progress bar ─────────────────────────────────────────────────────────────

  Widget _buildProgressBar(double progress) {
    final Color barColor;
    if (progress >= 0.8) {
      barColor = const Color(0xFF4CAF50);
    } else if (progress >= 0.5) {
      barColor = const Color(0xFF009688);
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
                    color: Color(0xFF009688)),
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

  // ── Reset button ─────────────────────────────────────────────────────────────

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _resetGame,
      icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text('New Round',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF009688),
        side: const BorderSide(color: Color(0xFF009688), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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
