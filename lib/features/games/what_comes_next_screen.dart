import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _Item {
  final String value;
  final Color color;
  const _Item(this.value, this.color);

  bool matches(_Item other) => value == other.value && color.toARGB32() == other.color.toARGB32();
}

class _Sequence {
  final List<_Item> items;
  final List<_Item> options;
  final _Item answer;
  const _Sequence({required this.items, required this.options, required this.answer});
}

// ── Screen ────────────────────────────────────────────────────────────────────

class WhatComesNextScreen extends StatefulWidget {
  const WhatComesNextScreen({super.key});

  @override
  State<WhatComesNextScreen> createState() => _WhatComesNextScreenState();
}

class _WhatComesNextScreenState extends State<WhatComesNextScreen> {
  static const _blue   = Color(0xFF2196F3);
  static const _purple = Color(0xFF9C27B0);

  static const _shapes = ['●', '■', '▲', '★', '◆', '♥'];

  static const _palette = [
    Color(0xFFF44336), // red
    Color(0xFF2196F3), // blue
    Color(0xFF4CAF50), // green
    Color(0xFFFFC107), // yellow/amber
    Color(0xFF9C27B0), // purple
    Color(0xFFE91E63), // pink
  ];

  final _rng = Random();

  int _score = 0;
  int _level = 1;
  _Item? _selected;
  String? _feedback; // "correct" | "wrong"
  _Sequence? _seq;
  bool _busy = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _seq = _buildSequence();
  }

  void _reset() {
    setState(() {
      _score = 0;
      _level = 1;
      _selected = null;
      _feedback = null;
      _busy = false;
      _seq = _buildSequence();
    });
  }

  // ── Sequence generation ────────────────────────────────────────────────────

  _Sequence _buildSequence() {
    switch (_rng.nextInt(5)) {
      case 0:  return _constantStep();
      case 1:  return _incrementingStep();
      case 2:  return _twoShapePattern();
      case 3:  return _threeShapePattern();
      default: return _colorPattern();
    }
  }

  _Sequence _constantStep() {
    final start = _rng.nextInt(5) + 1; // 1–5
    final step  = _rng.nextInt(3) + 1; // 1–3
    final items  = List.generate(4, (i) => _Item('${start + i * step}', _blue));
    final ans    = start + 4 * step;
    final answer = _Item('$ans', _blue);

    final wrongs = <int>{};
    while (wrongs.length < 3) {
      final v = _rng.nextInt(20) + 1;
      if (v != ans) wrongs.add(v);
    }

    return _Sequence(
      items: items,
      options: _shuffled([answer, ...wrongs.map((v) => _Item('$v', _blue))]),
      answer: answer,
    );
  }

  _Sequence _incrementingStep() {
    final start    = _rng.nextInt(3) + 1; // 1–3
    final initStep = _rng.nextInt(2) + 1; // 1–2

    final vals = [start];
    for (int i = 0; i < 4; i++) {
      vals.add(vals.last + initStep + i);
    }

    final items  = vals.take(4).map((v) => _Item('$v', _blue)).toList();
    final ans    = vals[4];
    final answer = _Item('$ans', _blue);
    final lastStep = initStep + 3;

    final wrongs = <int>{ans + 1, (ans - 1 > 0 ? ans - 1 : ans + 2)};
    final minus = ans - lastStep;
    if (minus > 0 && minus != ans) wrongs.add(minus);
    while (wrongs.length < 3) {
      final v = _rng.nextInt(30) + 1;
      if (v != ans) wrongs.add(v);
    }

    return _Sequence(
      items: items,
      options: _shuffled([answer, ...wrongs.take(3).map((v) => _Item('$v', _blue))]),
      answer: answer,
    );
  }

  _Sequence _twoShapePattern() {
    final s = List<String>.from(_shapes)..shuffle(_rng);
    final a = s[0]; final b = s[1];
    final items  = [a, b, a, b, a].map((x) => _Item(x, _purple)).toList();
    final answer = _Item(b, _purple); // 5 % 2 = 1 → b
    return _Sequence(
      items: items,
      options: _shuffled([answer, ...s.skip(2).take(3).map((x) => _Item(x, _purple))]),
      answer: answer,
    );
  }

  _Sequence _threeShapePattern() {
    final s = List<String>.from(_shapes)..shuffle(_rng);
    final a = s[0]; final b = s[1]; final c = s[2];
    final items  = [a, b, c, a, b, c].map((x) => _Item(x, _purple)).toList();
    final answer = _Item(a, _purple); // 6 % 3 = 0 → a
    return _Sequence(
      items: items,
      options: _shuffled([answer, ...s.skip(3).take(3).map((x) => _Item(x, _purple))]),
      answer: answer,
    );
  }

  _Sequence _colorPattern() {
    final shape  = _shapes[_rng.nextInt(_shapes.length)];
    final idx    = List<int>.generate(6, (i) => i)..shuffle(_rng);
    final cA     = _palette[idx[0]];
    final cB     = _palette[idx[1]];
    final items  = [cA, cB, cA, cB, cA].map((c) => _Item(shape, c)).toList();
    final answer = _Item(shape, cB);
    return _Sequence(
      items: items,
      options: _shuffled([answer, ...idx.skip(2).take(3).map((i) => _Item(shape, _palette[i]))]),
      answer: answer,
    );
  }

  List<_Item> _shuffled(List<_Item> list) => list..shuffle(_rng);

  // ── Input handling ─────────────────────────────────────────────────────────

  void _onTap(_Item option) {
    if (_busy || _feedback != null) return;
    final correct = option.matches(_seq!.answer);

    setState(() {
      _busy = true;
      _selected = option;
      _feedback = correct ? 'correct' : 'wrong';
      if (correct) _score += 10;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _selected = null;
        _feedback = null;
        if (correct) {
          _level++;
          _seq = _buildSequence();
        }
      });
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              _titleSection(),
              _statsRow(),
              const SizedBox(height: 16),
              _sequenceCard(),
              const SizedBox(height: 16),
              _instructions(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: const Text('Back to Games'),
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

  // ── Title ──────────────────────────────────────────────────────────────────

  Widget _titleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Comes Next?',
            style: GoogleFonts.montserrat(
              fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Identify the pattern and predict the next item',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statCard('Level', '$_level', const Color(0xFFFF9800)),
          const SizedBox(width: 16),
          _statCard('Score', '$_score', const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color valueColor) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w900, color: valueColor),
          ),
        ],
      ),
    );
  }

  // ── Sequence card ──────────────────────────────────────────────────────────

  Widget _sequenceCard() {
    if (_seq == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What comes next in this sequence?',
                style: GoogleFonts.montserrat(
                  fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 16),
              _sequenceRow(),
              const SizedBox(height: 20),
              _optionsRow(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _feedback == null
                    ? const SizedBox(key: ValueKey('none'))
                    : Padding(
                        key: ValueKey(_feedback),
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: Text(
                            _feedback == 'correct'
                                ? '🎉 Excellent! You found the pattern!'
                                : '🤔 Not quite. Look for the pattern!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _feedback == 'correct' ? const Color(0xFF2E7D32) : Colors.red[700],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sequence row ───────────────────────────────────────────────────────────

  Widget _sequenceRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in _seq!.items) ...[
            _seqTile(item),
            _arrowWidget(),
          ],
          _questionMark(),
        ],
      ),
    );
  }

  Widget _seqTile(_Item item) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(item.value, style: TextStyle(fontSize: 26, color: item.color, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _arrowWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text('→', style: TextStyle(fontSize: 18, color: Colors.grey[400])),
    );
  }

  Widget _questionMark() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800), width: 2),
      ),
      child: const Center(
        child: Text('?', style: TextStyle(fontSize: 26, color: Color(0xFFFF9800), fontWeight: FontWeight.w900)),
      ),
    );
  }

  // ── Options row ────────────────────────────────────────────────────────────

  Widget _optionsRow() {
    return Row(
      children: _seq!.options.map((opt) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AspectRatio(aspectRatio: 1, child: _optionTile(opt)),
        ),
      )).toList(),
    );
  }

  Widget _optionTile(_Item option) {
    final isSelected = _selected != null && option.matches(_selected!);
    final scale = isSelected ? 1.08 : 1.0;

    return GestureDetector(
      onTap: () => _onTap(option),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF9800) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              option.value,
              style: TextStyle(fontSize: 24, color: option.color, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  // ── Instructions ───────────────────────────────────────────────────────────

  Widget _instructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Look carefully at the sequence and find the pattern. What should come next?',
                style: TextStyle(fontSize: 13, color: Colors.orange[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
