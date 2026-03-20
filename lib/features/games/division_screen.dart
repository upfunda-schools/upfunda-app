import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DivisionScreen extends StatefulWidget {
  const DivisionScreen({super.key});

  @override
  State<DivisionScreen> createState() => _DivisionScreenState();
}

class _DivisionScreenState extends State<DivisionScreen>
    with TickerProviderStateMixin {
  // ── Question state ───────────────────────────────────────────────────────────
  int _divisor = 4;
  int _quotient = 9;
  int _dividend = 36;

  // ── Game state ───────────────────────────────────────────────────────────────
  bool _isAnswered = false;
  bool _isCorrect = false;
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

  // ── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

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

    _answerController.addListener(() => setState(() {}));
    _generateQuestion();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _questionAnim.dispose();
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

    bytes.setRange(0, 4, [0x52, 0x49, 0x46, 0x46]);
    buffer.setInt32(4, 36 + numSamples * 2, Endian.little);
    bytes.setRange(8, 12, [0x57, 0x41, 0x56, 0x45]);
    bytes.setRange(12, 16, [0x66, 0x6D, 0x74, 0x20]);
    buffer.setInt32(16, 16, Endian.little);
    buffer.setInt16(20, 1, Endian.little);
    buffer.setInt16(22, 1, Endian.little);
    buffer.setInt32(24, sampleRate, Endian.little);
    buffer.setInt32(28, sampleRate * 2, Endian.little);
    buffer.setInt16(32, 2, Endian.little);
    buffer.setInt16(34, 16, Endian.little);
    bytes.setRange(36, 40, [0x64, 0x61, 0x74, 0x61]);
    buffer.setInt32(40, numSamples * 2, Endian.little);

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

  Future<void> _playCorrectSound() async {
    if (!_isSoundEnabled) return;
    for (final hz in [523.25, 659.25, 783.99]) {
      final p = AudioPlayer();
      await p.play(BytesSource(_makeToneWav(hz, 180, 0.08)));
      await Future.delayed(const Duration(milliseconds: 210));
      p.dispose();
    }
  }

  Future<void> _playWrongSound() async {
    if (!_isSoundEnabled) return;
    for (final hz in [350.0, 220.0]) {
      final p = AudioPlayer();
      await p.play(BytesSource(_makeToneWav(hz, 260, 0.06)));
      await Future.delayed(const Duration(milliseconds: 290));
      p.dispose();
    }
  }

  void _playTapSound() {
    if (!_isSoundEnabled) return;
    final p = AudioPlayer();
    p.play(BytesSource(_makeToneWav(800.0, 55, 0.05)));
    Future.delayed(const Duration(milliseconds: 300), p.dispose);
  }

  // ── Game logic ───────────────────────────────────────────────────────────────

  void _generateQuestion() {
    _feedbackTimer?.cancel();
    final divisor = _random.nextInt(12) + 1;
    final quotient = _random.nextInt(12) + 1;

    setState(() {
      _divisor = divisor;
      _quotient = quotient;
      _dividend = divisor * quotient;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });

    _answerController.clear();
    _questionAnim.forward(from: 0);
  }

  void _checkAnswer() {
    final userAnswer = int.tryParse(_answerController.text.trim());
    if (userAnswer == null || _isAnswered) return;

    _playTapSound();
    final correct = userAnswer == _quotient;

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

    _focusNode.unfocus();
    if (correct) {
      _playCorrectSound();
    } else {
      _playWrongSound();
    }

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
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildScoreRow(),
                        const SizedBox(height: 24),
                        SlideTransition(
                          position: _questionSlide,
                          child: FadeTransition(
                            opacity: _questionFade,
                            child: _buildQuestionCard(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildAnswerField(),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                hasInput && !_isAnswered ? _checkAnswer : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F51B5),
                              disabledBackgroundColor:
                                  const Color(0xFFC5CAE9),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white60,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            child: const Text('Check Answer',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildProgressBar(progress),
                        const SizedBox(height: 20),
                        _buildResetButton(),
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
              'Division',
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
                  ? const Color(0xFF3F51B5)
                  : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
        ],
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
              color: const Color(0xFF3F51B5),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF3F51B5), width: 2.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF3F51B5).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Division symbol decoration
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('÷',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3F51B5))),
            ),
          ),
          Text(
            '$_dividend ÷ $_divisor = ?',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A237E),
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3F51B5).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'How many times does $_divisor go into $_dividend?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3F51B5)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Answer field ─────────────────────────────────────────────────────────────

  Widget _buildAnswerField() {
    final borderColor = _isAnswered
        ? (_isCorrect
            ? const Color(0xFF4CAF50)
            : const Color(0xFFF44336))
        : const Color(0xFF3F51B5);

    return TextField(
      controller: _answerController,
      focusNode: _focusNode,
      enabled: !_isAnswered,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A237E)),
      decoration: InputDecoration(
        hintText: 'Your answer…',
        hintStyle: TextStyle(fontSize: 16, color: Colors.grey.shade400),
        filled: true,
        fillColor: _isAnswered
            ? (_isCorrect
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE))
            : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF3F51B5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF3F51B5), width: 2.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
      onSubmitted: (_) => _checkAnswer(),
    );
  }

  // ── Feedback banner ──────────────────────────────────────────────────────────

  Widget _buildFeedbackBanner() {
    final bg =
        _isCorrect ? const Color(0xFF43A047) : const Color(0xFFFF5722);
    final explanation =
        '$_dividend ÷ $_divisor = $_quotient  (because $_divisor × $_quotient = $_dividend)';

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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Next question in 3 s — or tap below',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
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
      barColor = const Color(0xFF3F51B5);
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
                    color: Color(0xFF3F51B5)),
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
      label: const Text('Reset Game',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF3F51B5),
        side: const BorderSide(color: Color(0xFF3F51B5), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
