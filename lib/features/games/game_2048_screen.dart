import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({super.key});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const int _size = 4;
  static const String _bestScoreKey = '2048-best-score';

  List<List<int>> _grid = List.generate(4, (_) => List.filled(4, 0));
  int _score = 0;
  int _bestScore = 0;
  bool _hasWon = false;
  bool _showWinModal = false;
  bool _gameOver = false;

  Offset? _panStart;

  @override
  void initState() {
    super.initState();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
    });
    _newGame();
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestScoreKey, _bestScore);
  }

  void _newGame() {
    setState(() {
      _grid = List.generate(_size, (_) => List.filled(_size, 0));
      _score = 0;
      _hasWon = false;
      _showWinModal = false;
      _gameOver = false;
      _addRandomTile();
      _addRandomTile();
    });
  }

  void _addRandomTile() {
    final empties = <(int, int)>[];
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_grid[r][c] == 0) empties.add((r, c));
      }
    }
    if (empties.isEmpty) return;
    final rng = Random();
    final (r, c) = empties[rng.nextInt(empties.length)];
    _grid[r][c] = rng.nextDouble() < 0.9 ? 2 : 4;
  }

  (List<int>, int) _moveLeft(List<int> row) {
    final tiles = row.where((v) => v != 0).toList();
    final result = <int>[];
    int gained = 0;
    int i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
        final merged = tiles[i] * 2;
        result.add(merged);
        gained += merged;
        i += 2;
      } else {
        result.add(tiles[i]);
        i++;
      }
    }
    while (result.length < _size) { result.add(0); }
    return (result, gained);
  }

  List<List<int>> _transpose(List<List<int>> g) =>
      List.generate(_size, (r) => List.generate(_size, (c) => g[c][r]));

  List<List<int>> _reverseRows(List<List<int>> g) =>
      g.map((row) => row.reversed.toList()).toList();

  bool _move(String direction) {
    if (_gameOver) return false;

    List<List<int>> g = _grid.map((r) => List<int>.from(r)).toList();

    if (direction == 'right') g = _reverseRows(g);
    if (direction == 'up') g = _transpose(g);
    if (direction == 'down') {
      g = _transpose(g);
      g = _reverseRows(g);
    }

    int gained = 0;
    List<List<int>> newG = [];
    for (final row in g) {
      final (newRow, rowGained) = _moveLeft(row);
      newG.add(newRow);
      gained += rowGained;
    }

    if (direction == 'right') newG = _reverseRows(newG);
    if (direction == 'up') newG = _transpose(newG);
    if (direction == 'down') {
      newG = _reverseRows(newG);
      newG = _transpose(newG);
    }

    bool changed = false;
    for (int r = 0; r < _size && !changed; r++) {
      for (int c = 0; c < _size; c++) {
        if (newG[r][c] != _grid[r][c]) {
          changed = true;
          break;
        }
      }
    }
    if (!changed) return false;

    setState(() {
      _grid = newG;
      _score += gained;
      if (_score > _bestScore) {
        _bestScore = _score;
        _saveBestScore();
      }
      _addRandomTile();

      if (!_hasWon) {
        outer:
        for (final row in _grid) {
          for (final v in row) {
            if (v == 2048) {
              _hasWon = true;
              _showWinModal = true;
              break outer;
            }
          }
        }
      }

      _gameOver = _isGameOver();
    });

    return true;
  }

  bool _isGameOver() {
    for (final row in _grid) {
      if (row.contains(0)) return false;
    }
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (c + 1 < _size && _grid[r][c] == _grid[r][c + 1]) return false;
        if (r + 1 < _size && _grid[r][c] == _grid[r + 1][c]) return false;
      }
    }
    return true;
  }

  void _onPanStart(DragStartDetails details) {
    _panStart = details.globalPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    if (_panStart == null) return;
    final v = details.velocity.pixelsPerSecond;
    if (v.dx.abs() < 50 && v.dy.abs() < 50) return; // ignore tiny flicks
    if (v.dx.abs() > v.dy.abs()) {
      _move(v.dx > 0 ? 'right' : 'left');
    } else {
      _move(v.dy > 0 ? 'down' : 'up');
    }
    _panStart = null;
  }

  Color _tileColor(int value) {
    switch (value) {
      case 0:
        return const Color(0xFFCDC1B4);
      case 2:
        return const Color(0xFFB8D4E8);
      case 4:
        return const Color(0xFF8EC3D6);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      case 1024:
        return const Color(0xFF3DB446);
      case 2048:
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  Color _tileTextColor(int value) =>
      value <= 4 ? const Color(0xFF776E65) : Colors.white;

  double _tileFontSize(int value) {
    if (value < 100) return 26;
    if (value < 1000) return 20;
    return 15;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanEnd: _onPanEnd,
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildScoreRow(),
                  const SizedBox(height: 16),
                  _buildBoard(),
                  const SizedBox(height: 24),
                  _buildControls(),
                  const SizedBox(height: 16),
                  _buildHowToPlay(),
                ],
              ),
            ),
            if (_showWinModal) _buildWinModal(),
            if (_gameOver && !_showWinModal) _buildGameOverModal(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: const Color(0xFF776E65),
          ),
          Expanded(
            child: Text(
              '2048',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF776E65),
              ),
            ),
          ),
          IconButton(
            onPressed: _newGame,
            icon: const Icon(Icons.refresh_rounded),
            color: const Color(0xFF776E65),
            tooltip: 'New Game',
          ),
        ],
      ),
    );
  }

  // ── Score row ────────────────────────────────────────────────────────────────

  Widget _buildScoreRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _scoreCard('SCORE', _score)),
          const SizedBox(width: 12),
          Expanded(child: _scoreCard('BEST', _bestScore)),
        ],
      ),
    );
  }

  Widget _scoreCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFEEE4DA),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Board ────────────────────────────────────────────────────────────────────

  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFBBADA0),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: List.generate(
            _size,
            (r) => Row(
              children: List.generate(
                _size,
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: _tileColor(_grid[r][c]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: _grid[r][c] == 0
                              ? null
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(scale: anim, child: child),
                                  child: Text(
                                    '${_grid[r][c]}',
                                    key: ValueKey('$r$c${_grid[r][c]}'),
                                    style: GoogleFonts.montserrat(
                                      fontSize: _tileFontSize(_grid[r][c]),
                                      fontWeight: FontWeight.w900,
                                      color: _tileTextColor(_grid[r][c]),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Controls ─────────────────────────────────────────────────────────────────

  Widget _buildControls() {
    return Column(
      children: [
        _arrowBtn(Icons.keyboard_arrow_up_rounded, () => _move('up')),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _arrowBtn(Icons.keyboard_arrow_left_rounded, () => _move('left')),
            const SizedBox(width: 56),
            _arrowBtn(Icons.keyboard_arrow_right_rounded, () => _move('right')),
          ],
        ),
        _arrowBtn(Icons.keyboard_arrow_down_rounded, () => _move('down')),
      ],
    );
  }

  Widget _arrowBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFBBADA0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildHowToPlay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Text(
        'Swipe or use arrow buttons to move tiles. Merge matching numbers to reach 2048!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
    );
  }

  // ── Modals ───────────────────────────────────────────────────────────────────

  Widget _buildWinModal() {
    return _modalShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(
            'You Win!',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You reached 2048! Keep playing to achieve a higher score.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _modalBtn(
            label: 'Keep Playing',
            color: const Color(0xFF2E7D32),
            onTap: () => setState(() => _showWinModal = false),
          ),
          const SizedBox(height: 10),
          _modalOutlineBtn(label: 'New Game', onTap: _newGame),
        ],
      ),
    );
  }

  Widget _buildGameOverModal() {
    return _modalShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Game Over!',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No more moves available.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Score: $_score',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF776E65),
            ),
          ),
          const SizedBox(height: 20),
          _modalBtn(
            label: 'Try Again',
            color: Colors.red[700]!,
            onTap: _newGame,
          ),
        ],
      ),
    );
  }

  Widget _modalShell({required Widget child}) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _modalBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _modalOutlineBtn({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
