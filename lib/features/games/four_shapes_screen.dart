import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _maxColumnHeight = 4;
const _shapeTypes = ['circle', 'square', 'triangle', 'hexagon'];

const _shapeColors = {
  'circle': Color(0xFF3B82F6),
  'square': Color(0xFF22C55E),
  'triangle': Color(0xFFEF4444),
  'hexagon': Color(0xFFEAB308),
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class FourShapesScreen extends StatefulWidget {
  const FourShapesScreen({super.key});

  @override
  State<FourShapesScreen> createState() => _FourShapesScreenState();
}

// Tracks which specific shape is selected
class _Selection {
  final int col;
  final int row; // index within the column list
  const _Selection(this.col, this.row);
}

class _FourShapesScreenState extends State<FourShapesScreen> with TickerProviderStateMixin {
  // ── State ──
  late List<List<String>> _columns;
  _Selection? _selection; // which shape tile is selected
  int _moves = 0;
  int _level = 1;
  bool _isComplete = false;

  // ── Animations ──
  late AnimationController _modalCtrl;
  late Animation<double> _modalAnim;

  @override
  void initState() {
    super.initState();
    _modalCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _modalAnim = CurvedAnimation(parent: _modalCtrl, curve: Curves.easeOut);
    _generatePuzzle();
  }

  @override
  void dispose() {
    _modalCtrl.dispose();
    super.dispose();
  }

  // ── Game logic ──

  void _generatePuzzle() {
    final shapes = <String>[];
    for (final type in _shapeTypes) {
      shapes.addAll([type, type, type]);
    }
    shapes.shuffle(Random());

    setState(() {
      _columns = List.generate(4, (i) => shapes.sublist(i * 3, i * 3 + 3));
      _moves = 0;
      _isComplete = false;
      _selection = null;
    });
    _modalCtrl.reset();
  }

  void _checkCompletion() {
    if (_moves == 0) return;
    final done = _columns.every((col) {
      if (col.length != 3) return false;
      return col.every((s) => s == col.first);
    });
    if (done) {
      setState(() => _isComplete = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _modalCtrl.forward();
      });
    }
  }

  // Tap a specific shape tile to select it
  void _handleShapeTap(int colIndex, int rowIndex) {
    if (_isComplete) return;
    final sel = _selection;
    if (sel != null && sel.col == colIndex && sel.row == rowIndex) {
      // Tapped same shape — deselect
      setState(() => _selection = null);
      return;
    }
    setState(() => _selection = _Selection(colIndex, rowIndex));
  }

  // Tap a column (empty area or a different shape) to move the selected shape there
  void _handleColumnTap(int targetCol) {
    if (_isComplete) return;
    final sel = _selection;
    if (sel == null) return; // nothing selected yet

    if (sel.col == targetCol) {
      // Tapped same column — deselect
      setState(() => _selection = null);
      return;
    }
    if (_columns[targetCol].length >= _maxColumnHeight) {
      // Target full — deselect
      setState(() => _selection = null);
      return;
    }

    setState(() {
      final shape = _columns[sel.col].removeAt(sel.row);
      _columns[targetCol].insert(0, shape);
      _moves++;
      _selection = null;
    });
    _checkCompletion();
  }

  void _resetGame() {
    setState(() {
      _level = 1;
      _selection = null;
    });
    _generatePuzzle();
  }

  void _nextLevel() {
    setState(() => _level++);
    _generatePuzzle();
  }

  // ── Column styling ──

  Color _columnBorderColor(int i) {
    if (_selection?.col == i) return const Color(0xFF3B82F6);
    if (_selection != null && _selection!.col != i) return const Color(0xFF22C55E);
    return const Color(0xFFD1D5DB);
  }

  Color _columnBgColor(int i) {
    if (_selection?.col == i) return const Color(0xFFEFF6FF);
    if (_selection != null && _selection!.col != i) return const Color(0xFFF0FDF4);
    return Colors.white;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFCFFAFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 12),
                          _buildInstructions(),
                          const SizedBox(height: 16),
                          _buildBoard(),
                          const SizedBox(height: 16),
                          _buildLegend(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isComplete)
                FadeTransition(opacity: _modalAnim, child: _buildModal()),
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
              'Four Shapes',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _resetGame,
            icon: const Icon(Icons.restart_alt_rounded, size: 18, color: Color(0xFF2563EB)),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(label: 'Level', value: '$_level', color: const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        _StatCard(label: 'Moves', value: '$_moves', color: const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap any shape to select it (glows blue), then tap another column to move it there. '
              'Sort all shapes so each column has only one type!',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF1E40AF),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) => _buildColumn(i)),
      ),
    );
  }

  Widget _buildColumn(int colIndex) {
    final col = _columns[colIndex];
    final isSourceCol = _selection?.col == colIndex;
    final isDropTarget = _selection != null && !isSourceCol;
    final borderColor = _columnBorderColor(colIndex);
    final bgColor = _columnBgColor(colIndex);

    return GestureDetector(
      // Tapping the column background (empty slots) triggers a move
      onTap: () => _handleColumnTap(colIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        height: _maxColumnHeight * 64.0 + 16,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: isSourceCol || isDropTarget ? 2.5 : 1.5,
          ),
          boxShadow: isSourceCol
              ? [BoxShadow(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Empty slots at top (tapping these also triggers move)
              ...List.generate(_maxColumnHeight - col.length, (_) => _emptySlot()),
              // Shape tiles — each individually tappable
              ...col.asMap().entries.map((e) {
                final rowIdx = e.key;
                final shape = e.value;
                final isThisSelected = _selection?.col == colIndex && _selection?.row == rowIdx;
                return _buildShapeTile(shape, colIndex, rowIdx, isThisSelected, isSourceCol);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptySlot() {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
    );
  }

  Widget _buildShapeTile(String shape, int colIndex, int rowIndex, bool isSelected, bool isSourceCol) {
    final color = _shapeColors[shape] ?? Colors.grey;
    return GestureDetector(
      onTap: () {
        if (_selection != null && _selection!.col != colIndex) {
          // A shape from another column is selected — move it here
          _handleColumnTap(colIndex);
        } else {
          // Select/deselect this shape
          _handleShapeTap(colIndex, rowIndex);
        }
      },
      child: _ShapeTile(
        shape: shape,
        color: color,
        isSelected: isSelected,
        isSource: isSourceCol,
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _shapeTypes.map((shape) {
          final color = _shapeColors[shape]!;
          return Column(
            children: [
              _shapeIcon(shape, 28, color),
              const SizedBox(height: 4),
              Text(
                shape[0].toUpperCase() + shape.substring(1),
                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🏆', style: TextStyle(fontSize: 44))),
              ),
              const SizedBox(height: 16),
              Text(
                'Puzzle Complete!',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Solved in $_moves move${_moves == 1 ? '' : 's'}!',
                style: GoogleFonts.montserrat(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _ModalButton(
                label: 'Next Level →',
                color: const Color(0xFF3B82F6),
                onTap: _nextLevel,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                  side: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Back to Games',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shape tile widget
// ─────────────────────────────────────────────────────────────────────────────

class _ShapeTile extends StatelessWidget {
  final String shape;
  final Color color;
  final bool isSelected; // this specific tile is selected
  final bool isSource;   // its column is the source column

  const _ShapeTile({
    required this.shape,
    required this.color,
    required this.isSelected,
    required this.isSource,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 56,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 3),
      transform: isSelected ? (Matrix4.identity()..scale(1.08)) : Matrix4.identity(),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.5),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))]
            : [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Center(child: _shapeIcon(shape, 30, color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shape icon factory
// ─────────────────────────────────────────────────────────────────────────────

Widget _shapeIcon(String shape, double size, Color color) {
  switch (shape) {
    case 'circle':
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    case 'square':
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      );
    case 'triangle':
      return CustomPaint(
        size: Size(size, size),
        painter: _TrianglePainter(color: color),
      );
    case 'hexagon':
      return CustomPaint(
        size: Size(size, size),
        painter: _HexagonPainter(color: color),
      );
    default:
      return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters
// ─────────────────────────────────────────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexagonPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModalButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
