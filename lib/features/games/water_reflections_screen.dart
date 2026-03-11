import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _Pattern {
  final List<List<bool>> original;
  final List<List<List<bool>>> options;
  final int correctIndex;

  const _Pattern({
    required this.original,
    required this.options,
    required this.correctIndex,
  });
}

_Pattern _generatePattern() {
  final rng = Random();

  // Step 1 — random 5×5 original
  final original = List.generate(5, (_) => List.generate(5, (_) => rng.nextBool()));

  // Step 2 — correct answer: vertical flip (reverse row order)
  final verticalFlip = original.reversed.toList();

  // Step 3 — 3 wrong options
  // 1. Horizontal flip — reverse each row left-to-right
  final horizontalFlip = original.map((row) => row.reversed.toList()).toList();

  // 2. 90° rotation — rotated[col][4-row] = original[row][col]
  final rotated = List.generate(
    5,
    (col) => List.generate(5, (row) => original[4 - row][col]),
  );

  // 3. Completely random pattern
  final random = List.generate(5, (_) => List.generate(5, (_) => rng.nextBool()));

  // Step 4 — shuffle all 4
  final all = <List<List<bool>>>[verticalFlip, horizontalFlip, rotated, random];
  // Fisher-Yates shuffle
  for (var i = all.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = all[i];
    all[i] = all[j];
    all[j] = tmp;
  }

  // Find where verticalFlip landed
  int correctIndex = 0;
  for (var i = 0; i < all.length; i++) {
    bool match = true;
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        if (all[i][r][c] != verticalFlip[r][c]) {
          match = false;
          break;
        }
      }
      if (!match) break;
    }
    if (match) {
      correctIndex = i;
      break;
    }
  }

  return _Pattern(original: original, options: all, correctIndex: correctIndex);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class WaterReflectionsScreen extends StatefulWidget {
  const WaterReflectionsScreen({super.key});

  @override
  State<WaterReflectionsScreen> createState() => _WaterReflectionsScreenState();
}

class _WaterReflectionsScreenState extends State<WaterReflectionsScreen> {
  late _Pattern _pattern;
  int? _selectedIndex;
  int _score = 0;
  int _level = 1;
  String? _feedback; // 'correct' | 'wrong' | null

  @override
  void initState() {
    super.initState();
    _pattern = _generatePattern();
  }

  void _reset() {
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
    setState(() => _feedback = correct ? 'correct' : 'wrong');
    if (correct) setState(() => _score += 10);

    Future.delayed(const Duration(milliseconds: 1500), () {
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
            colors: [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
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
                      _buildInstructionsFooter(),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF2563EB)),
            label: Text(
              'Games',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Water Reflections',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D4ED8),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF2563EB)),
            label: Text(
              'Reset',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2563EB),
              ),
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
          'Water Reflections',
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1D4ED8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find the correct water reflection',
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Row(
      children: [
        _StatCard(label: 'Level', value: '$_level', color: const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        _StatCard(label: 'Score', value: '$_score pts', color: const Color(0xFF0891B2)),
      ],
    );
  }

  Widget _buildGameCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final useRow = screenWidth >= 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: useRow
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildOriginalColumn()),
                const SizedBox(width: 16),
                Expanded(child: _buildOptionsColumn()),
              ],
            )
          : Column(
              children: [
                _buildOriginalColumn(),
                const SizedBox(height: 20),
                _buildOptionsColumn(),
              ],
            ),
    );
  }

  // ── Left column ──

  Widget _buildOriginalColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Original Pattern',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        _PatternGrid(grid: _pattern.original, cellSize: 24),
        const SizedBox(height: 12),
        _buildWaterDivider(),
        const SizedBox(height: 12),
        _buildReflectionPlaceholder(),
      ],
    );
  }

  Widget _buildWaterDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.water_drop, size: 14, color: Color(0xFF60A5FA)),
        const SizedBox(width: 4),
        Flexible(
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF93C5FD), Color(0xFF22D3EE), Color(0xFF93C5FD)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Water',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF60A5FA),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF93C5FD), Color(0xFF22D3EE), Color(0xFF93C5FD)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.water_drop, size: 14, color: Color(0xFF60A5FA)),
      ],
    );
  }

  Widget _buildReflectionPlaceholder() {
    return Container(
      width: 5 * 24.0 + 4 * 3.0 + 16,
      height: 5 * 24.0 + 4 * 3.0 + 16,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF93C5FD),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFEFF6FF),
      ),
      child: Center(
        child: Text(
          '?',
          style: GoogleFonts.montserrat(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF93C5FD),
          ),
        ),
      ),
    );
  }

  // ── Right column ──

  Widget _buildOptionsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Which one is the correct water reflection?',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        // 2×2 grid of options
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: List.generate(4, (i) => _buildOptionCard(i)),
        ),
        const SizedBox(height: 14),
        if (_feedback != null) _buildFeedbackText(),
      ],
    );
  }

  Widget _buildOptionCard(int index) {
    final selected = _selectedIndex == index;
    final isCorrect = index == _pattern.correctIndex;
    final showCorrect = _feedback == 'correct' && selected;
    final showWrong = _feedback == 'wrong' && selected;

    Color borderColor;
    Color bgColor;
    if (showCorrect) {
      borderColor = const Color(0xFF22C55E);
      bgColor = const Color(0xFFF0FDF4);
    } else if (showWrong) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
    } else if (selected) {
      borderColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFEFF6FF);
    } else {
      borderColor = const Color(0xFFD1D5DB);
      bgColor = Colors.white;
    }

    return GestureDetector(
      onTap: _feedback != null ? null : () => _selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..scale(selected ? 1.04 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 2.5 : 1.5),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Option ${index + 1}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? borderColor : const Color(0xFF6B7280),
                  ),
                ),
                if (showCorrect) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF22C55E)),
                ],
                if (showWrong) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.cancel, size: 14, color: Color(0xFFEF4444)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            _PatternGrid(grid: _pattern.options[index], cellSize: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackText() {
    final correct = _feedback == 'correct';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          correct ? Icons.check_circle_rounded : Icons.info_rounded,
          size: 16,
          color: correct ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            correct
                ? 'Excellent! That\'s the correct water reflection!'
                : 'Not quite. Try again!',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: correct ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.water_drop_rounded, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A water reflection is a vertical flip of the original pattern, like seeing something reflected in water. The top becomes the bottom!',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF1E40AF),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pattern grid widget
// ─────────────────────────────────────────────────────────────────────────────

class _PatternGrid extends StatelessWidget {
  final List<List<bool>> grid;
  final double cellSize;

  const _PatternGrid({required this.grid, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    const gap = 3.0;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
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
                      color: cell ? const Color(0xFF3B82F6) : Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: cell
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              )
                            ]
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
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
