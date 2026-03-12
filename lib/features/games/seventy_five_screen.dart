import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _Problem {
  final String question;
  final int answer;
  const _Problem(this.question, this.answer);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SeventyFiveScreen extends StatefulWidget {
  const SeventyFiveScreen({super.key});

  @override
  State<SeventyFiveScreen> createState() => _SeventyFiveScreenState();
}

class _SeventyFiveScreenState extends State<SeventyFiveScreen> {
  // colorIndex = num % 10
  static const _cellColors = [
    Color(0xFFF44336), // 0 → red
    Color(0xFF2196F3), // 1 → blue
    Color(0xFF4CAF50), // 2 → green
    Color(0xFFFFC107), // 3 → yellow/amber
    Color(0xFF9C27B0), // 4 → purple
    Color(0xFFE91E63), // 5 → pink
    Color(0xFFFF9800), // 6 → orange
    Color(0xFF009688), // 7 → teal
    Color(0xFF3F51B5), // 8 → indigo
    Color(0xFF00BCD4), // 9 → cyan
  ];

  final _rng = Random();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  // null → mode selection screen
  int? _gridSize;

  Set<int> _colored = {};
  _Problem? _problem;
  String? _feedback; // "correct" | "wrong"
  int _score = 0;
  int _streak = 0;
  bool _busy = false;
  int? _justColored; // cell to highlight briefly

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {})); // re-render on typing
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Problem generation ─────────────────────────────────────────────────────

  _Problem _generate() {
    final size = _gridSize!;
    for (int t = 0; t < 100; t++) {
      final additionMode = _rng.nextBool();
      int n1, n2, ans;

      if (size == 25) {
        if (additionMode) {
          n1 = _rng.nextInt(12) + 1;              // 1–12
          n2 = _rng.nextInt(25 - n1) + 1;         // 1–(25-n1)
          ans = n1 + n2;
        } else {
          n1 = _rng.nextInt(24) + 2;              // 2–25
          n2 = _rng.nextInt(n1 - 1) + 1;          // 1–(n1-1)
          ans = n1 - n2;
        }
      } else {
        if (additionMode) {
          n1 = _rng.nextInt(40) + 1;              // 1–40
          n2 = _rng.nextInt(50 - n1) + 1;         // 1–(50-n1)
          ans = n1 + n2;
        } else {
          ans = _rng.nextInt(50) + 1;             // 1–50
          n1 = ans + _rng.nextInt(50) + 1;        // ans+1 .. ans+50
          n2 = n1 - ans;
        }
      }

      if (!_colored.contains(ans)) {
        final q = additionMode ? '$n1 + $n2 = ?' : '$n1 - $n2 = ?';
        return _Problem(q, ans);
      }
    }
    return const _Problem('1 + 1 = ?', 2); // fallback
  }

  // ── Game actions ───────────────────────────────────────────────────────────

  void _startGame(int size) {
    setState(() {
      _gridSize = size;
      _colored = {};
      _score = 0;
      _streak = 0;
      _feedback = null;
      _busy = false;
      _justColored = null;
      _ctrl.clear();
      _problem = _generate();
    });
    Future.microtask(() => _focus.requestFocus());
  }

  void _reset() {
    setState(() {
      _colored = {};
      _score = 0;
      _streak = 0;
      _feedback = null;
      _busy = false;
      _justColored = null;
      _ctrl.clear();
      _problem = _generate();
    });
    Future.microtask(() => _focus.requestFocus());
  }

  void _submit() {
    if (_busy || _feedback != null) return;
    final typed = int.tryParse(_ctrl.text.trim());
    if (typed == null) return;

    final correct = typed == _problem!.answer;

    setState(() {
      _busy = true;
      _feedback = correct ? 'correct' : 'wrong';
      if (correct) {
        _score += 10;
        _streak += 1;
        _colored.add(_problem!.answer);
        _justColored = _problem!.answer;
      } else {
        _streak = 0;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _feedback = null;
        _busy = false;
        if (correct) {
          if (_colored.length < _gridSize!) {
            _ctrl.clear();
            _justColored = null;
            _problem = _generate();
            Future.microtask(() => _focus.requestFocus());
          }
          // If all colored → victory modal shows, no new problem needed
        }
        // Wrong: keep same problem + input, just clear feedback
      });
    });
  }

  // ── Top-level build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _gridSize == null ? _modeSelection(context) : _gameScreen(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN 1 — Mode Selection
  // ─────────────────────────────────────────────────────────────────────────

  Widget _modeSelection(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _warmGradient(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _backToGames(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '75 Chart Coloring',
                  style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF333333)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text('Choose your challenge level', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Expanded(
                        child: _modeCard(
                          size: 25,
                          gradient: [const Color(0xFFEC407A), const Color(0xFFF48FB1)],
                          title: '25 Chart',
                          badge: 'Easier',
                          badgeColor: Colors.green,
                          description: '5×5 grid with numbers 1–25',
                          subText: 'Perfect for beginners or quick practice',
                          accent: const Color(0xFFEC407A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _modeCard(
                          size: 50,
                          gradient: [const Color(0xFF7B1FA2), const Color(0xFF3949AB)],
                          title: '50 Chart',
                          badge: 'Difficult',
                          badgeColor: Colors.red,
                          description: '5×10 grid with harder math problems',
                          subText: 'Subtraction uses numbers up to 100!',
                          accent: const Color(0xFF7B1FA2),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard({
    required int size,
    required List<Color> gradient,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required String subText,
    required Color accent,
  }) {
    return GestureDetector(
      onTap: () => _startGame(size),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$size',
                    style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Text(title, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF333333))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
                    const SizedBox(height: 4),
                    Text(subText, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accent),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN 2 — Game
  // ─────────────────────────────────────────────────────────────────────────

  Widget _gameScreen(BuildContext context) {
    final allColored = _colored.length == _gridSize;
    return Scaffold(
      body: Container(
        decoration: _warmGradient(),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _gameHeader(),
                    _gameTitle(),
                    const SizedBox(height: 12),
                    _statsCard(),
                    const SizedBox(height: 12),
                    _problemCard(),
                    const SizedBox(height: 12),
                    _chartCard(),
                    const SizedBox(height: 12),
                    _howToPlay(),
                  ],
                ),
              ),
              if (allColored) _victoryModal(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => setState(() { _gridSize = null; _ctrl.clear(); _feedback = null; _busy = false; }),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: const Text('Change Mode'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _gameTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_gridSize Chart Coloring',
            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF333333)),
          ),
          Text('Solve math problems to color the chart!', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ── Stats card ─────────────────────────────────────────────────────────────

  Widget _statsCard() {
    final pct = _colored.length / _gridSize! * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: _whiteCard(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Score', '$_score', const Color(0xFFFF9800)),
                _stat('Colored', '${_colored.length}/$_gridSize', const Color(0xFF4CAF50)),
                _stat('Streak', '$_streak', const Color(0xFF2196F3)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _colored.length / _gridSize!,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${pct.toStringAsFixed(1)}% Complete', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  // ── Problem card ───────────────────────────────────────────────────────────

  Widget _problemCard() {
    if (_problem == null) return const SizedBox();
    final disabled = _busy || _feedback != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: _whiteCard(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solve the Problem:',
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF444444))),
            const SizedBox(height: 12),

            // Problem display box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFFEC407A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _problem!.question,
                  style: GoogleFonts.montserrat(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input
            TextField(
              controller: _ctrl,
              focusNode: _focus,
              enabled: !disabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Your answer…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: disabled || _ctrl.text.isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  disabledBackgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Submit Answer', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
              ),
            ),

            // Feedback
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _feedback == null
                  ? const SizedBox(key: ValueKey('none'), height: 0)
                  : Padding(
                      key: ValueKey(_feedback),
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _feedback == 'correct' ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _feedback == 'correct' ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            _feedback == 'correct' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: _feedback == 'correct' ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _feedback == 'correct'
                                  ? 'Correct! +10 points'
                                  : 'Not quite! Give it another try.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _feedback == 'correct' ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chart card ─────────────────────────────────────────────────────────────

  Widget _chartCard() {
    final cols = _gridSize == 25 ? 5 : 10;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: _whiteCard(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '$_gridSize Number Chart',
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF444444)),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 4.0;
                final cellSize = (constraints.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: List.generate(_gridSize!, (i) => _chartCell(i + 1, cellSize)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCell(int num, double size) {
    final isColored = _colored.contains(num);
    final isJust = num == _justColored;
    final col = _cellColors[num % 10];
    final fontSize = _gridSize == 25 ? 12.0 : 9.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isColored ? col : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isJust ? const Color(0xFFFF9800) : (isColored ? col.withValues(alpha: 0.6) : Colors.grey.shade300),
          width: isJust ? 2.5 : 1,
        ),
        boxShadow: isColored
            ? [BoxShadow(color: col.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      child: Center(
        child: Text(
          '$num',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: isColored ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  // ── How to play ────────────────────────────────────────────────────────────

  Widget _howToPlay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to Play:', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1565C0))),
            const SizedBox(height: 8),
            ...[
              'Solve the math problem',
              'Type your answer and submit',
              'Correct answers color the chart',
              'Try to color all the numbers!',
            ].map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Text('• ', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
                Text(s, style: const TextStyle(fontSize: 13, color: Color(0xFF1565C0))),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  // ── Victory modal ──────────────────────────────────────────────────────────

  Widget _victoryModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              Text(
                'Amazing Work!',
                style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 8),
              Text(
                'You colored all $_gridSize numbers!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Final Score: $_score',
                style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFFFF9800)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Play Again', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _backToGames(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: TextButton.icon(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
        label: const Text('Back to Games'),
        style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
      ),
    );
  }

  BoxDecoration _warmGradient() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFDE7), Color(0xFFFFE0B2)],
    ),
  );

  BoxDecoration _whiteCard() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 3))],
  );
}
