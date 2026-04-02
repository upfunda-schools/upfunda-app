import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Question model ────────────────────────────────────────────────────────────

enum _QType { to12, to24 }

class _Question {
  final _QType type;
  final String displayTime; // shown on clock
  final String questionText;
  final String answer; // correct answer (canonical)
  final String explanation;

  const _Question({
    required this.type,
    required this.displayTime,
    required this.questionText,
    required this.answer,
    required this.explanation,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TimeConversionScreen extends StatefulWidget {
  const TimeConversionScreen({super.key});

  @override
  State<TimeConversionScreen> createState() => _TimeConversionScreenState();
}

class _TimeConversionScreenState extends State<TimeConversionScreen>
    with TickerProviderStateMixin {
  // ── Question state ───────────────────────────────────────────────────────────
  _Question? _question;

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
  late final AnimationController _clockPulseAnim; // LED blink
  late final AnimationController _clockScaleAnim; // gentle scale loop
  late final AnimationController _questionPulseAnim; // prompt pulsing
  late final AnimationController _feedbackBounceAnim;
  late final AnimationController _feedbackShakeAnim;
  late final AnimationController _clockInAnim; // slide-in on new question

  final AudioPlayer _audioPlayer = AudioPlayer();

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

    _clockPulseAnim = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);

    _clockScaleAnim = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this)
      ..repeat(reverse: true);

    _questionPulseAnim = AnimationController(
        duration: const Duration(milliseconds: 1600), vsync: this)
      ..repeat(reverse: true);

    _feedbackBounceAnim = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);

    _feedbackShakeAnim = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    _clockInAnim = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);

    _inputController.addListener(() => setState(() {}));
    _generateQuestion();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _clockPulseAnim.dispose();
    _clockScaleAnim.dispose();
    _questionPulseAnim.dispose();
    _feedbackBounceAnim.dispose();
    _feedbackShakeAnim.dispose();
    _clockInAnim.dispose();
    _inputController.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Question generation ───────────────────────────────────────────────────────

  _Question _buildTo12Question() {
    final minutes = [0, 15, 30, 45];
    final h24 = _random.nextInt(24);
    final m = minutes[_random.nextInt(4)];
    final mm = m.toString().padLeft(2, '0');
    final hh = h24.toString().padLeft(2, '0');

    final int h12;
    final String period;
    if (h24 == 0) {
      h12 = 12;
      period = 'AM';
    } else if (h24 < 12) {
      h12 = h24;
      period = 'AM';
    } else if (h24 == 12) {
      h12 = 12;
      period = 'PM';
    } else {
      h12 = h24 - 12;
      period = 'PM';
    }
    final answer = '$h12:$mm $period';
    return _Question(
      type: _QType.to12,
      displayTime: '$hh:$mm',
      questionText: 'Convert to 12-hour format',
      answer: answer,
      explanation: '$hh:$mm = $answer',
    );
  }

  _Question _buildTo24Question() {
    final minutes = [0, 15, 30, 45];
    final h12 = _random.nextInt(12) + 1;
    final m = minutes[_random.nextInt(4)];
    final mm = m.toString().padLeft(2, '0');
    final period = _random.nextBool() ? 'AM' : 'PM';

    final int h24;
    if (period == 'AM') {
      h24 = h12 == 12 ? 0 : h12;
    } else {
      h24 = h12 == 12 ? 12 : h12 + 12;
    }
    final answer = '${h24.toString().padLeft(2, '0')}:$mm';
    return _Question(
      type: _QType.to24,
      displayTime: '$h12:$mm $period',
      questionText: 'Convert to 24-hour format',
      answer: answer,
      explanation: '$h12:$mm $period = $answer',
    );
  }

  void _generateQuestion() {
    _feedbackTimer?.cancel();
    _feedbackBounceAnim.reset();
    _feedbackShakeAnim.reset();

    final q = _random.nextBool() ? _buildTo12Question() : _buildTo24Question();

    setState(() {
      _question = q;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });

    _inputController.clear();
    _clockInAnim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  // ── Answer validation ────────────────────────────────────────────────────────

  String _normalise(String raw) {
    // Trim, collapse whitespace, uppercase AM/PM
    return raw
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toUpperCase()
        .replaceAll('A.M.', 'AM')
        .replaceAll('P.M.', 'PM');
  }

  void _checkAnswer() {
    if (_isAnswered || _question == null) return;
    final raw = _inputController.text;
    if (raw.trim().isEmpty) return;

    final correct =
        _normalise(raw) == _normalise(_question!.answer);

    if (correct) {
      _playCorrectSound();
    } else {
      _playWrongSound();
    }

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

  Future<void> _playCorrectSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/correct_sound_effect.mp3'));
    } catch (_) {}
  }

  Future<void> _playWrongSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/wrong_sound_effect.mp3'));
    } catch (_) {}
  }

  Future<void> _playTapSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/tap_sound_effect.mp3'));
    } catch (_) {}
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final q = _question;
    if (q == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                            Expanded(child: _buildClockSection(q)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildQuestionPanel(q)),
                          ],
                        );
                      }
                      return Column(children: [
                        _buildClockSection(q),
                        const SizedBox(height: 20),
                        _buildQuestionPanel(q),
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
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text('Time Conversion',
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

  // ── Digital clock section ────────────────────────────────────────────────────

  Widget _buildClockSection(_Question q) {
    final is24 = q.type == _QType.to12;
    final badgeColor = is24 ? const Color(0xFF2563EB) : const Color(0xFFEA580C);
    final badgeLabel = is24 ? '24-Hour Format' : '12-Hour Format';

    return AnimatedBuilder(
      animation: Listenable.merge([_clockScaleAnim, _clockInAnim]),
      builder: (_, child) {
        final scale = 0.985 + 0.015 * _clockScaleAnim.value;
        final slideY = (1 - CurvedAnimation(
                parent: _clockInAnim, curve: Curves.easeOutBack)
            .value) * 30;
        final opacity = _clockInAnim.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Column(
        children: [
          // Outer casing
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D2D2D), Color(0xFF0F0F0F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF444444), width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 24,
                    offset: const Offset(0, 8)),
                BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.06),
                    blurRadius: 30,
                    spreadRadius: 2),
              ],
            ),
            child: Column(
              children: [
                // Inner screen
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050505),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 12,
                          spreadRadius: -2,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _clockPulseAnim,
                    builder: (_, __) {
                      final opacity = 0.72 + 0.28 * _clockPulseAnim.value;
                      return Opacity(
                        opacity: opacity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            q.displayTime,
                            key: ValueKey(q.displayTime),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                              letterSpacing: 6,
                              shadows: [
                                Shadow(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.9),
                                    blurRadius: 18),
                                Shadow(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 40),
                                Shadow(
                                    color: const Color(0xFF34D399)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 60),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // Decorative dots row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 2
                            ? const Color(0xFF10B981).withValues(alpha: 0.8)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Format badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: badgeColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: badgeColor),
                const SizedBox(width: 6),
                Text(badgeLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: badgeColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Question panel ────────────────────────────────────────────────────────────

  Widget _buildQuestionPanel(_Question q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pulsing question prompt
        AnimatedBuilder(
          animation: _questionPulseAnim,
          builder: (_, child) {
            final s = 1.0 + 0.025 * sin(_questionPulseAnim.value * pi);
            return Transform.scale(scale: s, child: child);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                q.questionText,
                key: ValueKey(q.questionText),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Conversion reference chip
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                  width: 1.5),
            ),
            child: Text(
              q.type == _QType.to12
                  ? '0–11 → AM   •   12–23 → PM'
                  : 'AM+12 → 00:MM   •   PM+12 → add 12',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Input field
        TextField(
          controller: _inputController,
          focusNode: _focusNode,
          enabled: !_isAnswered,
          keyboardType: TextInputType.text,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d: AaMmPp.]')),
          ],
          style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText:
                q.type == _QType.to12 ? 'e.g.  3:30 PM' : 'e.g.  15:30',
            hintStyle:
                TextStyle(fontSize: 16, color: Colors.grey.shade400),
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

        // Submit or feedback
        if (!_isAnswered)
          _buildSubmitButton()
        else
          _buildFeedbackCard(q),
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
            Text('🎯  ',
                style: TextStyle(
                    fontSize: 20,
                    color: hasInput ? null : Colors.grey)),
            Text('Submit Answer!',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasInput
                        ? Colors.white
                        : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(_Question q) {
    final grad = _isCorrect
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : [const Color(0xFFFF5722), const Color(0xFFEC4899)];
    final accent =
        _isCorrect ? const Color(0xFF10B981) : const Color(0xFFFF5722);

    final subtitle = _isCorrect
        ? 'Next question in 3 s — or tap below'
        : '${q.explanation}  •  Next in 3 s';

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
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9))),
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
