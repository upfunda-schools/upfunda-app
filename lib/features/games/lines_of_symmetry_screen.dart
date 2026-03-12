import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _orange = Color(0xFFEA580C);
const _orange500 = Color(0xFFF97316);
const _orange50 = Color(0xFFFFF7ED);

class _LineOption {
  final String id;
  final String label;
  const _LineOption(this.id, this.label);
}

const _lineOptions = [
  _LineOption('vertical',      'Vertical'),
  _LineOption('horizontal',    'Horizontal'),
  _LineOption('diagonal_down', 'Diagonal ↘'),
  _LineOption('diagonal_up',   'Diagonal ↙'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _Shape {
  final int type;
  final List<String> symmetryLines;
  final List<List<bool>> pattern;
  const _Shape({required this.type, required this.symmetryLines, required this.pattern});
}

// ─────────────────────────────────────────────────────────────────────────────
// Pattern generation
// ─────────────────────────────────────────────────────────────────────────────

List<List<bool>> _emptyGrid() => List.generate(6, (_) => List.filled(6, false));

_Shape _generateShape(int type) {
  final rng = Random();
  final grid = _emptyGrid();

  if (type == 1) {
    // Vertical symmetry: fill left 3 columns, mirror right
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 3; j++) {
        grid[i][j] = rng.nextBool();
        grid[i][5 - j] = grid[i][j];
      }
    }
  } else if (type == 2) {
    // Horizontal symmetry: fill top 3 rows, mirror bottom
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 6; j++) {
        grid[i][j] = rng.nextBool();
        grid[5 - i][j] = grid[i][j];
      }
    }
  } else {
    // Both: fill top-left 3×3, mirror right then bottom
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        grid[i][j] = rng.nextBool();
        grid[i][5 - j] = grid[i][j];
        grid[5 - i][j] = grid[i][j];
        grid[5 - i][5 - j] = grid[i][j];
      }
    }
  }

  final lines = _verifySymmetries(grid);
  return _Shape(type: type, symmetryLines: lines, pattern: grid);
}

List<String> _verifySymmetries(List<List<bool>> g) {
  final lines = <String>[];

  // Vertical: g[i][j] == g[i][5-j]
  if (_check(() { for (int i=0;i<6;i++) { for (int j=0;j<6;j++) {
    if(g[i][j]!=g[i][5-j]) return false;
  } } return true; })) {
    lines.add('vertical');
  }
  // Horizontal: g[i][j] == g[5-i][j]
  if (_check(() { for (int i=0;i<6;i++) { for (int j=0;j<6;j++) {
    if(g[i][j]!=g[5-i][j]) return false;
  } } return true; })) {
    lines.add('horizontal');
  }
  // Diagonal ↘: g[i][j] == g[j][i]
  if (_check(() { for (int i=0;i<6;i++) { for (int j=0;j<6;j++) {
    if(g[i][j]!=g[j][i]) return false;
  } } return true; })) {
    lines.add('diagonal_down');
  }
  // Diagonal ↙: g[i][j] == g[5-j][5-i]
  if (_check(() { for (int i=0;i<6;i++) { for (int j=0;j<6;j++) {
    if(g[i][j]!=g[5-j][5-i]) return false;
  } } return true; })) {
    lines.add('diagonal_up');
  }
  return lines;
}

bool _check(bool Function() fn) => fn();

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class LinesOfSymmetryScreen extends StatefulWidget {
  const LinesOfSymmetryScreen({super.key});
  @override
  State<LinesOfSymmetryScreen> createState() => _LinesOfSymmetryScreenState();
}

class _LinesOfSymmetryScreenState extends State<LinesOfSymmetryScreen>
    with TickerProviderStateMixin {

  late _Shape _currentShape;
  final Set<String> _selectedLines = {};
  int _score = 0;
  int _level = 1;
  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _showInstructions = false;

  // Shuffled type cycle
  final List<int> _typeOrder = [1, 2, 3];
  int _typeIndex = 0;

  // Help modal animation
  late AnimationController _helpCtrl;
  late Animation<Offset> _helpSlide;

  // Instruction box animations
  late List<AnimationController> _boxCtrls;
  late List<Animation<double>> _boxScales;
  late List<Animation<double>> _boxFades;

  Timer? _feedbackTimer;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _typeOrder.shuffle();

    _helpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _helpSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _helpCtrl, curve: Curves.easeOut));

    _boxCtrls = List.generate(4, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _boxScales = _boxCtrls.map((c) => TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.06), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
    _boxFades = _boxCtrls.map((c) => Tween<double>(begin: 0, end: 1).animate(c)).toList();

    _currentShape = _generateShape(_typeOrder[_typeIndex]);
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _scrollCtrl.dispose();
    _helpCtrl.dispose();
    for (final c in _boxCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _openInstructions() {
    setState(() => _showInstructions = true);
    _helpCtrl.forward(from: 0);
    for (var i = 0; i < _boxCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _boxCtrls[i].forward(from: 0);
      });
    }
  }

  void _closeInstructions() {
    _helpCtrl.reverse().then((_) {
      if (mounted) setState(() => _showInstructions = false);
    });
  }

  void _reset() {
    _feedbackTimer?.cancel();
    _typeOrder.shuffle();
    _typeIndex = 0;
    setState(() {
      _score = 0;
      _level = 1;
      _selectedLines.clear();
      _showFeedback = false;
      _isCorrect = false;
      _currentShape = _generateShape(_typeOrder[_typeIndex]);
    });
  }

  void _toggleLine(String id) {
    if (_showFeedback) return;
    setState(() {
      if (_selectedLines.contains(id)) {
        _selectedLines.remove(id);
      } else {
        _selectedLines.add(id);
      }
    });
  }

  void _checkAnswer() {
    if (_selectedLines.isEmpty || _showFeedback) return;
    final correct = _selectedLines.length == _currentShape.symmetryLines.length &&
        _selectedLines.every((id) => _currentShape.symmetryLines.contains(id));

    setState(() {
      _showFeedback = true;
      _isCorrect = correct;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });

    if (correct) {
      _feedbackTimer = Timer(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        _typeIndex++;
        if (_typeIndex >= _typeOrder.length) {
          _typeOrder.shuffle();
          _typeIndex = 0;
        }
        setState(() {
          _score += 10;
          _level++;
          _selectedLines.clear();
          _showFeedback = false;
          _currentShape = _generateShape(_typeOrder[_typeIndex]);
        });
      });
    }
  }

  void _tryAgain() {
    setState(() {
      _showFeedback = false;
      _selectedLines.clear();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFEFCE8), Color(0xFFFED7AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      children: [
                        _buildPatternSection(),
                        const SizedBox(height: 16),
                        _buildOptionsSection(),
                        const SizedBox(height: 14),
                        _buildCheckButton(),
                        const SizedBox(height: 12),
                        if (_showFeedback) _buildFeedbackCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Help modal overlay
          if (_showInstructions) _buildHelpModal(),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final isSmall = MediaQuery.of(context).size.width < 380;
    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _orange),
            label: Text('Games', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: _orange)),
          ),
          Expanded(
            child: Text(
              isSmall ? 'Symmetry' : 'Lines of Symmetry',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w800, color: _orange),
            ),
          ),
          // Level badge
          _Badge(label: 'L$_level', color: _orange),
          const SizedBox(width: 6),
          // Score badge
          _Badge(label: '$_score', color: const Color(0xFF16A34A)),
          const SizedBox(width: 6),
          // Help button
          _IconBtn(icon: Icons.help_outline_rounded, onTap: _openInstructions),
          const SizedBox(width: 4),
          // Reset button
          _IconBtn(icon: Icons.refresh_rounded, onTap: _reset),
        ],
      ),
    );
  }

  // ── Pattern display ────────────────────────────────────────────────────────

  Widget _buildPatternSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _orange.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text('Pattern', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[700])),
          const SizedBox(height: 12),
          Center(child: _PatternGrid(grid: _currentShape.pattern)),
        ],
      ),
    );
  }

  // ── Options ────────────────────────────────────────────────────────────────

  Widget _buildOptionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select all lines of symmetry:',
            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[800]),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: _lineOptions.map((opt) => _buildLineButton(opt)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineButton(_LineOption opt) {
    final selected = _selectedLines.contains(opt.id);
    return GestureDetector(
      onTap: _showFeedback ? null : () => _toggleLine(opt.id),
      child: Opacity(
        opacity: _showFeedback ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.diagonal3Values(selected ? 1.06 : 1.0, selected ? 1.06 : 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _orange50 : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _orange : const Color(0xFFD1D5DB), width: selected ? 2.5 : 1.5),
            boxShadow: selected
                ? [BoxShadow(color: _orange.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(painter: _LinePainter(lineId: opt.id, selected: selected)),
              ),
              const SizedBox(height: 6),
              Text(
                opt.label,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? _orange : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Check button ───────────────────────────────────────────────────────────

  Widget _buildCheckButton() {
    final disabled = _selectedLines.isEmpty || _showFeedback;
    return GestureDetector(
      onTap: disabled ? null : _checkAnswer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey[300] : _orange,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled ? null : [BoxShadow(color: _orange.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Text(
          'Check Answer',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: disabled ? Colors.grey[500] : Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Feedback card ──────────────────────────────────────────────────────────

  Widget _buildFeedbackCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: _isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            _isCorrect ? 'Excellent!' : 'Not Quite!',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isCorrect
                ? 'You found all the lines of symmetry!'
                : 'Some lines are missing or incorrect. Try again!',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: _isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
            ),
          ),
          if (!_isCorrect) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _tryAgain,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _orange.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text('Try Again', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Help modal ─────────────────────────────────────────────────────────────

  Widget _buildHelpModal() {
    return GestureDetector(
      onTap: _closeInstructions,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // prevent close on content tap
            child: SlideTransition(
              position: _helpSlide,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('How to Play', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w800, color: _orange)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _closeInstructions,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._helpBoxes().asMap().entries.map((e) {
                        return FadeTransition(
                          opacity: _boxFades[e.key],
                          child: ScaleTransition(
                            scale: _boxScales[e.key],
                            child: Padding(padding: const EdgeInsets.only(bottom: 12), child: e.value),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _helpBoxes() {
    return [
      _HelpBox(
        color: const Color(0xFFFEF9C3),
        borderColor: const Color(0xFFFDE047),
        title: 'What is a Line of Symmetry?',
        body: 'A line of symmetry divides a pattern into two mirror-image halves. If you fold the pattern along that line, both sides match perfectly!',
      ),
      _HelpBox(
        color: const Color(0xFFF9FAFB),
        borderColor: const Color(0xFFE5E7EB),
        title: 'Instructions:',
        items: const ['Look at the pattern carefully', 'Identify which lines divide it into mirror halves', 'Select all correct symmetry lines', 'Press Check Answer to verify'],
      ),
      _HelpBox(
        color: const Color(0xFFFFF7ED),
        borderColor: const Color(0xFFFED7AA),
        title: 'Line Types:',
        items: const [
          'Vertical — left half mirrors the right',
          'Horizontal — top half mirrors the bottom',
          'Diagonal ↘ — top-left mirrors bottom-right',
          'Diagonal ↙ — top-right mirrors bottom-left',
        ],
      ),
      _HelpBox(
        color: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFF86EFAC),
        title: 'Scoring:',
        body: '✅ +10 points for every correct answer\n🔁 No penalty for wrong answers — just try again!',
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pattern grid
// ─────────────────────────────────────────────────────────────────────────────

class _PatternGrid extends StatelessWidget {
  final List<List<bool>> grid;
  const _PatternGrid({required this.grid});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        const gap = 4.0;
        const padding = 10.0;
        final cellSize = ((available - padding * 2 - gap * 5) / 6).clamp(30.0, 48.0);

        return Container(
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: grid.asMap().entries.map((rowEntry) {
              return Padding(
                padding: EdgeInsets.only(bottom: rowEntry.key < 5 ? gap : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: rowEntry.value.asMap().entries.map((cellEntry) {
                    final cell = cellEntry.value;
                    return Padding(
                      padding: EdgeInsets.only(right: cellEntry.key < 5 ? gap : 0),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: cell ? _orange500 : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: cell
                              ? [BoxShadow(color: _orange500.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 2))]
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symmetry line painter
// ─────────────────────────────────────────────────────────────────────────────

class _LinePainter extends CustomPainter {
  final String lineId;
  final bool selected;
  const _LinePainter({required this.lineId, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const gridPad = 6.0;
    const cellGap = 2.0;
    final cellSize = (w - gridPad * 2 - cellGap * 5) / 6;

    // Draw mini 6×6 grid
    final bgPaint = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bgPaint);

    final cellPaint = Paint()..color = const Color(0xFFD1D5DB);
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        final x = gridPad + c * (cellSize + cellGap);
        final y = gridPad + r * (cellSize + cellGap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cellSize, cellSize), const Radius.circular(2)),
          cellPaint,
        );
      }
    }

    // Draw the symmetry line
    final linePaint = Paint()
      ..color = selected ? _orange : const Color(0xFF9CA3AF)
      ..strokeWidth = selected ? 3.0 : 2.0
      ..strokeCap = StrokeCap.round;

    switch (lineId) {
      case 'vertical':
        canvas.drawLine(Offset(w / 2, 2), Offset(w / 2, h - 2), linePaint);
        _drawArrow(canvas, linePaint, Offset(w / 2, 4), true);
        _drawArrow(canvas, linePaint, Offset(w / 2, h - 4), false);
        break;
      case 'horizontal':
        canvas.drawLine(Offset(2, h / 2), Offset(w - 2, h / 2), linePaint);
        _drawArrowH(canvas, linePaint, Offset(4, h / 2), true);
        _drawArrowH(canvas, linePaint, Offset(w - 4, h / 2), false);
        break;
      case 'diagonal_down':
        canvas.drawLine(const Offset(4, 4), Offset(w - 4, h - 4), linePaint);
        break;
      case 'diagonal_up':
        canvas.drawLine(Offset(w - 4, 4), Offset(4, h - 4), linePaint);
        break;
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset tip, bool up) {
    final dir = up ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 5, tip.dy + dir * 7)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 5, tip.dy + dir * 7);
    canvas.drawPath(path, paint);
  }

  void _drawArrowH(Canvas canvas, Paint paint, Offset tip, bool left) {
    final dir = left ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + dir * 7, tip.dy - 5)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + dir * 7, tip.dy + 5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.selected != selected;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)],
      ),
      child: Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _HelpBox extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String title;
  final String? body;
  final List<String>? items;
  const _HelpBox({required this.color, required this.borderColor, required this.title, this.body, this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey[800])),
          const SizedBox(height: 6),
          if (body != null)
            Text(body!, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700], height: 1.5)),
          if (items != null)
            ...items!.map((item) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: _orange, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700]))),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
