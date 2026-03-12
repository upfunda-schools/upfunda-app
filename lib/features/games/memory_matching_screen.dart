import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kEmojis = ['🎨', '🎭', '🎪', '🎯', '🎲', '🎸', '🎺', '🎹'];
const _kPurple = Color(0xFF7C3AED);
const _kPink   = Color(0xFFEC4899);

class _Card {
  final String emoji;
  bool isFlipped;
  bool isMatched;
  _Card(this.emoji) : isFlipped = false, isMatched = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MemoryMatchingScreen extends StatefulWidget {
  const MemoryMatchingScreen({super.key});
  @override
  State<MemoryMatchingScreen> createState() => _MemoryMatchingScreenState();
}

class _MemoryMatchingScreenState extends State<MemoryMatchingScreen> {
  List<_Card> _cards = [];
  final List<int> _flipped = [];
  int _moves = 0;
  int _matches = 0;
  bool _isComplete = false;
  bool _busy = false;
  int _generation = 0; // forces GridView state recreation on reset

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final emojis = [..._kEmojis, ..._kEmojis]..shuffle(Random());
    _cards = emojis.map((e) => _Card(e)).toList();
    _flipped.clear();
    _moves = 0;
    _matches = 0;
    _isComplete = false;
    _busy = false;
    _generation++;
  }

  void _onTap(int index) {
    if (_busy) return;
    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;

    setState(() {
      card.isFlipped = true;
      _flipped.add(index);
      if (_flipped.length == 2) {
        _moves++;
        _busy = true;
      }
    });

    if (_flipped.length == 2) _evaluate();
  }

  void _evaluate() {
    final a = _cards[_flipped[0]];
    final b = _cards[_flipped[1]];

    if (a.emoji == b.emoji) {
      setState(() {
        a.isMatched = true;
        b.isMatched = true;
        _matches++;
        _flipped.clear();
        _busy = false;
        if (_matches == 8) _isComplete = true;
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted || _flipped.length < 2) return;
        setState(() {
          _cards[_flipped[0]].isFlipped = false;
          _cards[_flipped[1]].isFlipped = false;
          _flipped.clear();
          _busy = false;
        });
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _header(),
                  _titleSection(),
                  _statsRow(),
                  const SizedBox(height: 8),
                  Expanded(child: _grid()),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (_isComplete) _victoryModal(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _kPurple),
            label: Text('Back to Games',
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: _kPurple)),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => setState(() => _initGame()),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text('Reset', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Memory Matching',
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF333333))),
          Text('Match all the pairs!', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statCard('Moves', '$_moves', _kPurple),
          const SizedBox(width: 16),
          _statCard('Matches', '$_matches/8', _kPink),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  Widget _grid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        key: ValueKey(_generation),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: 16,
        itemBuilder: (_, i) => _CardTile(
          key: ValueKey(i),
          emoji: _cards[i].emoji,
          isFlipped: _cards[i].isFlipped,
          isMatched: _cards[i].isMatched,
          onTap: () => _onTap(i),
        ),
      ),
    );
  }

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
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('Congratulations!',
                  style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: _kPurple)),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                  children: [
                    const TextSpan(text: 'You completed the game in '),
                    TextSpan(
                      text: '$_moves moves',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: _kPurple),
                    ),
                    const TextSpan(text: '!'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _initGame()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Play Again', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Back', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card tile — StatelessWidget, flip driven by TweenAnimationBuilder
// No AnimationController, no late fields, no initialization issues.
// ─────────────────────────────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final String emoji;
  final bool isFlipped;
  final bool isMatched;
  final VoidCallback onTap;

  const _CardTile({
    super.key,
    required this.emoji,
    required this.isFlipped,
    required this.isMatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (isFlipped || isMatched) ? null : onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: isFlipped ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (_, value, __) {
          final angle = value * pi;
          final showFront = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(showFront ? angle - pi : angle),
            child: showFront ? _front() : _back(),
          );
        },
      ),
    );
  }

  Widget _front() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: Opacity(
          opacity: isMatched ? 0.4 : 1.0,
          child: Text(emoji, style: const TextStyle(fontSize: 30)),
        ),
      ),
    );
  }

  Widget _back() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPurple, _kPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: _kPurple.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: Text('?',
            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }
}
