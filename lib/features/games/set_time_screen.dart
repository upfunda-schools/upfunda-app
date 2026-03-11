import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SetTimeScreen extends StatefulWidget {
  const SetTimeScreen({super.key});

  @override
  State<SetTimeScreen> createState() => _SetTimeScreenState();
}

class _SetTimeScreenState extends State<SetTimeScreen>
    with TickerProviderStateMixin {
  // ── Target time ──────────────────────────────────────────────────────────────
  int _targetHour = 3;
  int _targetMinute = 30;

  // ── Clock hand state ─────────────────────────────────────────────────────────
  int _clockHour = 12;
  int _clockMinute = 0;
  bool _isDraggingHour = false;
  bool _isDraggingMinute = false;

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

  // ── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _pulseAnim;
  late final AnimationController _feedbackBounceAnim;
  late final AnimationController _feedbackShakeAnim;

  // ── Clock geometry (viewbox = 280 × 280) ─────────────────────────────────────
  static const double _kVB = 280.0;
  static const Offset _kC = Offset(140, 140); // center
  static const double _kR = 130.0; // clock radius
  static const double _kHourLen = 72.0;
  static const double _kMinLen = 104.0;
  static const double _kHandleR = 13.0;
  static const double _kNumR = 98.0;

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

    _generateQuestion();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _pulseAnim.dispose();
    _feedbackBounceAnim.dispose();
    _feedbackShakeAnim.dispose();
    super.dispose();
  }

  // ── Geometry helpers ─────────────────────────────────────────────────────────

  double get _hourAngleRad {
    final h = _clockHour % 12;
    return (h * 30 + _clockMinute * 0.5) * pi / 180;
  }

  double get _minuteAngleRad => _clockMinute * 6.0 * pi / 180;

  Offset _tipAt(double angleRad, double len) => Offset(
        _kC.dx + len * sin(angleRad),
        _kC.dy - len * cos(angleRad),
      );

  Offset get _hourTip => _tipAt(_hourAngleRad, _kHourLen);
  Offset get _minuteTip => _tipAt(_minuteAngleRad, _kMinLen);

  // ── Clock drag handling ───────────────────────────────────────────────────────

  // Pointer-based drag (bypasses ScrollView gesture arena)
  void _onPointerDown(PointerDownEvent e, double scale) {
    final local = Offset(e.localPosition.dx / scale, e.localPosition.dy / scale);
    final dH = (local - _hourTip).distance;
    final dM = (local - _minuteTip).distance;
    const hitSlop = _kHandleR + 14;
    setState(() {
      if (dH <= hitSlop && dH <= dM) {
        _isDraggingHour = true;
      } else if (dM <= hitSlop) {
        _isDraggingMinute = true;
      }
    });
  }

  void _onPointerMove(PointerMoveEvent e, double scale) {
    if (!_isDraggingHour && !_isDraggingMinute) return;
    final local = Offset(e.localPosition.dx / scale, e.localPosition.dy / scale);
    double angle =
        atan2(local.dy - _kC.dy, local.dx - _kC.dx) * (180 / pi) + 90;
    if (angle < 0) angle += 360;

    setState(() {
      if (_isDraggingHour) {
        int h = (angle / 30).round() % 12;
        if (h == 0) h = 12;
        _clockHour = h;
      } else {
        final raw = (angle / 6).round() % 60;
        final idx = ((raw / 15).round()) % 4;
        _clockMinute = [0, 15, 30, 45][idx];
      }
    });
  }

  void _onPointerUp(PointerUpEvent _) =>
      setState(() { _isDraggingHour = false; _isDraggingMinute = false; });

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
      _clockHour = 12;
      _clockMinute = 0;
      _isDraggingHour = false;
      _isDraggingMinute = false;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });
  }

  void _checkAnswer() {
    if (_isAnswered) return;
    _playTapSound();

    final correct = _clockHour == _targetHour && _clockMinute == _targetMinute;

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
        _feedbackMessage = _incorrectMsgs[_random.nextInt(_incorrectMsgs.length)];
        _feedbackShakeAnim.forward(from: 0);
      }
    });

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
      } else if (i > n - fade) env = (n - i) / fade;
      final s = (sin(2 * pi * hz * i / sr) * amp * env)
          .round()
          .clamp(-32768, 32767);
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

  // ── Formatting ───────────────────────────────────────────────────────────────

  String _fmt(int h, int m) => '$h:${m.toString().padLeft(2, '0')}';
  String get _currentTimeStr => _fmt(_clockHour, _clockMinute);
  String get _targetTimeStr => _fmt(_targetHour, _targetMinute);

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
            child: Text('Set the Time',
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
              color:
                  _isSoundEnabled ? const Color(0xFF7C3AED) : Colors.grey,
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

  // ── Clock section ────────────────────────────────────────────────────────────

  Widget _buildClockSection() {
    return Column(
      children: [
        LayoutBuilder(builder: (ctx, c) {
          final size = min(c.maxWidth, 300.0);
          final scale = size / _kVB;
          return SizedBox(
            width: size,
            height: size,
            child: Listener(
              onPointerDown: (e) => _onPointerDown(e, scale),
              onPointerMove: (e) => _onPointerMove(e, scale),
              onPointerUp: _onPointerUp,
              child: CustomPaint(
                size: Size(size, size),
                painter: _ClockPainter(
                  clockHour: _clockHour,
                  clockMinute: _clockMinute,
                  isDraggingHour: _isDraggingHour,
                  isDraggingMinute: _isDraggingMinute,
                  numberBgColors: _numberBgColors,
                  scale: scale,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              Text('🕐 Drag the hands to set the time!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7C3AED))),
              SizedBox(height: 4),
              Text('Blue = Hours   •   Green = Minutes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            ],
          ),
        ),
      ],
    );
  }

  // ── Question panel ───────────────────────────────────────────────────────────

  Widget _buildQuestionPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pulsing question card
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) {
            final s = 1.0 + 0.025 * sin(_pulseAnim.value * pi);
            return Transform.scale(scale: s, child: child);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Column(
              children: [
                const Text('Set the clock to',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  _targetTimeStr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Live current time readout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.25), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Current Time: ',
                  style: TextStyle(fontSize: 15, color: Color(0xFF9E9E9E))),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  _currentTimeStr,
                  key: ValueKey(_currentTimeStr),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Check button or feedback card
        if (!_isAnswered) _buildCheckButton() else _buildFeedbackCard(),
      ],
    );
  }

  Widget _buildCheckButton() {
    return GestureDetector(
      onTap: _checkAnswer,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.32),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎯 ', style: TextStyle(fontSize: 22)),
            Text('Check My Time!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
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
              color: accent.withOpacity(0.28),
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
          Text('Next question in 3 s — or tap below',
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withOpacity(0.8))),
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
          final x =
              sin(_feedbackShakeAnim.value * pi * 5) * 10 *
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
      label: const Text('Reset Game',
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

// ── Clock painter ─────────────────────────────────────────────────────────────

class _ClockPainter extends CustomPainter {
  final int clockHour;
  final int clockMinute;
  final bool isDraggingHour;
  final bool isDraggingMinute;
  final List<Color> numberBgColors;
  final double scale;

  const _ClockPainter({
    required this.clockHour,
    required this.clockMinute,
    required this.isDraggingHour,
    required this.isDraggingMinute,
    required this.numberBgColors,
    required this.scale,
  });

  static const Offset _c = Offset(140, 140);
  static const double _r = 130.0;
  static const double _hourLen = 72.0;
  static const double _minLen = 104.0;
  static const double _handleR = 13.0;
  static const double _numR = 98.0;

  double get _hourAngle {
    final h = clockHour % 12;
    return (h * 30 + clockMinute * 0.5) * pi / 180;
  }

  double get _minAngle => clockMinute * 6.0 * pi / 180;

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
    _drawHand(canvas, _tip(_minAngle, _minLen), _minLen,
        color: isDraggingMinute
            ? const Color(0xFFFF4081)
            : const Color(0xFF388E3C),
        width: 5.5,
        handleColor: isDraggingMinute
            ? const Color(0xFFFF80AB)
            : const Color(0xFF66BB6A));
    _drawHand(canvas, _tip(_hourAngle, _hourLen), _hourLen,
        color: isDraggingHour
            ? const Color(0xFFFF9800)
            : const Color(0xFF1565C0),
        width: 8.5,
        handleColor: isDraggingHour
            ? const Color(0xFFFFB74D)
            : const Color(0xFF42A5F5));
    _drawCenter(canvas);

    canvas.restore();
  }

  void _drawFace(Canvas canvas) {
    // Drop shadow
    canvas.drawCircle(
        _c + const Offset(0, 3),
        _r + 2,
        Paint()
          ..color = const Color(0xFF7C3AED).withOpacity(0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    // White fill
    canvas.drawCircle(_c, _r, Paint()..color = Colors.white);
    // Purple border
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
              ? const Color(0xFF7C3AED).withOpacity(0.45)
              : const Color(0xFF9E9E9E).withOpacity(0.35)
          ..strokeWidth = isHour ? 2.5 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSmiley(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF7C3AED).withOpacity(0.13);
    // Eyes
    canvas.drawCircle(Offset(_c.dx - 26, _c.dy - 30), 5.5, paint);
    canvas.drawCircle(Offset(_c.dx + 26, _c.dy - 30), 5.5, paint);
    // Smile
    final path = Path()
      ..moveTo(_c.dx - 30, _c.dy + 20)
      ..quadraticBezierTo(_c.dx, _c.dy + 46, _c.dx + 30, _c.dy + 20);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF7C3AED).withOpacity(0.13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
  }

  void _drawNumbers(Canvas canvas) {
    for (int i = 1; i <= 12; i++) {
      final angle = i * 30.0 * pi / 180;
      final pos = Offset(
          _c.dx + _numR * sin(angle), _c.dy - _numR * cos(angle));
      // Pastel background
      canvas.drawCircle(
          pos,
          16.5,
          Paint()..color = numberBgColors[(i - 1) % numberBgColors.length]);
      // Purple stroke
      canvas.drawCircle(
          pos,
          16.5,
          Paint()
            ..color = const Color(0xFF7C3AED).withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      // Number
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

  void _drawHand(Canvas canvas, Offset tip, double len,
      {required Color color,
      required double width,
      required Color handleColor}) {
    // Hand line
    canvas.drawLine(
        _c,
        tip,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
    // Handle circle at tip
    canvas.drawCircle(tip, _handleR, Paint()..color = handleColor);
    canvas.drawCircle(
        tip,
        _handleR,
        Paint()
          ..color = Colors.white.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
    canvas.drawCircle(tip, 4, Paint()..color = Colors.white);
  }

  void _drawCenter(Canvas canvas) {
    canvas.drawCircle(_c, 12, Paint()..color = const Color(0xFF7C3AED));
    canvas.drawCircle(_c, 8, Paint()..color = Colors.white);
    canvas.drawCircle(_c, 4, Paint()..color = const Color(0xFFEC4899));
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.clockHour != clockHour ||
      old.clockMinute != clockMinute ||
      old.isDraggingHour != isDraggingHour ||
      old.isDraggingMinute != isDraggingMinute;
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
