import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ReadTimeScreen extends StatefulWidget {
  const ReadTimeScreen({super.key});

  @override
  State<ReadTimeScreen> createState() => _ReadTimeScreenState();
}

class _ReadTimeScreenState extends State<ReadTimeScreen>
    with TickerProviderStateMixin {
  // ── Question state ───────────────────────────────────────────────────────────
  int _targetHour = 3;
  int _targetMinute = 30;

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

  Timer? _feedbackTimer;
  final Random _random = Random();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // ── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _pulseAnim;
  late final AnimationController _feedbackBounceAnim;
  late final AnimationController _feedbackShakeAnim;

  // ── Clock geometry (viewbox = 280 × 280) ─────────────────────────────────────
  static const double _kVB = 280.0;

  static const _numberBgColors = [
    Color(0xFFFFCDD2), Color(0xFFE1BEE7), Color(0xFFBBDEFB),
    Color(0xFFC8E6C9), Color(0xFFFFF9C4), Color(0xFFFFCCBC),
    Color(0xFFB2EBF2), Color(0xFFD1C4E9), Color(0xFFDCEDC8),
    Color(0xFFFFE0B2), Color(0xFFF8BBD0), Color(0xFFB3E5FC),
  ];

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
    _pulseAnim = AnimationController(
        duration: const Duration(milliseconds: 1600), vsync: this)
      ..repeat(reverse: true);
    _feedbackBounceAnim = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _feedbackShakeAnim = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _inputController.addListener(() => setState(() {}));
    _generateQuestion();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _pulseAnim.dispose();
    _feedbackBounceAnim.dispose();
    _feedbackShakeAnim.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Input parsing ────────────────────────────────────────────────────────────

  /// Normalises freeform input to "H:MM" so we can compare to _targetStr.
  String _normalise(String raw) {
    final s = raw.replaceAll(' ', '').trim();
    if (s.contains(':')) return s; // already has separator

    // digits only — try to split into hour + minutes
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 3) {
      // e.g. "330" → hour=3, min=30
      final h = int.tryParse(digits[0]);
      final m = int.tryParse(digits.substring(1));
      if (h != null && m != null && h >= 1 && h <= 9 && m >= 0 && m <= 59) {
        return '$h:${m.toString().padLeft(2, '0')}';
      }
    } else if (digits.length == 4) {
      // e.g. "1130" → hour=11, min=30
      final h = int.tryParse(digits.substring(0, 2));
      final m = int.tryParse(digits.substring(2));
      if (h != null && m != null && h >= 1 && h <= 12 && m >= 0 && m <= 59) {
        return '$h:${m.toString().padLeft(2, '0')}';
      }
    }
    return s; // return as-is; will not match target
  }

  // ── Game logic ───────────────────────────────────────────────────────────────

  void _generateQuestion() {
    _feedbackTimer?.cancel();
    _feedbackBounceAnim.reset();
    _feedbackShakeAnim.reset();

    final hour = _random.nextInt(12) + 1;
    final minute = [0, 15, 30, 45][_random.nextInt(4)];

    setState(() {
      _targetHour = hour;
      _targetMinute = minute;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });
    _inputController.clear();
  }

  void _checkAnswer() {
    if (_isAnswered) return;
    final raw = _inputController.text;
    if (raw.trim().isEmpty) return;

    _playTapSound();
    final normalised = _normalise(raw);
    final correct = normalised == _targetStr;

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
        _feedbackBounceAnim.forward(from: 0);
      } else {
        _streak = 0;
        _streakKey++;
        _feedbackMessage =
            _incorrectMsgs[_random.nextInt(_incorrectMsgs.length)];
        _feedbackShakeAnim.forward(from: 0);
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
      _score = 0; _totalQuestions = 0;
      _streak = 0; _bestStreak = 0;
      _scoreKey = 0; _streakKey = 0;
    });
    _generateQuestion();
  }

  String get _targetStr =>
      '$_targetHour:${_targetMinute.toString().padLeft(2, '0')}';

  // ── Sound synthesis ──────────────────────────────────────────────────────────

  static Uint8List _makeToneWav(double hz, int durMs, double vol) {
    const sr = 44100;
    final n = (sr * durMs / 1000).round();
    final buf = ByteData(44 + n * 2);
    final bytes = buf.buffer.asUint8List();
    bytes.setRange(0, 4, [0x52, 0x49, 0x46, 0x46]);
    buf.setInt32(4, 36 + n * 2, Endian.little);
    bytes.setRange(8, 12, [0x57, 0x41, 0x56, 0x45]);
    bytes.setRange(12, 16, [0x66, 0x6D, 0x74, 0x20]);
    buf.setInt32(16, 16, Endian.little);
    buf.setInt16(20, 1, Endian.little);
    buf.setInt16(22, 1, Endian.little);
    buf.setInt32(24, sr, Endian.little);
    buf.setInt32(28, sr * 2, Endian.little);
    buf.setInt16(32, 2, Endian.little);
    buf.setInt16(34, 16, Endian.little);
    bytes.setRange(36, 40, [0x64, 0x61, 0x74, 0x61]);
    buf.setInt32(40, n * 2, Endian.little);
    final amp = (32767 * vol).round();
    final fade = (sr * 0.02).round();
    for (int i = 0; i < n; i++) {
      double env = 1.0;
      if (i < fade) {
        env = i / fade;
      } else if (i > n - fade) {
        env = (n - i) / fade;
      }
      final s = (sin(2 * pi * hz * i / sr) * amp * env)
          .round().clamp(-32768, 32767);
      buf.setInt16(44 + i * 2, s, Endian.little);
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final progress = _totalQuestions == 0
        ? 0.0
        : (_score / _totalQuestions).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildScoreRow(),
                    const SizedBox(height: 20),
                    LayoutBuilder(builder: (ctx, c) {
                      if (c.maxWidth >= 580) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildClockSection()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildQuestionPanel()),
                          ],
                        );
                      }
                      return Column(children: [
                        _buildClockSection(),
                        const SizedBox(height: 20),
                        _buildQuestionPanel(),
                      ]);
                    }),
                    const SizedBox(height: 24),
                    _buildProgressBar(progress),
                    const SizedBox(height: 16),
                    _buildResetButton(),
                  ],
                ),
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
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF333333)),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text('Read the Time',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333))),
          ),
          IconButton(
            icon: Icon(
              _isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _isSoundEnabled
                  ? const Color(0xFF7C3AED)
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
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCell(
              label: 'Score',
              value: '$_score / $_totalQuestions',
              color: const Color(0xFF7C3AED),
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

  // ── Clock section (display only) ─────────────────────────────────────────────

  Widget _buildClockSection() {
    return LayoutBuilder(builder: (ctx, c) {
      final size = min(c.maxWidth, 300.0);
      final scale = size / _kVB;
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _StaticClockPainter(
            hour: _targetHour,
            minute: _targetMinute,
            numberBgColors: _numberBgColors,
            scale: scale,
          ),
        ),
      );
    });
  }

  // ── Question panel ───────────────────────────────────────────────────────────

  Widget _buildQuestionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pulsing prompt
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) {
            final s = 1.0 + 0.025 * sin(_pulseAnim.value * pi);
            return Transform.scale(scale: s, child: child);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ],
            ),
            child: const Text(
              'What time is shown\non this clock?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.35),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Input field
        TextField(
          controller: _inputController,
          focusNode: _focusNode,
          enabled: !_isAnswered,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d: ]')),
          ],
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: 'e.g.  3:30',
            hintStyle:
                TextStyle(fontSize: 17, color: Colors.grey.shade400),
            filled: true,
            fillColor: _isAnswered
                ? (_isCorrect
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE))
                : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 2.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: _isCorrect
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                  width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
          onSubmitted: (_) => _checkAnswer(),
        ),
        const SizedBox(height: 16),

        // Submit button or feedback card
        if (!_isAnswered)
          _buildSubmitButton()
        else
          _buildFeedbackCard(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final hasInput = _inputController.text.trim().isNotEmpty;
    return GestureDetector(
      onTap: hasInput ? _checkAnswer : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: hasInput
              ? const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: hasInput ? null : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: hasInput
              ? [
                  BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🕐 ',
                style: TextStyle(
                    fontSize: 22,
                    color: hasInput ? null : Colors.grey)),
            Text('Submit Answer',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        hasInput ? Colors.white : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    final grad = _isCorrect
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFFFF5722), const Color(0xFFEC4899)];
    final accent =
        _isCorrect ? const Color(0xFF10B981) : const Color(0xFFFF5722);

    // Show correct answer on wrong
    final subtitle = _isCorrect
        ? 'Next question in 3 s — or tap below'
        : 'The answer was $_targetStr  •  Next in 3 s';

    Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Text(_feedbackMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Next Question →',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    if (_isCorrect) {
      return AnimatedBuilder(
        animation: CurvedAnimation(
            parent: _feedbackBounceAnim, curve: Curves.easeOutBack),
        builder: (_, child) => Transform.translate(
          offset: Offset(0, (1 - _feedbackBounceAnim.value) * 40),
          child: Opacity(
              opacity: _feedbackBounceAnim.value.clamp(0.0, 1.0),
              child: child),
        ),
        child: card,
      );
    } else {
      return AnimatedBuilder(
        animation: _feedbackShakeAnim,
        builder: (_, child) {
          final x = sin(_feedbackShakeAnim.value * pi * 5) *
              10 *
              (1 - _feedbackShakeAnim.value);
          return Transform.translate(offset: Offset(x, 0), child: child);
        },
        child: card,
      );
    }
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────

  Widget _buildProgressBar(double progress) {
    final Color bar = progress >= 0.8
        ? const Color(0xFF4CAF50)
        : progress >= 0.5
            ? const Color(0xFF7C3AED)
            : const Color(0xFFF44336);
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
                    color: Color(0xFF7C3AED)),
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
              valueColor: AlwaysStoppedAnimation<Color>(bar),
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
        foregroundColor: const Color(0xFF7C3AED),
        side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Static clock painter (display only — no drag handles) ─────────────────────

class _StaticClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final List<Color> numberBgColors;
  final double scale;

  const _StaticClockPainter({
    required this.hour,
    required this.minute,
    required this.numberBgColors,
    required this.scale,
  });

  static const Offset _c = Offset(140, 140);
  static const double _r = 130.0;
  static const double _hourLen = 72.0;
  static const double _minLen = 104.0;
  static const double _numR = 98.0;

  double get _hourAngle {
    final h = hour % 12;
    return (h * 30 + minute * 0.5) * pi / 180;
  }

  double get _minAngle => minute * 6.0 * pi / 180;

  Offset _tip(double rad, double len) =>
      Offset(_c.dx + len * sin(rad), _c.dy - len * cos(rad));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale, scale);

    _drawFace(canvas);
    _drawTicks(canvas);
    _drawSmiley(canvas);
    _drawNumbers(canvas);
    // Minute hand first so hour sits on top
    _drawHand(canvas, _tip(_minAngle, _minLen),
        color: const Color(0xFF388E3C), width: 5.5);
    _drawHand(canvas, _tip(_hourAngle, _hourLen),
        color: const Color(0xFF1565C0), width: 8.5);
    _drawCenter(canvas);

    canvas.restore();
  }

  void _drawFace(Canvas canvas) {
    canvas.drawCircle(
        _c + const Offset(0, 3),
        _r + 2,
        Paint()
          ..color = const Color(0xFF7C3AED).withValues(alpha: 0.13)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(
        _c,
        _r,
        Paint()
          ..color = const Color(0xFF7C3AED)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5);
  }

  void _drawTicks(Canvas canvas) {
    for (int i = 0; i < 60; i++) {
      final angle = i * 6.0 * pi / 180;
      final isHour = i % 5 == 0;
      final outer = _r - 4;
      final inner = isHour ? _r - 16 : _r - 10;
      canvas.drawLine(
        Offset(_c.dx + outer * sin(angle), _c.dy - outer * cos(angle)),
        Offset(_c.dx + inner * sin(angle), _c.dy - inner * cos(angle)),
        Paint()
          ..color = isHour
              ? const Color(0xFF7C3AED).withValues(alpha: 0.45)
              : const Color(0xFF9E9E9E).withValues(alpha: 0.35)
          ..strokeWidth = isHour ? 2.5 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSmiley(Canvas canvas) {
    final fill = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: 0.13);
    canvas.drawCircle(Offset(_c.dx - 26, _c.dy - 30), 5.5, fill);
    canvas.drawCircle(Offset(_c.dx + 26, _c.dy - 30), 5.5, fill);
    final path = Path()
      ..moveTo(_c.dx - 30, _c.dy + 20)
      ..quadraticBezierTo(_c.dx, _c.dy + 46, _c.dx + 30, _c.dy + 20);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF7C3AED).withValues(alpha: 0.13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
  }

  void _drawNumbers(Canvas canvas) {
    for (int i = 1; i <= 12; i++) {
      final angle = i * 30.0 * pi / 180;
      final pos =
          Offset(_c.dx + _numR * sin(angle), _c.dy - _numR * cos(angle));
      canvas.drawCircle(
          pos,
          16.5,
          Paint()
            ..color = numberBgColors[(i - 1) % numberBgColors.length]);
      canvas.drawCircle(
          pos,
          16.5,
          Paint()
            ..color = const Color(0xFF7C3AED).withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      final tp = TextPainter(
        text: TextSpan(
            text: '$i',
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawHand(Canvas canvas, Offset tip,
      {required Color color, required double width}) {
    canvas.drawLine(
        _c,
        tip,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
    // Round cap tip decoration
    canvas.drawCircle(tip, width / 2, Paint()..color = color);
  }

  void _drawCenter(Canvas canvas) {
    canvas.drawCircle(_c, 12, Paint()..color = const Color(0xFF7C3AED));
    canvas.drawCircle(_c, 8, Paint()..color = Colors.white);
    canvas.drawCircle(_c, 4, Paint()..color = const Color(0xFFEC4899));
  }

  @override
  bool shouldRepaint(_StaticClockPainter old) =>
      old.hour != hour || old.minute != minute;
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
    return Column(children: [
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
    ]);
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
}
