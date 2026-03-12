import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pattern generation
// ─────────────────────────────────────────────────────────────────────────────

class _Pattern {
  final List<List<bool>> original;
  final List<List<List<bool>>> options;
  final int correctIndex;
  const _Pattern({required this.original, required this.options, required this.correctIndex});
}

_Pattern _generatePattern() {
  final rng = Random();

  // Step 1 — random 5×5 original
  final original = List.generate(5, (_) => List.generate(5, (_) => rng.nextBool()));

  // Step 2 — correct: horizontal flip (reverse each row left-to-right)
  final horizFlip = original.map((row) => row.reversed.toList()).toList();

  // Step 3 — 3 wrong options
  // 1. Vertical flip — reverse row order
  final vertFlip = original.reversed.toList();

  // 2. 90° rotation — rotated[col][4-row] = original[row][col]
  final rotated = List.generate(5, (col) => List.generate(5, (row) => original[4 - row][col]));

  // 3. Random pattern
  final random = List.generate(5, (_) => List.generate(5, (_) => rng.nextBool()));

  // Step 4 — Fisher-Yates shuffle
  final all = <List<List<bool>>>[horizFlip, vertFlip, rotated, random];
  for (var i = all.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = all[i]; all[i] = all[j]; all[j] = tmp;
  }

  // Find correct index after shuffle
  int correctIndex = 0;
  outer:
  for (var i = 0; i < all.length; i++) {
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        if (all[i][r][c] != horizFlip[r][c]) continue outer;
      }
    }
    correctIndex = i;
    break;
  }

  return _Pattern(original: original, options: all, correctIndex: correctIndex);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MirrorImagesScreen extends StatefulWidget {
  const MirrorImagesScreen({super.key});
  @override
  State<MirrorImagesScreen> createState() => _MirrorImagesScreenState();
}

class _MirrorImagesScreenState extends State<MirrorImagesScreen> {
  late _Pattern _pattern;
  int? _selectedIndex;
  int _score = 0;
  int _level = 1;
  String? _feedback; // 'correct' | 'wrong' | null
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _pattern = _generatePattern();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _feedbackTimer?.cancel();
    setState(() {
      _score = 0;
      _level = 1;
      _selectedIndex = null;
      _feedback = null;
      _pattern = _generatePattern();
    });
  }

  void _selectOption(int index) {
    if (_feedback != null) return;
    setState(() => _selectedIndex = index);
    final correct = index == _pattern.correctIndex;
    setState(() {
      _feedback = correct ? 'correct' : 'wrong';
      if (correct) _score += 10;
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (correct) {
        setState(() {
          _level++;
          _selectedIndex = null;
          _feedback = null;
          _pattern = _generatePattern();
        });
      } else {
        setState(() {
          _selectedIndex = null;
          _feedback = null;
        });
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0FDFA), Color(0xFFF0FDF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 14),
                      _buildStatsBar(),
                      const SizedBox(height: 18),
                      _buildGameCard(),
                      const SizedBox(height: 16),
                      _buildFooter(),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0D9488)),
            label: Text('Games', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0D9488))),
          ),
          Expanded(
            child: Text(
              'Mirror Images',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0D9488)),
            ),
          ),
          GestureDetector(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Reset', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Mirror Images',
          style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF0D9488)),
        ),
        const SizedBox(height: 4),
        Text(
          'Find the correct mirror reflection',
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Row(
      children: [
        _StatCard(label: 'Level', value: '$_level', color: const Color(0xFF0D9488)),
        const SizedBox(width: 12),
        _StatCard(label: 'Score', value: '$_score pts', color: const Color(0xFF16A34A)),
      ],
    );
  }

  Widget _buildGameCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // ── Top: Original + flip icon + placeholder ──
          Text('Original Pattern', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF374151))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PatternGrid(grid: _pattern.original, cellSize: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 32, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 4),
                    Text('flip', style: GoogleFonts.montserrat(fontSize: 10, color: Colors.grey[400])),
                  ],
                ),
              ),
              _buildPlaceholder(),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE5E7EB), thickness: 1),
          const SizedBox(height: 14),

          // ── Bottom: Options ──
          Text(
            'Which one is the correct mirror image?',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF374151)),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.88,
            children: List.generate(4, (i) => _buildOptionCard(i)),
          ),
          const SizedBox(height: 12),
          if (_feedback != null) _buildFeedback(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    // Same size as the 5×5 grid: 5*24 + 4*4 + 2*8 = 120 + 16 + 16 = 152
    const size = 5 * 24.0 + 4 * 4.0 + 2 * 8.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5EEAD4), width: 2, style: BorderStyle.solid),
      ),
      child: Center(
        child: Text('?', style: GoogleFonts.montserrat(fontSize: 40, fontWeight: FontWeight.w900, color: const Color(0xFF5EEAD4))),
      ),
    );
  }

  Widget _buildOptionCard(int index) {
    final selected = _selectedIndex == index;
    final showCorrect = _feedback == 'correct' && selected;
    final showWrong = _feedback == 'wrong' && selected;

    Color borderColor;
    Color bgColor;
    if (showCorrect) {
      borderColor = const Color(0xFF16A34A);
      bgColor = const Color(0xFFF0FDF4);
    } else if (showWrong) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
    } else if (selected) {
      borderColor = const Color(0xFF0D9488);
      bgColor = const Color(0xFFF0FDFA);
    } else {
      borderColor = const Color(0xFFD1D5DB);
      bgColor = Colors.white;
    }

    return GestureDetector(
      onTap: _feedback != null ? null : () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(selected ? 1.05 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 2.5 : 1.5),
          boxShadow: selected
              ? [BoxShadow(color: borderColor.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Opacity(
          opacity: (_feedback != null && !selected) ? 0.5 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Option ${index + 1}',
                    style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? borderColor : const Color(0xFF6B7280)),
                  ),
                  if (showCorrect) ...[const SizedBox(width: 4), const Icon(Icons.check_circle, size: 13, color: Color(0xFF16A34A))],
                  if (showWrong)   ...[const SizedBox(width: 4), const Icon(Icons.cancel,       size: 13, color: Color(0xFFEF4444))],
                ],
              ),
              const SizedBox(height: 8),
              _PatternGrid(grid: _pattern.options[index], cellSize: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedback() {
    final correct = _feedback == 'correct';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(correct ? Icons.check_circle_rounded : Icons.info_rounded, size: 16,
            color: correct ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
        const SizedBox(width: 6),
        Text(
          correct ? 'Perfect! That\'s the correct mirror image!' : 'Not quite. Try again!',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: correct ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Text(
        'A mirror image is a horizontal flip of the original pattern. Look carefully and select the correct reflection!',
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(fontSize: 13, color: const Color(0xFF0F766E), height: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pattern grid
// ─────────────────────────────────────────────────────────────────────────────

class _PatternGrid extends StatelessWidget {
  final List<List<bool>> grid;
  final double cellSize;
  const _PatternGrid({required this.grid, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    const gap = 4.0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: grid.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: gap),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: row.map((cell) {
                return Padding(
                  padding: const EdgeInsets.only(right: gap),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: cell ? const Color(0xFF14B8A6) : Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: cell
                          ? [BoxShadow(color: const Color(0xFF14B8A6).withValues(alpha: 0.3), blurRadius: 3, offset: const Offset(0, 1))]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
