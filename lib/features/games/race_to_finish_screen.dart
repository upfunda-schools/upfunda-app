import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

enum _GameState { waiting, racing, finished }

enum _Difficulty { easy, medium, hard }

enum _Feedback { none, correct, incorrect }

class _Racer {
  final String name;
  final String emoji;
  final Color color;
  final bool isPlayer;
  int steps = 0;

  _Racer({
    required this.name,
    required this.emoji,
    required this.color,
    required this.isPlayer,
  });
}

class _Question {
  final String text;
  final int answer;
  final List<int> choices;
  const _Question({required this.text, required this.answer, required this.choices});
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class RaceToFinishScreen extends StatefulWidget {
  const RaceToFinishScreen({super.key});

  @override
  State<RaceToFinishScreen> createState() => _RaceToFinishScreenState();
}

class _RaceToFinishScreenState extends State<RaceToFinishScreen> {
  static const int _maxSteps = 10;

  // ── State ─────────────────────────────────────────────────────────────────
  _GameState _gameState = _GameState.waiting;
  _Difficulty _difficulty = _Difficulty.medium;

  late List<_Racer> _racers;
  _Racer? _winner;

  _Question? _question;
  _Feedback _feedback = _Feedback.none;
  bool _answerLocked = false;
  int? _selectedAnswer;

  int _timeElapsed = 0;
  Timer? _gameTimer;

  final _random = Random();

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initRacers();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  // ── Setup ─────────────────────────────────────────────────────────────────
  void _initRacers() {
    _racers = [
      _Racer(name: 'You',  emoji: '🏎️', color: const Color(0xFF00E5FF), isPlayer: true),
      _Racer(name: 'Nova', emoji: '🚗',  color: const Color(0xFFFF4081), isPlayer: false),
      _Racer(name: 'Bolt', emoji: '🚕',  color: const Color(0xFFFFAB40), isPlayer: false),
    ];
  }

  void _startRace() {
    for (final r in _racers) {
      r.steps = 0;
    }
    setState(() {
      _gameState = _GameState.racing;
      _winner = null;
      _feedback = _Feedback.none;
      _answerLocked = false;
      _selectedAnswer = null;
      _timeElapsed = 0;
    });
    _generateQuestion();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameState != _GameState.racing) return;
      setState(() {
        _timeElapsed++;
        _tickAI();
      });
    });
  }

  // ── AI advancement ────────────────────────────────────────────────────────
  double get _aiChancePerSecond => switch (_difficulty) {
        _Difficulty.easy   => 0.10,
        _Difficulty.medium => 0.17,
        _Difficulty.hard   => 0.28,
      };

  void _tickAI() {
    for (final r in _racers) {
      if (r.isPlayer || r.steps >= _maxSteps) continue;
      if (_random.nextDouble() < _aiChancePerSecond) {
        r.steps++;
        if (r.steps >= _maxSteps && _winner == null) {
          _winner = r;
          // Use addPostFrameCallback to avoid setState during setState
          WidgetsBinding.instance.addPostFrameCallback((_) => _finishRace());
          return;
        }
      }
    }
  }

  // ── Question generation ───────────────────────────────────────────────────
  void _generateQuestion() {
    final q = switch (_difficulty) {
      _Difficulty.easy   => _makeAddSub(max: 20),
      _Difficulty.medium => _random.nextBool() ? _makeAddSub(max: 50) : _makeMul(aMax: 5, bMax: 10),
      _Difficulty.hard   => _random.nextBool() ? _makeMul(aMax: 12, bMax: 12) : _makeAddSub(max: 100),
    };
    setState(() => _question = q);
  }

  _Question _makeAddSub({required int max}) {
    final a = 1 + _random.nextInt(max);
    final b = 1 + _random.nextInt(max);
    if (_random.nextBool() || b > a) {
      final ans = a + b;
      return _Question(text: '$a + $b = ?', answer: ans, choices: _makeChoices(ans, maxVal: max * 2));
    } else {
      final ans = a - b;
      return _Question(text: '$a − $b = ?', answer: ans, choices: _makeChoices(ans, maxVal: max));
    }
  }

  _Question _makeMul({required int aMax, required int bMax}) {
    final a = 2 + _random.nextInt(aMax - 1);
    final b = 2 + _random.nextInt(bMax - 1);
    final ans = a * b;
    return _Question(text: '$a × $b = ?', answer: ans, choices: _makeChoices(ans, maxVal: ans + 20));
  }

  List<int> _makeChoices(int correct, {required int maxVal}) {
    final set = <int>{correct};
    int tries = 0;
    while (set.length < 4 && tries++ < 50) {
      final delta = 1 + _random.nextInt(maxVal ~/ 5 < 4 ? 4 : maxVal ~/ 5);
      final w = correct + (_random.nextBool() ? delta : -delta);
      if (w > 0 && w != correct) set.add(w);
    }
    // Fallback if not enough unique wrongs
    int fill = 1;
    while (set.length < 4) {
      if (fill != correct) set.add(fill);
      fill++;
    }
    return set.toList()..shuffle(_random);
  }

  // ── Answer handling ───────────────────────────────────────────────────────
  void _submitAnswer(int choice) {
    if (_answerLocked || _gameState != _GameState.racing) return;

    final correct = choice == _question!.answer;
    setState(() {
      _answerLocked = true;
      _selectedAnswer = choice;
      _feedback = correct ? _Feedback.correct : _Feedback.incorrect;
      if (correct) {
        final player = _racers.firstWhere((r) => r.isPlayer);
        player.steps++;
        if (player.steps >= _maxSteps && _winner == null) {
          _winner = player;
        }
      }
    });

    if (_winner != null) {
      Future.delayed(const Duration(milliseconds: 700), _finishRace);
      return;
    }

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted && _gameState == _GameState.racing) {
        setState(() {
          _feedback = _Feedback.none;
          _answerLocked = false;
          _selectedAnswer = null;
        });
        _generateQuestion();
      }
    });
  }

  void _finishRace() {
    _gameTimer?.cancel();
    _winner ??= _racers.reduce((a, b) => a.steps > b.steps ? a : b);
    if (mounted) setState(() => _gameState = _GameState.finished);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _timeStr {
    final m = _timeElapsed ~/ 60;
    final s = _timeElapsed % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  List<_Racer> get _standings => [..._racers]..sort((a, b) => b.steps.compareTo(a.steps));

  int _rankOf(_Racer r) => _standings.indexOf(r) + 1;

  String _rankLabel(int rank) => ['1st', '2nd', '3rd', '4th'][rank - 1];

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B6E), Color(0xFF5B1FA8), Color(0xFFAD1457)],
          ),
        ),
        child: SafeArea(
          child: switch (_gameState) {
            _GameState.waiting  => _buildWaiting(),
            _GameState.racing   => _buildRacing(),
            _GameState.finished => _buildFinished(),
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Top bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar({required bool showTimer}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
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
              '🏁 Arithmetic Car Race',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          if (showTimer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _timeStr,
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 38),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 1 — Waiting / Start
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWaiting() {
    return Column(
      children: [
        _buildTopBar(showTimer: false),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              children: [
                const Text('🏎️', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 8),
                Text(
                  'Arithmetic Car Race!',
                  style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Answer maths questions to move your car.\nFirst to the finish line wins! 🏁',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 32),

                // Difficulty
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Difficulty',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _DiffBtn(
                      emoji: '🟢', label: 'Easy', sub: 'Addition / Subtraction',
                      selected: _difficulty == _Difficulty.easy,
                      onTap: () => setState(() => _difficulty = _Difficulty.easy),
                    ),
                    const SizedBox(width: 8),
                    _DiffBtn(
                      emoji: '🟡', label: 'Medium', sub: 'Times tables',
                      selected: _difficulty == _Difficulty.medium,
                      onTap: () => setState(() => _difficulty = _Difficulty.medium),
                    ),
                    const SizedBox(width: 8),
                    _DiffBtn(
                      emoji: '🔴', label: 'Hard', sub: 'Large numbers',
                      selected: _difficulty == _Difficulty.hard,
                      onTap: () => setState(() => _difficulty = _Difficulty.hard),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Racers
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Opponents',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                ..._racers.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text(r.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Text(
                        r.name,
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 15, color: r.color),
                      ),
                      const SizedBox(width: 8),
                      if (r.isPlayer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: r.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: r.color.withValues(alpha: 0.5)),
                          ),
                          child: Text('YOU', style: TextStyle(color: r.color, fontSize: 10, fontWeight: FontWeight.w800)),
                        )
                      else ...[
                        const Spacer(),
                        Text('AI', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ],
                  ),
                )),

                const SizedBox(height: 32),

                // Start button
                GestureDetector(
                  onTap: _startRace,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00E5FF)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00BCD4).withValues(alpha: 0.5),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '🚦 Start Race!',
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 2 — Racing
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRacing() {
    return Column(
      children: [
        _buildTopBar(showTimer: true),
        const SizedBox(height: 16),

        // Track area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: _racers.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTrackRow(r),
            )).toList(),
          ),
        ),

        const Spacer(),

        // Question card
        if (_question != null) _buildQuestionCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTrackRow(_Racer racer) {
    final rank = _rankOf(racer);

    return Row(
      children: [
        // Label
        SizedBox(
          width: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _rankLabel(rank),
                style: TextStyle(
                  color: rank == 1 ? const Color(0xFFFFD700) : Colors.white60,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              Text(
                racer.name,
                style: TextStyle(color: racer.color, fontSize: 10, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Track
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: LayoutBuilder(
              builder: (_, c) {
                // Available width for car travel (leave 36px right for flag)
                final travel = c.maxWidth - 36.0 - 28.0; // 28 = car emoji width
                final carLeft = (racer.steps / _maxSteps * travel).clamp(0.0, travel);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Progress fill
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: racer.steps / _maxSteps),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                      builder: (_, v, __) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: v,
                        child: Container(
                          decoration: BoxDecoration(
                            color: racer.color.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),

                    // Car emoji
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                      left: carLeft,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(racer.emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),

                    // Steps counter (subtle)
                    Positioned(
                      right: 36,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          '${racer.steps}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Finish flag
                    const Positioned(
                      right: 6,
                      top: 0,
                      bottom: 0,
                      child: Center(child: Text('🏁', style: TextStyle(fontSize: 18))),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final q = _question!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            q.text,
            style: GoogleFonts.montserrat(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          // 2×2 answer grid
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.6,
            children: q.choices.map((choice) {
              Color bg;
              if (_selectedAnswer == choice) {
                bg = _feedback == _Feedback.correct
                    ? const Color(0xFF00C853)
                    : const Color(0xFFD32F2F);
              } else if (_answerLocked &&
                  _feedback == _Feedback.incorrect &&
                  choice == q.answer) {
                bg = const Color(0xFF00C853).withValues(alpha: 0.45);
              } else {
                bg = Colors.white.withValues(alpha: 0.15);
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _answerLocked ? null : () => _submitAnswer(choice),
                    child: Center(
                      child: Text(
                        '$choice',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 3 — Finished
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFinished() {
    final playerWon = _winner?.isPlayer == true;
    final standings = _standings;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopBar(showTimer: false),
          const SizedBox(height: 24),

          // Winner banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: playerWon
                    ? const [Color(0xFF00897B), Color(0xFF00BCD4)]
                    : const [Color(0xFF6A1B9A), Color(0xFFAD1457)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (playerWon ? Colors.cyan : Colors.purple).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(playerWon ? '🏆' : _winner!.emoji, style: const TextStyle(fontSize: 60)),
                const SizedBox(height: 8),
                Text(
                  playerWon ? 'You Win! 🎉' : '${_winner!.name} Wins!',
                  style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  playerWon
                      ? 'Amazing! You crossed the finish line first!'
                      : 'Good try! Keep practising to beat the AI!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⏱️  Time: $_timeStr',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Final standings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  'Final Standings',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 14),
                ...standings.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final r = e.value;
                  final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Text(medal, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(r.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          r.name,
                          style: TextStyle(
                            color: r.isPlayer ? Colors.white : Colors.white70,
                            fontWeight: r.isPlayer ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: r.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: r.color.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '${r.steps}/$_maxSteps steps',
                            style: TextStyle(color: r.color, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _startRace,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00BCD4), Color(0xFF00E5FF)]),
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Center(
                      child: Text('🔄 Race Again', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _initRacers();
                    _gameState = _GameState.waiting;
                  }),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text('🏠 Menu', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                    ),
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DiffBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _DiffBtn({
    required this.emoji,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
