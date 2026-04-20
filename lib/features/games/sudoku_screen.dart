import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen>
    with TickerProviderStateMixin {
  // ── Puzzle state ─────────────────────────────────────────────────────────────
  List<List<int>> _puzzle = List.generate(4, (_) => List.filled(4, 0));
  List<List<int>> _solution = List.generate(4, (_) => List.filled(4, 0));
  List<List<int>> _playerGrid = List.generate(4, (_) => List.filled(4, 0));
  int? _selectedRow;
  int? _selectedCol;

  // ── Game state ───────────────────────────────────────────────────────────────
  bool _isComplete = false;
  int _score = 0;
  int _totalPuzzles = 0;
  int _streak = 0;
  int _bestStreak = 0;
  String _feedbackMessage = '';
  bool _isSoundEnabled = true;
  int _scoreKey = 0;
  int _streakKey = 0;

  Timer? _completionTimer;
  final Random _random = Random();

  // ── Animations ───────────────────────────────────────────────────────────────
  late final AnimationController _feedbackBounceAnim;
  late final AnimationController _boardShakeAnim;

  // ── Messages ─────────────────────────────────────────────────────────────────
  static const _completeMsgs = [
    "Amazing! You're a math wizard! 🧩 Sudoku Master!",
    "Fantastic work! Keep going! 🧩 Sudoku Master!",
    "Brilliant! You're on fire! 🧩 Sudoku Master!",
    "Excellent! Math genius! 🧩 Sudoku Master!",
    "Wonderful! You've got this! 🧩 Sudoku Master!",
    "Magical! Perfect grid! 🧩 Sudoku Master!",
    "Bullseye! Great solve! 🧩 Sudoku Master!",
    "Rainbow perfect! 🧩 Sudoku Master!",
  ];

  // ── Base grid for shuffled generation ────────────────────────────────────────
  static const _base = [
    [1, 2, 3, 4],
    [3, 4, 1, 2],
    [2, 1, 4, 3],
    [4, 3, 2, 1],
  ];

  static const _fallbackSolution = [
    [1, 2, 3, 4],
    [3, 4, 1, 2],
    [2, 1, 4, 3],
    [4, 3, 2, 1],
  ];

  // ── Colors ───────────────────────────────────────────────────────────────────
  static const _purple = Color(0xFF7C3AED);
  static const _prefillBg = Color(0xFFEEF0FB);
  static const _prefillText = Color(0xFF1A237E);
  static const _conflictBg = Color(0xFFFFEBEE);
  static const _conflictText = Color(0xFFD32F2F);
  static const _userText = Color(0xFF6D28D9);

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _feedbackBounceAnim = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _boardShakeAnim = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _loadNewPuzzle();
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _feedbackBounceAnim.dispose();
    _boardShakeAnim.dispose();
    super.dispose();
  }

  // ── Puzzle generation ────────────────────────────────────────────────────────

  List<List<int>> _generateSolution() {
    try {
      final nums = [1, 2, 3, 4]..shuffle(_random);
      return _base
          .map((row) => row.map((v) => nums[v - 1]).toList())
          .toList();
    } catch (_) {
      return _fallbackSolution
          .map((row) => List<int>.from(row))
          .toList();
    }
  }

  ({List<List<int>> puzzle, List<List<int>> solution}) _makePuzzle() {
    final solution = _generateSolution();
    final puzzle =
        solution.map((row) => List<int>.from(row)).toList();

    // Remove 8–10 cells randomly
    final cells = List.generate(16, (i) => i)..shuffle(_random);
    int removed = 0;
    final target = 8 + _random.nextInt(3); // 8, 9, or 10 empties
    for (final idx in cells) {
      if (removed >= target) break;
      puzzle[idx ~/ 4][idx % 4] = 0;
      removed++;
    }
    return (puzzle: puzzle, solution: solution);
  }

  void _loadNewPuzzle() {
    _completionTimer?.cancel();
    _feedbackBounceAnim.reset();

    final result = _makePuzzle();

    setState(() {
      _puzzle = result.puzzle;
      _solution = result.solution;
      _playerGrid =
          result.puzzle.map((row) => List<int>.from(row)).toList();
      _selectedRow = null;
      _selectedCol = null;
      _isComplete = false;
      _feedbackMessage = '';
      _totalPuzzles++;
    });
  }

  void _resetGame() {
    _playTapSound();
    _completionTimer?.cancel();
    setState(() {
      _score = 0;
      _totalPuzzles = 0;
      _streak = 0;
      _bestStreak = 0;
      _scoreKey = 0;
      _streakKey = 0;
    });
    _loadNewPuzzle();
  }

  // ── Conflict detection ───────────────────────────────────────────────────────

  Set<String> get _conflicts {
    final result = <String>{};
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final val = _playerGrid[r][c];
        if (val == 0) continue;
        // Row
        for (int cc = 0; cc < 4; cc++) {
          if (cc != c && _playerGrid[r][cc] == val) {
            result.add('$r,$c');
            result.add('$r,$cc');
          }
        }
        // Column
        for (int rr = 0; rr < 4; rr++) {
          if (rr != r && _playerGrid[rr][c] == val) {
            result.add('$r,$c');
            result.add('$rr,$c');
          }
        }
        // 2×2 box
        final br = (r ~/ 2) * 2;
        final bc = (c ~/ 2) * 2;
        for (int rr = br; rr < br + 2; rr++) {
          for (int cc = bc; cc < bc + 2; cc++) {
            if ((rr != r || cc != c) && _playerGrid[rr][cc] == val) {
              result.add('$r,$c');
              result.add('$rr,$cc');
            }
          }
        }
      }
    }
    return result;
  }

  // ── Completion check ─────────────────────────────────────────────────────────

  void _checkCompletion() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (_playerGrid[r][c] != _solution[r][c]) return;
      }
    }
    if (_isComplete) return;
    setState(() {
      _isComplete = true;
      _score++;
      _streak++;
      _scoreKey++;
      _streakKey++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      _feedbackMessage =
          _completeMsgs[_random.nextInt(_completeMsgs.length)];
      _selectedRow = null;
      _selectedCol = null;
    });
    _playCorrectSound();
    _feedbackBounceAnim.forward(from: 0);
    _completionTimer =
        Timer(const Duration(seconds: 3), () {
      if (mounted) _loadNewPuzzle();
    });
  }

  // ── Interaction ──────────────────────────────────────────────────────────────

  void _onCellTap(int row, int col) {
    if (_isComplete) return;
    _playTapSound();
    setState(() {
      if (_puzzle[row][col] != 0) {
        // Pre-filled: just deselect
        _selectedRow = null;
        _selectedCol = null;
      } else if (_selectedRow == row && _selectedCol == col) {
        // Already selected: deselect
        _selectedRow = null;
        _selectedCol = null;
      } else {
        _selectedRow = row;
        _selectedCol = col;
      }
    });
  }

  void _onNumberTap(int num) {
    if (_isComplete) return;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return;
    if (_puzzle[row][col] != 0) return;

    setState(() {
      _playerGrid[row][col] = num;
    });

    final conflicts = _conflicts;
    if (conflicts.contains('$row,$col')) {
      _playWrongSound();
      _boardShakeAnim.forward(from: 0);
    } else {
      _playTapSound();
    }
    _checkCompletion();
  }

  void _onClearTap() {
    if (_isComplete) return;
    final row = _selectedRow;
    final col = _selectedCol;
    if (row == null || col == null) return;
    if (_puzzle[row][col] != 0) return;
    _playTapSound();
    setState(() {
      _playerGrid[row][col] = 0;
    });
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
      await p.play(BytesSource(_makeToneWav(hz, 200, 0.06)));
      await Future.delayed(const Duration(milliseconds: 230));
      p.dispose();
    }
  }

  void _playTapSound() {
    if (!_isSoundEnabled) return;
    final p = AudioPlayer();
    p.play(BytesSource(_makeToneWav(800.0, 50, 0.04)));
    Future.delayed(const Duration(milliseconds: 250), p.dispose);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final conflicts = _conflicts;

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
                            Expanded(
                                child: _buildBoardSection(conflicts)),
                            const SizedBox(width: 20),
                            _buildPickerColumn(conflicts),
                          ],
                        );
                      }
                      return Column(children: [
                        _buildBoardSection(conflicts),
                        const SizedBox(height: 16),
                        _buildPickerRow(conflicts),
                      ]);
                    }),
                    const SizedBox(height: 16),
                    if (_isComplete) _buildFeedbackCard(),
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
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
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
            child: Text('Sudoku 4×4',
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
              color: _isSoundEnabled ? _purple : Colors.grey,
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
              value: '$_score / $_totalPuzzles',
              color: _purple,
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

  // ── Board section ────────────────────────────────────────────────────────────

  Widget _buildBoardSection(Set<String> conflicts) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _boardShakeAnim,
          builder: (_, child) {
            final x = sin(_boardShakeAnim.value * pi * 5) *
                8 *
                (1 - _boardShakeAnim.value);
            return Transform.translate(offset: Offset(x, 0), child: child);
          },
          child: _buildBoard(conflicts),
        ),
        const SizedBox(height: 10),
        if (!_isComplete)
          Text(
            _selectedRow != null
                ? 'Cell selected — tap a number below'
                : 'Tap an empty cell to select it',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: _purple.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  Widget _buildBoard(Set<String> conflicts) {
    return Center(
      child: LayoutBuilder(builder: (ctx, c) {
        final size = min(c.maxWidth, 320.0);
        return SizedBox(
          width: size,
          height: size,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _purple, width: 3),
              boxShadow: [
                BoxShadow(
                    color: _purple.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                children: [
                  // Top two rows (box row 0)
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildBox(0, 0, conflicts)),
                        Container(width: 3, color: _purple),
                        Expanded(child: _buildBox(0, 2, conflicts)),
                      ],
                    ),
                  ),
                  // Thick horizontal divider
                  Container(height: 3, color: _purple),
                  // Bottom two rows (box row 1)
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildBox(2, 0, conflicts)),
                        Container(width: 3, color: _purple),
                        Expanded(child: _buildBox(2, 2, conflicts)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBox(int r0, int c0, Set<String> conflicts) {
    return Column(
      children: [
        Expanded(
          child: Row(children: [
            Expanded(child: _buildCell(r0, c0, conflicts)),
            Container(
                width: 1, color: Colors.grey.shade300),
            Expanded(child: _buildCell(r0, c0 + 1, conflicts)),
          ]),
        ),
        Container(height: 1, color: Colors.grey.shade300),
        Expanded(
          child: Row(children: [
            Expanded(child: _buildCell(r0 + 1, c0, conflicts)),
            Container(
                width: 1, color: Colors.grey.shade300),
            Expanded(child: _buildCell(r0 + 1, c0 + 1, conflicts)),
          ]),
        ),
      ],
    );
  }

  Widget _buildCell(int row, int col, Set<String> conflicts) {
    final isPreFilled = _puzzle[row][col] != 0;
    final isSelected = _selectedRow == row && _selectedCol == col;
    final value = _playerGrid[row][col];
    final hasConflict = conflicts.contains('$row,$col');

    // Determine colors
    final Color bg;
    final Color textColor;

    if (isSelected) {
      bg = hasConflict ? const Color(0xFFC62828) : _purple;
      textColor = Colors.white;
    } else if (hasConflict) {
      bg = _conflictBg;
      textColor = _conflictText;
    } else if (isPreFilled) {
      bg = _prefillBg;
      textColor = _prefillText;
    } else if (value != 0) {
      bg = Colors.white;
      textColor = _userText;
    } else {
      bg = Colors.white;
      textColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: bg,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: value == 0
                ? const SizedBox.shrink()
                : Text(
                    '$value',
                    key: ValueKey('$row-$col-$value'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Number picker ────────────────────────────────────────────────────────────

  Widget _buildPickerRow(Set<String> conflicts) {
    if (_isComplete) return const SizedBox.shrink();
    return Row(
      children: [
        for (int n = 1; n <= 4; n++) ...[
          Expanded(child: _buildNumBtn(n)),
          const SizedBox(width: 8),
        ],
        Expanded(child: _buildClearBtn()),
      ],
    );
  }

  Widget _buildPickerColumn(Set<String> conflicts) {
    if (_isComplete) return const SizedBox.shrink();
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          for (int n = 1; n <= 4; n++) ...[
            _buildNumBtn(n, size: 64),
            const SizedBox(height: 8),
          ],
          _buildClearBtn(size: 64),
        ],
      ),
    );
  }

  Widget _buildNumBtn(int n, {double size = 60}) {
    final isActive = _selectedRow != null && _selectedCol != null &&
        _puzzle[_selectedRow!][_selectedCol!] == 0;
    return GestureDetector(
      onTap: () => _onNumberTap(n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: isActive ? null : const Color(0xFFE8E0FF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: _purple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Center(
          child: Text('$n',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : _purple)),
        ),
      ),
    );
  }

  Widget _buildClearBtn({double size = 60}) {
    return GestureDetector(
      onTap: _onClearTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text('✕',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF757575))),
        ),
      ),
    );
  }

  // ── Feedback card ─────────────────────────────────────────────────────────────

  Widget _buildFeedbackCard() {
    return AnimatedBuilder(
      animation: CurvedAnimation(
          parent: _feedbackBounceAnim, curve: Curves.easeOutBack),
      builder: (_, child) => Transform.translate(
        offset:
            Offset(0, (1 - _feedbackBounceAnim.value) * 40),
        child: Opacity(
            opacity: _feedbackBounceAnim.value.clamp(0.0, 1.0),
            child: child),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 16,
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
            Text('Next puzzle in 3 s — or tap below',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadNewPuzzle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF10B981),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Next Puzzle →',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
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
        foregroundColor: _purple,
        side: const BorderSide(color: _purple, width: 1.5),
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
