import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

enum _GamePhase { menu, playing, finished }

class _GradeConfig {
  final int grade;
  final int min;
  final int max;
  final int minClues;
  final int maxClues;
  final String difficulty;

  const _GradeConfig({
    required this.grade,
    required this.min,
    required this.max,
    required this.minClues,
    required this.maxClues,
    required this.difficulty,
  });

  String get range => '$min–$max';
}

const _grades = [
  _GradeConfig(grade: 1, min: 1, max: 20, minClues: 2, maxClues: 3, difficulty: 'Beginner'),
  _GradeConfig(grade: 2, min: 10, max: 50, minClues: 3, maxClues: 4, difficulty: 'Easy'),
  _GradeConfig(grade: 3, min: 10, max: 99, minClues: 3, maxClues: 4, difficulty: 'Medium'),
  _GradeConfig(grade: 4, min: 100, max: 500, minClues: 4, maxClues: 5, difficulty: 'Hard'),
  _GradeConfig(grade: 5, min: 100, max: 999, minClues: 4, maxClues: 5, difficulty: 'Expert'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Clue generation
// ─────────────────────────────────────────────────────────────────────────────

class _Clue {
  final String text;
  final bool Function(int) test;

  const _Clue({required this.text, required this.test});
}

List<_Clue> _allCluesFor(int n, int grade) {
  final clues = <_Clue>[];

  // Grade 1 clues
  if (grade == 1) {
    final pivots = [5, 10, 15];
    for (final p in pivots) {
      if (n > p) clues.add(_Clue(text: 'It is greater than $p', test: (x) => x > p));
      if (n < p) clues.add(_Clue(text: 'It is less than $p', test: (x) => x < p));
    }
    if (n % 2 == 0) {
      clues.add(_Clue(text: 'It is an even number', test: (x) => x % 2 == 0));
    } else {
      clues.add(_Clue(text: 'It is an odd number', test: (x) => x % 2 != 0));
    }
    final ones = n % 10;
    clues.add(_Clue(text: 'It ends in the digit $ones', test: (x) => x % 10 == ones));
  }

  // Grade 2 clues
  if (grade == 2) {
    if (n % 2 == 0) {
      clues.add(_Clue(text: 'It is an even number', test: (x) => x % 2 == 0));
    } else {
      clues.add(_Clue(text: 'It is an odd number', test: (x) => x % 2 != 0));
    }
    final ds = _digitSum(n);
    clues.add(_Clue(text: 'Its digit sum is $ds', test: (x) => _digitSum(x) == ds));
    final ones = n % 10;
    clues.add(_Clue(text: 'Its ones digit is $ones', test: (x) => x % 10 == ones));
    final tens = (n ~/ 10) % 10;
    clues.add(_Clue(text: 'Its tens digit is $tens', test: (x) => (x ~/ 10) % 10 == tens));
    final pivots = [20, 30, 40];
    for (final p in pivots) {
      if (n > p) clues.add(_Clue(text: 'It is greater than $p', test: (x) => x > p));
      if (n < p) clues.add(_Clue(text: 'It is less than $p', test: (x) => x < p));
    }
  }

  // Grade 3 clues
  if (grade == 3) {
    if (n % 2 == 0) {
      clues.add(_Clue(text: 'It is an even number', test: (x) => x % 2 == 0));
    } else {
      clues.add(_Clue(text: 'It is an odd number', test: (x) => x % 2 != 0));
    }
    if (n % 3 == 0) {
      clues.add(_Clue(text: 'It is divisible by 3', test: (x) => x % 3 == 0));
    }
    if (n % 5 == 0) {
      clues.add(_Clue(text: 'It is divisible by 5', test: (x) => x % 5 == 0));
    } else {
      clues.add(_Clue(text: 'It is NOT divisible by 5', test: (x) => x % 5 != 0));
    }
    final ds = _digitSum(n);
    clues.add(_Clue(text: 'Its digit sum is $ds', test: (x) => _digitSum(x) == ds));
    final tens = (n ~/ 10) % 10;
    clues.add(_Clue(text: 'Its tens digit is $tens', test: (x) => (x ~/ 10) % 10 == tens));
    final ones = n % 10;
    clues.add(_Clue(text: 'Its ones digit is $ones', test: (x) => x % 10 == ones));
    final pivots = [30, 50, 70];
    for (final p in pivots) {
      if (n > p) clues.add(_Clue(text: 'It is greater than $p', test: (x) => x > p));
      if (n < p) clues.add(_Clue(text: 'It is less than $p', test: (x) => x < p));
    }
  }

  // Grade 4 clues
  if (grade == 4) {
    final hundreds = n ~/ 100;
    clues.add(_Clue(text: 'Its hundreds digit is $hundreds', test: (x) => x ~/ 100 == hundreds));
    final tens = (n ~/ 10) % 10;
    clues.add(_Clue(text: 'Its tens digit is $tens', test: (x) => (x ~/ 10) % 10 == tens));
    final ones = n % 10;
    clues.add(_Clue(text: 'Its ones digit is $ones', test: (x) => x % 10 == ones));
    if (n % 4 == 0) {
      clues.add(_Clue(text: 'It is divisible by 4', test: (x) => x % 4 == 0));
    }
    if (n % 2 == 0) {
      clues.add(_Clue(text: 'It is an even number', test: (x) => x % 2 == 0));
    } else {
      clues.add(_Clue(text: 'It is an odd number', test: (x) => x % 2 != 0));
    }
    final pivots = [150, 250, 350, 400];
    for (final p in pivots) {
      if (n > p) clues.add(_Clue(text: 'It is greater than $p', test: (x) => x > p));
      if (n < p) clues.add(_Clue(text: 'It is less than $p', test: (x) => x < p));
    }
  }

  // Grade 5 clues
  if (grade == 5) {
    if (_isPerfectSquare(n)) {
      clues.add(_Clue(text: 'It is a perfect square', test: (x) => _isPerfectSquare(x)));
    }
    if (n % 7 == 0) {
      clues.add(_Clue(text: 'It is divisible by 7', test: (x) => x % 7 == 0));
    }
    if (n % 8 == 0) {
      clues.add(_Clue(text: 'It is divisible by 8', test: (x) => x % 8 == 0));
    }
    if (n % 9 == 0) {
      clues.add(_Clue(text: 'It is divisible by 9', test: (x) => x % 9 == 0));
    }
    final hundreds = n ~/ 100;
    clues.add(_Clue(text: 'Its hundreds digit is $hundreds', test: (x) => x ~/ 100 == hundreds));
    final tens = (n ~/ 10) % 10;
    clues.add(_Clue(text: 'Its tens digit is $tens', test: (x) => (x ~/ 10) % 10 == tens));
    final ones = n % 10;
    clues.add(_Clue(text: 'Its ones digit is $ones', test: (x) => x % 10 == ones));
    final ds = _digitSum(n);
    clues.add(_Clue(text: 'Its digit sum is $ds', test: (x) => _digitSum(x) == ds));
    if (n % 2 == 0) {
      clues.add(_Clue(text: 'It is an even number', test: (x) => x % 2 == 0));
    } else {
      clues.add(_Clue(text: 'It is an odd number', test: (x) => x % 2 != 0));
    }
  }

  return clues;
}

int _digitSum(int n) {
  var s = 0;
  var x = n.abs();
  while (x > 0) {
    s += x % 10;
    x ~/= 10;
  }
  return s;
}

bool _isPerfectSquare(int n) {
  if (n < 0) return false;
  final r = sqrt(n).round();
  return r * r == n;
}

/// Returns a minimal clue subset that uniquely identifies [n] within [range].
List<_Clue> _selectUniqueClues(int n, List<int> range, List<_Clue> allClues, int count) {
  final rng = Random();
  allClues.shuffle(rng);

  final selected = <_Clue>[];

  for (final clue in allClues) {
    selected.add(clue);
    final survivors = range.where((x) => selected.every((c) => c.test(x))).toList();
    if (survivors.length == 1 && survivors.first == n) {
      if (selected.length >= count) break;
    }
    if (selected.length >= count) break;
  }

  // If still not unique, keep adding
  for (final clue in allClues) {
    if (selected.contains(clue)) continue;
    selected.add(clue);
    final survivors = range.where((x) => selected.every((c) => c.test(x))).toList();
    if (survivors.length == 1 && survivors.first == n) break;
    if (selected.length >= count + 3) break;
  }

  return selected.take(count).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Puzzle model
// ─────────────────────────────────────────────────────────────────────────────

class _Puzzle {
  final int mystery;
  final List<_Clue> clues;

  const _Puzzle({required this.mystery, required this.clues});
}

_Puzzle _generatePuzzle(_GradeConfig cfg) {
  final rng = Random();
  final range = List.generate(cfg.max - cfg.min + 1, (i) => cfg.min + i);

  for (var attempt = 0; attempt < 20; attempt++) {
    final n = cfg.min + rng.nextInt(cfg.max - cfg.min + 1);
    final allClues = _allCluesFor(n, cfg.grade);
    if (allClues.length < cfg.minClues) continue;

    final count = cfg.minClues + rng.nextInt(cfg.maxClues - cfg.minClues + 1);
    final clues = _selectUniqueClues(n, range, allClues, count);
    if (clues.isNotEmpty) {
      return _Puzzle(mystery: n, clues: clues);
    }
  }

  // Fallback: just use raw clues
  final n = cfg.min + rng.nextInt(cfg.max - cfg.min + 1);
  final clues = _allCluesFor(n, cfg.grade).take(cfg.minClues).toList();
  return _Puzzle(mystery: n, clues: clues);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────

class NumberDetectiveScreen extends StatefulWidget {
  const NumberDetectiveScreen({super.key});

  @override
  State<NumberDetectiveScreen> createState() => _NumberDetectiveScreenState();
}

class _NumberDetectiveScreenState extends State<NumberDetectiveScreen>
    with TickerProviderStateMixin {
  // ── State ──
  _GamePhase _phase = _GamePhase.menu;
  int _selectedGrade = 1;
  bool _showInstructions = false;

  // Playing state
  _Puzzle? _puzzle;
  int _attemptsLeft = 3;
  int _revealedClues = 0;
  int _score = 0;
  int _casesSolved = 0;
  int _totalCases = 0;
  String _feedback = '';
  bool _feedbackCorrect = false;
  bool _showFeedback = false;
  bool _revealed = false; // answer revealed after 3 fails
  final _guessController = TextEditingController();
  final _focusNode = FocusNode();

  // Animations
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _feedbackCtrl;

  // Clue reveal timers
  final List<_ClueState> _clueStates = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));

    _feedbackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    _feedbackCtrl.dispose();
    _guessController.dispose();
    _focusNode.dispose();
    for (final cs in _clueStates) {
      cs.ctrl.dispose();
    }
    super.dispose();
  }

  // ── Game flow ──

  void _startGame() {
    setState(() {
      _phase = _GamePhase.playing;
      _score = 0;
      _casesSolved = 0;
      _totalCases = 0;
    });
    _loadPuzzle();
  }

  void _loadPuzzle() {
    final cfg = _grades[_selectedGrade - 1];
    final puzzle = _generatePuzzle(cfg);

    for (final cs in _clueStates) {
      cs.ctrl.dispose();
    }
    _clueStates.clear();

    for (var i = 0; i < puzzle.clues.length; i++) {
      final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
      _clueStates.add(_ClueState(ctrl: ctrl));
    }

    setState(() {
      _puzzle = puzzle;
      _attemptsLeft = 3;
      _revealedClues = 0;
      _showFeedback = false;
      _feedback = '';
      _revealed = false;
      _guessController.clear();
      _totalCases++;
    });

    // Reveal clues with staggered timing
    _revealClueAt(0, 500);
    for (var i = 1; i < puzzle.clues.length; i++) {
      _revealClueAt(i, 500 + i * 1500);
    }
  }

  void _revealClueAt(int index, int delayMs) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      if (index >= _clueStates.length) return;
      setState(() => _revealedClues = index + 1);
      _clueStates[index].ctrl.forward();
    });
  }

  void _checkAnswer() {
    final input = int.tryParse(_guessController.text.trim());
    if (input == null || _puzzle == null) return;
    FocusScope.of(context).unfocus();

    final correct = input == _puzzle!.mystery;
    if (correct) {
      final unusedClues = _puzzle!.clues.length - _revealedClues;
      final points = _attemptsLeft == 3 ? 100 : _attemptsLeft == 2 ? 75 : 50;
      final bonus = unusedClues.clamp(0, 99) * 10;
      setState(() {
        _score += points + bonus;
        _casesSolved++;
        _feedback = 'Correct! Great detective work! +${points + bonus} pts';
        _feedbackCorrect = true;
        _showFeedback = true;
      });
      _bounceCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        setState(() => _showFeedback = false);
        _loadPuzzle();
      });
    } else {
      final newAttempts = _attemptsLeft - 1;
      if (newAttempts == 0) {
        setState(() {
          _attemptsLeft = 0;
          _feedback = 'The mystery number was ${_puzzle!.mystery}!';
          _feedbackCorrect = false;
          _showFeedback = true;
          _revealed = true;
        });
      } else {
        setState(() {
          _attemptsLeft = newAttempts;
          _feedback = 'Not quite! Try again. $newAttempts attempt${newAttempts == 1 ? '' : 's'} left.';
          _feedbackCorrect = false;
          _showFeedback = true;
        });
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          setState(() {
            _showFeedback = false;
            _guessController.clear();
          });
        });
      }
    }
  }

  void _endInvestigation() {
    setState(() => _phase = _GamePhase.finished);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _GamePhase.menu => _buildMenu(),
      _GamePhase.playing => _buildPlaying(),
      _GamePhase.finished => _buildFinished(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Screen 1: Menu
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMenu() {
    final cfg = _grades[_selectedGrade - 1];
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF92400E)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Number Detective',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF92400E),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero icon
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🔍', style: TextStyle(fontSize: 52)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Become a Number Detective!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use clues to uncover the mystery number. You have 3 attempts per case!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),

            // Grade selector
            Text(
              'Select Your Grade',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: List.generate(5, (i) {
                final g = i + 1;
                final selected = _selectedGrade == g;
                return _GradeButton(
                  grade: g,
                  selected: selected,
                  onTap: () => setState(() => _selectedGrade = g),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Grade description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grade ${ cfg.grade} — ${cfg.difficulty}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          'Numbers ${cfg.range} · ${cfg.minClues}–${cfg.maxClues} clues per puzzle',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Start button
            _AmberButton(
              label: 'Start Detective Mode!',
              icon: Icons.play_arrow_rounded,
              onTap: _startGame,
            ),
            const SizedBox(height: 16),

            // Instructions collapsible
            GestureDetector(
              onTap: () => setState(() => _showInstructions = !_showInstructions),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_showInstructions ? 'Hide' : 'Show'} Instructions',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    Icon(
                      _showInstructions ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ),
            if (_showInstructions) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _instructionItem('🔍', 'Clues appear one by one — read carefully!'),
                    _instructionItem('🎯', 'You have 3 attempts to guess the mystery number.'),
                    _instructionItem('💯', '1st correct: 100 pts · 2nd: 75 pts · 3rd: 50 pts'),
                    _instructionItem('⭐', '+10 bonus points for each clue you didn\'t need!'),
                    _instructionItem('📋', 'Solve 5 cases to complete an investigation.'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _instructionItem(String emoji, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Screen 2: Playing
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPlaying() {
    final cfg = _grades[_selectedGrade - 1];
    final puzzle = _puzzle;
    if (puzzle == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF92400E)),
          onPressed: () => context.pop(),
          tooltip: 'Back to Games',
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
          ).createShader(bounds),
          child: Text(
            'Number Detective',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => setState(() => _phase = _GamePhase.menu),
            child: Text(
              'Grade',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats row
            Row(
              children: [
                _StatBox(label: 'Score', value: '$_score', color: const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _StatBox(label: 'Cases Solved', value: '$_casesSolved', color: const Color(0xFF22C55E)),
                const SizedBox(width: 8),
                _StatBox(
                  label: 'Attempts Left',
                  value: '$_attemptsLeft',
                  color: _attemptsLeft == 1 ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mystery number card
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C1917), Color(0xFF292524)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('🔍', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    Text(
                      'MYSTERY NUMBER',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_revealed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${puzzle.mystery}',
                          style: GoogleFonts.montserrat(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFF59E0B),
                            letterSpacing: 4,
                          ),
                        ),
                      )
                    else
                      Text(
                        cfg.max >= 100 ? '???' : '??',
                        style: GoogleFonts.montserrat(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF59E0B),
                          letterSpacing: 8,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Range: ${cfg.range}',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clues card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🕵️ Clues',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(puzzle.clues.length, (i) {
                    final revealed = i < _revealedClues;
                    if (i >= _clueStates.length) return const SizedBox.shrink();
                    final cs = _clueStates[i];
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: cs.ctrl, curve: Curves.easeOut)),
                      child: FadeTransition(
                        opacity: cs.ctrl,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: revealed
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: revealed
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: revealed
                                      ? const Color(0xFFF59E0B)
                                      : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: revealed ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  revealed ? puzzle.clues[i].text : 'Clue loading...',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: revealed ? const Color(0xFF78350F) : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Guess input card
            if (!_revealed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _guessController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your guess',
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2.5),
                        ),
                      ),
                      onSubmitted: (_) => _checkAnswer(),
                    ),
                    const SizedBox(height: 12),
                    _AmberButton(
                      label: 'Check Answer',
                      icon: Icons.search_rounded,
                      onTap: _checkAnswer,
                    ),
                  ],
                ),
              ),

            // Feedback
            if (_showFeedback) ...[
              const SizedBox(height: 12),
              ScaleTransition(
                scale: _feedbackCorrect ? _bounceAnim : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _feedbackCorrect
                        ? const Color(0xFFDCFCE7)
                        : _revealed
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _feedbackCorrect
                          ? const Color(0xFF22C55E)
                          : _revealed
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _feedbackCorrect
                            ? Icons.check_circle_rounded
                            : _revealed
                                ? Icons.lightbulb_rounded
                                : Icons.cancel_rounded,
                        color: _feedbackCorrect
                            ? const Color(0xFF22C55E)
                            : _revealed
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _feedback,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            color: _feedbackCorrect
                                ? const Color(0xFF166534)
                                : _revealed
                                    ? const Color(0xFF92400E)
                                    : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Try another case after failure
            if (_revealed) ...[
              const SizedBox(height: 12),
              _AmberButton(
                label: 'Try Another Case',
                icon: Icons.refresh_rounded,
                onTap: _loadPuzzle,
              ),
            ],

            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _endInvestigation,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.grey),
              label: Text(
                'End Investigation',
                style: GoogleFonts.montserrat(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Screen 3: Finished
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFinished() {
    final rate = _totalCases == 0 ? 0 : (_casesSolved * 100 ~/ _totalCases);
    final emoji = _casesSolved >= 5 ? '🏆' : _casesSolved >= 3 ? '⭐' : '🔍';
    final message = rate >= 80
        ? 'Outstanding detective work! You\'re a number master!'
        : rate >= 60
            ? 'Great job! Keep practicing to become a master detective!'
            : rate >= 40
                ? 'Good effort! The more you practice, the better you\'ll get!'
                : 'Keep investigating! Every case makes you a better detective!';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text('🏆', style: const TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Investigation Complete!',
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF92400E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 24),

              // Detective Report card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '🕵️ Detective Report',
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _ReportStat(label: 'Final Score', value: '$_score', color: const Color(0xFFF59E0B)),
                        const SizedBox(width: 10),
                        _ReportStat(label: 'Cases Solved', value: '$_casesSolved', color: const Color(0xFF22C55E)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ReportStat(label: 'Total Cases', value: '$_totalCases', color: const Color(0xFF3B82F6)),
                        const SizedBox(width: 10),
                        _ReportStat(label: 'Success Rate', value: '$rate%', color: const Color(0xFF8B5CF6)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Motivational message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF78350F),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _AmberButton(
                      label: 'New Investigation',
                      icon: Icons.refresh_rounded,
                      onTap: _startGame,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _phase = _GamePhase.menu),
                      icon: const Icon(Icons.tune_rounded, color: Color(0xFFF59E0B)),
                      label: Text(
                        'Change Grade',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFF59E0B), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ClueState {
  final AnimationController ctrl;
  _ClueState({required this.ctrl});
}

class _GradeButton extends StatefulWidget {
  final int grade;
  final bool selected;
  final VoidCallback onTap;

  const _GradeButton({required this.grade, required this.selected, required this.onTap});

  @override
  State<_GradeButton> createState() => _GradeButtonState();
}

class _GradeButtonState extends State<_GradeButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.9).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFF59E0B),
              width: widget.selected ? 0 : 2,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              'G${ widget.grade}',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: widget.selected ? Colors.white : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmberButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AmberButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_AmberButton> createState() => _AmberButtonState();
}

class _AmberButtonState extends State<_AmberButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.95).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
