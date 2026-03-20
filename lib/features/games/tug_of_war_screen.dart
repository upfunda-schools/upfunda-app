import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

enum _GamePhase { menu, playing, finished }
enum _Feedback { none, correct, wrong }

class _LevelInfo {
  final int level;
  final String name;
  final String ops; // display string
  const _LevelInfo(this.level, this.name, this.ops);
}

class _Question {
  final int num1, num2, answer;
  final String op, display;
  const _Question({
    required this.num1,
    required this.num2,
    required this.answer,
    required this.op,
    required this.display,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class TugOfWarScreen extends StatefulWidget {
  const TugOfWarScreen({super.key});
  @override
  State<TugOfWarScreen> createState() => _TugOfWarScreenState();
}

class _TugOfWarScreenState extends State<TugOfWarScreen>
    with TickerProviderStateMixin {
  static const _winScore = 7;

  static const _levels = [
    _LevelInfo(1, 'Easy Add',     '+'),
    _LevelInfo(2, 'Big Add',      '+'),
    _LevelInfo(3, 'Take Away',    '−'),
    _LevelInfo(4, 'Add & Sub',    '+  −'),
    _LevelInfo(5, 'Times ×2–5',  '×'),
    _LevelInfo(6, 'Times ×6–12', '×'),
    _LevelInfo(7, 'Division',     '÷'),
    _LevelInfo(8, 'All Ops',      '+ − × ÷'),
  ];

  // ── Game state ────────────────────────────────────────────────────────────
  _GamePhase _phase = _GamePhase.menu;
  int _level = 1;

  _Question? _question;
  int _p1Correct = 0;
  int _p2Correct = 0; // also used for AI score in vsAi mode

  String _p1Input = '';
  _Feedback _p1Fb = _Feedback.none;
  _Feedback _p2Fb = _Feedback.none;

  bool _p1Locked = false;
  bool _p2Locked = false;

  bool _aiThinking = false;
  String? _winner; // 'player' | 'ai'
  int _questionsAnswered = 0;
  bool _showInstructions = false;

  // Derived
  int get _ropePos => (_p2Correct - _p1Correct).clamp(-_winScore, _winScore);

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _lurchCtrl;
  int _lurchSign = 1;
  double get _lurchOffset {
    final v = _lurchCtrl.value;
    final peak = v < 0.4 ? v / 0.4 : (1 - v) / 0.6;
    return peak * 10 * _lurchSign;
  }

  late AnimationController _questionCtrl;
  bool _questionCorrect = false;

  // ── Timers ────────────────────────────────────────────────────────────────
  Timer? _aiTimer;
  Timer? _feedbackTimer;

  final _audio = AudioPlayer();
  final _random = Random();

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _lurchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(() => setState(() {}));

    _questionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _lurchCtrl.dispose();
    _questionCtrl.dispose();
    _aiTimer?.cancel();
    _feedbackTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  // ── Sounds ────────────────────────────────────────────────────────────────
  void _playSound(bool correct) async {
    try {
      await _audio.stop();
      await _audio.play(
        AssetSource(correct ? 'audio/correct.mp3' : 'audio/wrong.mp3'),
        volume: 0.5,
      );
    } catch (_) {}
  }

  // ── Game flow ─────────────────────────────────────────────────────────────
  void _startGame() {
    setState(() {
      _phase = _GamePhase.playing;
      _p1Correct = 0;
      _p2Correct = 0;
      _questionsAnswered = 0;
      _winner = null;
      _p1Input = '';
      _p1Fb = _Feedback.none;
      _p2Fb = _Feedback.none;
      _p1Locked = false;
      _p2Locked = false;
      _aiThinking = false;
    });
    _generateQuestion();
  }

  void _generateQuestion() {
    final q = _buildQuestion(_level);
    setState(() {
      _question = q;
      _questionsAnswered++;
      _p1Input = '';
      _p1Fb = _Feedback.none;
      _p2Fb = _Feedback.none;
      _p1Locked = false;
      _p2Locked = false;
    });
    _startAiTimer();
  }

  _Question _buildQuestion(int lvl) {
    final ops = switch (lvl) {
      1 => ['+'],
      2 => ['+'],
      3 => ['-'],
      4 => ['+', '-'],
      5 => ['×'],
      6 => ['×'],
      7 => ['÷'],
      _ => ['+', '-', '×', '÷'],
    };
    final op = ops[_random.nextInt(ops.length)];

    return switch (op) {
      '+'  => _makeAdd(lvl),
      '-'  => _makeSub(lvl),
      '×'  => _makeMul(lvl),
      _    => _makeDiv(lvl),
    };
  }

  _Question _makeAdd(int lvl) {
    final max = lvl <= 1 ? 10 : 20;
    final a = 1 + _random.nextInt(max);
    final b = 1 + _random.nextInt(max);
    return _Question(num1: a, num2: b, answer: a + b, op: '+', display: '$a + $b = ?');
  }

  _Question _makeSub(int lvl) {
    final max = lvl <= 3 ? 20 : 30;
    int a = 1 + _random.nextInt(max);
    int b = 1 + _random.nextInt(a); // b ≤ a ensures positive result
    return _Question(num1: a, num2: b, answer: a - b, op: '-', display: '$a − $b = ?');
  }

  _Question _makeMul(int lvl) {
    final tableMin = lvl <= 5 ? 2 : 6;
    final tableMax = lvl <= 5 ? 5 : 12;
    final a = tableMin + _random.nextInt(tableMax - tableMin + 1);
    final b = 1 + _random.nextInt(12);
    return _Question(num1: a, num2: b, answer: a * b, op: '×', display: '$a × $b = ?');
  }

  _Question _makeDiv(int lvl) {
    final divisor  = 2 + _random.nextInt(9);  // 2–10
    final quotient = 1 + _random.nextInt(10); // 1–10
    final dividend = divisor * quotient;
    return _Question(num1: dividend, num2: divisor, answer: quotient, op: '÷', display: '$dividend ÷ $divisor = ?');
  }

  // ── Answer submission ─────────────────────────────────────────────────────
  void _submitP1() {
    if (_p1Locked || _question == null) return;
    final ans = int.tryParse(_p1Input);
    if (ans == null) return;

    if (ans == _question!.answer) {
      _onCorrect(isPlayer1: true);
    } else {
      _onWrong(isPlayer1: true);
    }
  }

  void _onCorrect({required bool isPlayer1}) {
    _playSound(true);
    _lurchSign = isPlayer1 ? -1 : 1;
    _lurchCtrl.forward(from: 0);
    _questionCtrl.forward(from: 0);
    _questionCorrect = true;

    setState(() {
      if (isPlayer1) {
        _p1Correct++;
        _p1Fb = _Feedback.correct;
        _p1Locked = true;
        _p2Locked = true;
      } else {
        _p2Correct++;
        _p2Fb = _Feedback.correct;
        _p1Locked = true;
        _p2Locked = true;
      }
    });

    _aiTimer?.cancel();
    _feedbackTimer?.cancel();

    if (_p1Correct >= _winScore) {
      Future.delayed(const Duration(milliseconds: 900), () => _finishGame('player'));
    } else if (_p2Correct >= _winScore) {
      Future.delayed(const Duration(milliseconds: 900), () => _finishGame('ai'));
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _phase == _GamePhase.playing) _generateQuestion();
      });
    }
  }

  void _onWrong({required bool isPlayer1}) {
    _playSound(false);
    _questionCorrect = false;
    _questionCtrl.forward(from: 0);

    setState(() {
      if (isPlayer1) {
        _p1Fb = _Feedback.wrong;
        _p1Input = '';
      } else {
        _p2Fb = _Feedback.wrong;
      }
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          if (isPlayer1) { _p1Fb = _Feedback.none; } else { _p2Fb = _Feedback.none; }
        });
      }
    });
  }

  // ── AI logic ──────────────────────────────────────────────────────────────
  void _startAiTimer() {
    _aiTimer?.cancel();
    final delay = 2 + _random.nextInt(4);
    setState(() => _aiThinking = true);

    _aiTimer = Timer(Duration(seconds: delay), () {
      if (!mounted || _phase != _GamePhase.playing || _p2Locked) return;

      final aiCorrect = _random.nextDouble() < 0.7;
      setState(() => _aiThinking = false);

      if (aiCorrect) {
        _onCorrect(isPlayer1: false);
      } else {
        // AI got it wrong — try again after another delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _phase == _GamePhase.playing && !_p2Locked) {
            _startAiTimer();
          }
        });
      }
    });
  }

  void _finishGame(String winner) {
    _aiTimer?.cancel();
    _feedbackTimer?.cancel();
    if (mounted) setState(() { _winner = winner; _phase = _GamePhase.finished; });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF1A237E), Color(0xFF311B92)],
          ),
        ),
        child: SafeArea(
          child: switch (_phase) {
            _GamePhase.menu     => _buildMenu(),
            _GamePhase.playing  => _buildPlaying(),
            _GamePhase.finished => _buildFinished(),
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Top bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _aiTimer?.cancel();
              context.pop();
            },
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 1 — Menu
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMenu() {
    return Column(
      children: [
        _buildTopBar('🪢 Tug of War Maths'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose Level:',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                ),
                const SizedBox(height: 10),

                // Level grid
                GridView.count(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: _levels.map((l) {
                    final sel = _level == l.level;
                    return GestureDetector(
                      onTap: () => setState(() => _level = l.level),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.2),
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${l.level}',
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                            ),
                            Text(
                              l.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 8, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'Operations: ${_levels[_level - 1].ops}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 28),

                // Start button
                GestureDetector(
                  onTap: _startGame,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1DE9B6), Color(0xFF00B0FF)]),
                      borderRadius: BorderRadius.circular(29),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF1DE9B6).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Center(
                      child: Text('🚦 Start Game!', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Collapsible instructions
                GestureDetector(
                  onTap: () => setState(() => _showInstructions = !_showInstructions),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('❓', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        const Text('How to Play', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Icon(_showInstructions ? Icons.expand_less : Icons.expand_more, color: Colors.white70),
                      ],
                    ),
                  ),
                ),

                if (_showInstructions) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Answer the maths question correctly to pull the rope toward your side', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        SizedBox(height: 6),
                        Text('• First to pull the rope 7 steps to their side wins! 🏆', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        SizedBox(height: 6),
                        Text('• vs AI: the AI will try to answer after 2–5 seconds', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 2 — Playing
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPlaying() {
    return Column(
      children: [
        _buildTopBar('🪢 Tug of War  •  Level $_level'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: Column(
              children: [
                // Score bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _ScorePill(label: 'You', score: _p1Correct, total: _winScore, color: const Color(0xFF2196F3)),
                      Expanded(
                        child: Center(
                          child: Text('VS', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white54)),
                        ),
                      ),
                      _ScorePill(label: 'AI', score: _p2Correct, total: _winScore, color: const Color(0xFFF44336), reversed: true),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Question
                _buildQuestionWidget(),

                const SizedBox(height: 8),

                // Arena
                _buildArena(),

                if (_aiThinking) ...[
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'AI is thinking… 🤔',
                      style: TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Number pad
                _buildPad(isP1: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionWidget() {
    final q = _question;
    if (q == null) return const SizedBox(height: 60);

    // Question background color based on feedback
    Color qColor = Colors.white.withValues(alpha: 0.12);
    if (_p1Fb == _Feedback.correct || _p2Fb == _Feedback.correct) {
      qColor = const Color(0xFF00C853).withValues(alpha: 0.2);
    } else if (_p1Fb == _Feedback.wrong || _p2Fb == _Feedback.wrong) {
      qColor = const Color(0xFFD32F2F).withValues(alpha: 0.2);
    }

    // Scale animation: correct = scale up, wrong = use shake offset
    final animValue = _questionCtrl.value;
    double scale = 1.0;
    double shakeX = 0.0;
    if (_questionCorrect) {
      scale = 1.0 + (animValue < 0.5 ? animValue : 1 - animValue) * 0.25;
    } else {
      shakeX = sin(animValue * pi * 5) * 6;
    }

    return Transform.translate(
      offset: Offset(shakeX, 0),
      child: Transform.scale(
        scale: scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: qColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              q.display,
              style: GoogleFonts.montserrat(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // ── Arena ─────────────────────────────────────────────────────────────────
  Widget _buildArena() {
    return SizedBox(
      height: 155,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          const charW = 48.0;
          const ropeY = 155 * 0.5;
          final ropeStart = charW + 8;
          final ropeEnd = w - charW - 8;
          final ropeLen = ropeEnd - ropeStart;
          final cx = ropeStart + ropeLen / 2;
          final flagOffset = (_ropePos / _winScore) * (ropeLen / 2 * 0.82);
          final flagX = cx + flagOffset - 10;

          return AnimatedBuilder(
            animation: _lurchCtrl,
            builder: (_, __) => Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(w, 155),
                  painter: _ArenaPainter(
                    lurchOffset: _lurchOffset,
                    isVsAi: true,
                    p1Score: _p1Correct,
                    p2Score: _p2Correct,
                    winScore: _winScore,
                  ),
                ),
                // Animated rope flag
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  left: flagX.clamp(ropeStart - 4, ropeEnd - 16),
                  top: ropeY - 28,
                  child: const Text('🚩', style: TextStyle(fontSize: 22)),
                ),
                // Win zone labels
                Positioned(
                  left: 2,
                  bottom: 4,
                  child: Text('◀ P1', style: TextStyle(color: const Color(0xFF90CAF9), fontSize: 9, fontWeight: FontWeight.w700)),
                ),
                Positioned(
                  right: 2,
                  bottom: 4,
                  child: Text('AI ▶',
                    style: TextStyle(color: const Color(0xFFEF9A9A), fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Number pad ────────────────────────────────────────────────────────────
  Widget _buildPad({required bool isP1}) {
    final input  = _p1Input;
    final fb     = _p1Fb;
    final locked = _p1Locked;
    const color  = Color(0xFF1565C0);

    void onDigit(String d) {
      if (locked) return;
      setState(() { _p1Input = _p1Input.length < 5 ? _p1Input + d : _p1Input; });
    }

    void onClear() {
      if (locked) return;
      setState(() { _p1Input = ''; });
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Column(
        children: [
          // Input display
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: fb == _Feedback.correct
                  ? const Color(0xFF00C853).withValues(alpha: 0.25)
                  : fb == _Feedback.wrong
                      ? const Color(0xFFD32F2F).withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    input.isEmpty
                        ? (fb == _Feedback.wrong ? '✗ Try again!' : '?')
                        : input,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: fb == _Feedback.wrong ? const Color(0xFFEF9A9A) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Digit grid
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final d in ['7','8','9','4','5','6','1','2','3'])
                _PadBtn(label: d, color: color, locked: locked, onTap: () => onDigit(d)),
              _PadBtn(label: 'C', color: Colors.orange, locked: locked, onTap: onClear),
              _PadBtn(label: '0', color: color, locked: locked, onTap: () => onDigit('0')),
              _PadBtn(
                label: '✓',
                color: const Color(0xFF00C853),
                locked: locked,
                onTap: _submitP1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 3 — Finished
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFinished() {
    final playerWon = _winner == 'player';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar('🪢 Tug of War'),
          const SizedBox(height: 24),

          // Result banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: playerWon
                    ? const [Color(0xFF00897B), Color(0xFF1DE9B6)]
                    : const [Color(0xFF4A148C), Color(0xFF7B1FA2)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (playerWon ? Colors.teal : Colors.purple).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(playerWon ? '🏆' : '🤖', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 10),
                Text(
                  playerWon ? 'You Win! 🎉' : 'AI Wins!',
                  style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  playerWon
                      ? 'Incredible! You pulled the rope all the way! 💪'
                      : 'The AI won this time. Try again! 💪',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Text('Final Scores', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ResultStat(label: 'You', value: '$_p1Correct / $_winScore', color: const Color(0xFF90CAF9)),
                    _ResultStat(label: 'Questions', value: '$_questionsAnswered', color: Colors.white70),
                    _ResultStat(label: 'AI', value: '$_p2Correct / $_winScore', color: const Color(0xFFEF9A9A)),
                  ],
                ),
                const SizedBox(height: 10),
                _ResultStat(label: 'Level', value: '${_levels[_level - 1].level} — ${_levels[_level - 1].name}', color: Colors.white60),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _startGame,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1DE9B6), Color(0xFF00B0FF)]),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [BoxShadow(color: const Color(0xFF1DE9B6).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Center(child: Text('🔄 Play Again', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _phase = _GamePhase.menu),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Center(child: Text('⚙️ Change Level', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arena CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _ArenaPainter extends CustomPainter {
  final double lurchOffset;
  final bool isVsAi;
  final int p1Score, p2Score, winScore;

  const _ArenaPainter({
    required this.lurchOffset,
    required this.isVsAi,
    required this.p1Score,
    required this.p2Score,
    required this.winScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFB3E5FC)],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.68));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.68), skyPaint);

    // Grass
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
      ).createShader(Rect.fromLTWH(0, h * 0.68, w, h * 0.32));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.68, w, h * 0.32), grassPaint);

    // Win zone overlays
    canvas.drawRect(Rect.fromLTWH(0, 0, 28, h), Paint()..color = const Color(0xFF2196F3).withValues(alpha: 0.2));
    canvas.drawRect(Rect.fromLTWH(w - 28, 0, 28, h), Paint()..color = const Color(0xFFF44336).withValues(alpha: 0.2));

    // Rope
    const ropeY = 155 * 0.5;
    const charW = 48.0;
    final ropeStartX = charW + 8;
    final ropeEndX = w - charW - 8;
    final ropePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ropeStartX, ropeY), Offset(ropeEndX, ropeY), ropePaint);

    // Characters
    final p1X = 30.0 + lurchOffset;
    final p2X = w - 30.0 + lurchOffset;
    _drawPlayer(canvas, Offset(p1X, ropeY - 10), isP2: false);
    if (isVsAi) {
      _drawRobot(canvas, Offset(p2X, ropeY - 10));
    } else {
      _drawPlayer(canvas, Offset(p2X, ropeY - 10), isP2: true);
    }

    // Progress indicator lines at WIN_SCORE edges
    final ropeMid = ropeStartX + (ropeEndX - ropeStartX) / 2;
    final halfLen = (ropeEndX - ropeStartX) / 2 * 0.82;
    _drawDashedLine(canvas, Offset(ropeMid - halfLen, 0), Offset(ropeMid - halfLen, h), const Color(0xFF90CAF9).withValues(alpha: 0.4));
    _drawDashedLine(canvas, Offset(ropeMid + halfLen, 0), Offset(ropeMid + halfLen, h), const Color(0xFFEF9A9A).withValues(alpha: 0.4));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()..color = color..strokeWidth = 1.5;
    const dashLen = 6.0;
    const gapLen = 5.0;
    final dir = (end - start);
    final len = dir.distance;
    final unit = dir / len;
    double d = 0;
    while (d < len) {
      final a = start + unit * d;
      final b = start + unit * (d + dashLen).clamp(0.0, len);
      canvas.drawLine(a, b, paint);
      d += dashLen + gapLen;
    }
  }

  void _drawPlayer(Canvas canvas, Offset base, {required bool isP2}) {
    final skinPaint  = Paint()..color = const Color(0xFFFFCC80);
    final hairPaint  = Paint()..color = isP2 ? const Color(0xFF9C27B0) : const Color(0xFF6D4C41);
    final shirtPaint = Paint()..color = isP2 ? const Color(0xFF8E24AA) : const Color(0xFF1976D2);
    final limbPaint  = Paint()..color = const Color(0xFF37474F)..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    final hx = base.dx;
    final hy = base.dy - 32;

    // Head
    canvas.drawCircle(Offset(hx, hy), 11, skinPaint);
    // Hair arc
    final hairPath = Path()..addArc(Rect.fromCircle(center: Offset(hx, hy), radius: 11), -pi, pi);
    canvas.drawPath(hairPath, hairPaint..style = PaintingStyle.stroke..strokeWidth = 5);
    // Body shirt
    canvas.drawRect(Rect.fromLTWH(hx - 8, hy + 10, 16, 18), shirtPaint);
    // Neck
    canvas.drawLine(Offset(hx, hy + 11), Offset(hx, hy + 13), limbPaint..strokeWidth = 3);
    // Arms
    canvas.drawLine(Offset(hx - 8, hy + 14), Offset(hx - 18, hy + 23), limbPaint..strokeWidth = 2.5);
    canvas.drawLine(Offset(hx + 8, hy + 14), Offset(hx + 18, hy + 23), limbPaint);
    // Legs
    canvas.drawLine(Offset(hx - 3, hy + 28), Offset(hx - 8, hy + 42), limbPaint);
    canvas.drawLine(Offset(hx + 3, hy + 28), Offset(hx + 8, hy + 42), limbPaint);
  }

  void _drawRobot(Canvas canvas, Offset base) {
    final metalPaint = Paint()..color = const Color(0xFF90A4AE);
    final darkPaint  = Paint()..color = const Color(0xFF455A64);
    final eyePaint   = Paint()..color = const Color(0xFF69F0AE);
    final outlinePaint = Paint()..color = const Color(0xFF546E7A)..style = PaintingStyle.stroke..strokeWidth = 2;
    final limbPaint  = Paint()..color = const Color(0xFF78909C)..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    final hx = base.dx;
    final hy = base.dy - 32;

    // Antenna
    canvas.drawLine(Offset(hx, hy - 12), Offset(hx, hy - 20), darkPaint..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(hx, hy - 22), 4, eyePaint);

    // Head
    final headRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(hx, hy - 2), width: 22, height: 18), const Radius.circular(4));
    canvas.drawRRect(headRect, metalPaint);
    canvas.drawRRect(headRect, outlinePaint);
    // LED eyes
    canvas.drawCircle(Offset(hx - 4, hy - 2), 3, eyePaint);
    canvas.drawCircle(Offset(hx + 4, hy - 2), 3, eyePaint);

    // Body
    final bodyRect = RRect.fromRectAndRadius(Rect.fromLTWH(hx - 10, hy + 8, 20, 20), const Radius.circular(3));
    canvas.drawRRect(bodyRect, metalPaint);
    canvas.drawRRect(bodyRect, outlinePaint);

    // Arms
    canvas.drawLine(Offset(hx - 10, hy + 13), Offset(hx - 20, hy + 21), limbPaint);
    canvas.drawLine(Offset(hx + 10, hy + 13), Offset(hx + 20, hy + 21), limbPaint);

    // Legs
    canvas.drawLine(Offset(hx - 4, hy + 28), Offset(hx - 6, hy + 42), limbPaint..strokeWidth = 4);
    canvas.drawLine(Offset(hx + 4, hy + 28), Offset(hx + 6, hy + 42), limbPaint);
  }

  @override
  bool shouldRepaint(_ArenaPainter old) =>
      old.lurchOffset != lurchOffset ||
      old.p1Score != p1Score ||
      old.p2Score != p2Score;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final String label;
  final int score, total;
  final Color color;
  final bool reversed;
  const _ScorePill({required this.label, required this.score, required this.total, required this.color, this.reversed = false});

  @override
  Widget build(BuildContext context) {
    final dots = List.generate(total, (i) {
      final filled = reversed ? i >= (total - score) : i < score;
      return Container(
        width: 9, height: 9,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : color.withValues(alpha: 0.2),
        ),
      );
    });

    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        const SizedBox(height: 4),
        Row(mainAxisSize: MainAxisSize.min, children: dots),
      ],
    );
  }
}

class _PadBtn extends StatefulWidget {
  final String label;
  final Color color;
  final bool locked;
  final VoidCallback onTap;
  const _PadBtn({required this.label, required this.color, required this.locked, required this.onTap});

  @override
  State<_PadBtn> createState() => _PadBtnState();
}

class _PadBtnState extends State<_PadBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.locked
        ? Colors.white.withValues(alpha: 0.04)
        : _pressed
            ? widget.color.withValues(alpha: 0.40)
            : widget.color.withValues(alpha: 0.22);

    return GestureDetector(
      onTapDown: widget.locked ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.locked
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.locked
                ? Colors.white.withValues(alpha: 0.08)
                : widget.color.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: widget.locked ? Colors.white24 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ResultStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
