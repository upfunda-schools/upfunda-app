import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultiplicationTablesScreen extends StatefulWidget {
  const MultiplicationTablesScreen({super.key});

  @override
  State<MultiplicationTablesScreen> createState() =>
      _MultiplicationTablesScreenState();
}

class _MultiplicationTablesScreenState
    extends State<MultiplicationTablesScreen> with TickerProviderStateMixin {
  // ── Question state ──────────────────────────────────────────────────────────
  int _table = 1;
  int _multiplier = 1;
  int _correctAnswer = 1;

  // ── Game state ──────────────────────────────────────────────────────────────
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _showTable = false;
  int _score = 0;
  int _totalQuestions = 0;
  int _streak = 0;
  int _bestStreak = 0;
  String _feedbackMessage = '';
  bool _isSoundEnabled = true;

  int _scoreKey = 0;
  int _streakKey = 0;

  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();

  // ── Animations ──────────────────────────────────────────────────────────────
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  late final AnimationController _tableAnim;

  // ── Messages ────────────────────────────────────────────────────────────────
  static const _correctMsgs = [
    'Amazing work! 🌟', "You're on fire! 🔥", 'Brilliant! 💪',
    'Fantastic! ⭐', 'Perfect! 🚀', 'Excellent! 🎯',
    'Super! 🎉', 'Outstanding! 🏆',
  ];
  static const _incorrectMsgs = [
    'Good try! 💪', 'Almost there! 🌟',
    'Keep going! 📚', "Don't give up! 🎯",
    'Nice effort! ✨', 'So close! 🔥',
    'Try again! 💡', "You'll get it! 🌈",
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _questionAnim = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this, value: 1.0);
    _questionFade =
        CurvedAnimation(parent: _questionAnim, curve: Curves.easeInOut);
    _questionSlide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _questionAnim, curve: Curves.easeOut));

    _tableAnim = AnimationController(
        duration: const Duration(milliseconds: 320), vsync: this);

    // Rebuild when text changes (enables/disables Check button)
    _answerController.addListener(() => setState(() {}));

    _generateQuestion();
  }

  @override
  void dispose() {
    _questionAnim.dispose();
    _tableAnim.dispose();
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Question generation ─────────────────────────────────────────────────────
  void _generateQuestion() {
    final table = _random.nextInt(12) + 1;
    final multiplier = _random.nextInt(12) + 1;

    setState(() {
      _table = table;
      _multiplier = multiplier;
      _correctAnswer = table * multiplier;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });

    _answerController.clear();
    _questionAnim.forward(from: 0);
  }

  // ── Table toggle ────────────────────────────────────────────────────────────
  void _toggleTable() {
    setState(() => _showTable = !_showTable);
    _showTable ? _tableAnim.forward() : _tableAnim.reverse();
  }

  // ── Answer checking ─────────────────────────────────────────────────────────
  void _checkAnswer() {
    final userAnswer = int.tryParse(_answerController.text.trim());
    if (userAnswer == null || _isAnswered) return;

    final correct = userAnswer == _correctAnswer;

    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
      _totalQuestions++;
      if (correct) {
        _score++;
        _streak++;
        _scoreKey++;
        _streakKey++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        _feedbackMessage =
            _correctMsgs[_random.nextInt(_correctMsgs.length)];
      } else {
        _streak = 0;
        _streakKey++;
        _feedbackMessage =
            _incorrectMsgs[_random.nextInt(_incorrectMsgs.length)];
      }
    });

    _focusNode.unfocus();

    if (_isSoundEnabled) {
      correct
          ? HapticFeedback.lightImpact()
          : HapticFeedback.heavyImpact();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = _totalQuestions == 0
        ? 0.0
        : (_score / _totalQuestions).clamp(0.0, 1.0);
    final hasInput = _answerController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 16, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Times table grid (animated show/hide)
                        ClipRect(
                          child: SizeTransition(
                            sizeFactor: CurvedAnimation(
                                parent: _tableAnim,
                                curve: Curves.easeInOut),
                            axisAlignment: -1,
                            child: FadeTransition(
                              opacity: CurvedAnimation(
                                  parent: _tableAnim,
                                  curve: Curves.easeInOut),
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 14),
                                child: _buildTimesTableGrid(),
                              ),
                            ),
                          ),
                        ),

                        _buildScoreRow(),
                        const SizedBox(height: 20),

                        SlideTransition(
                          position: _questionSlide,
                          child: FadeTransition(
                            opacity: _questionFade,
                            child: _buildQuestionCard(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildAnswerField(),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                hasInput && !_isAnswered
                                    ? _checkAnswer
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFF59E0B),
                              disabledBackgroundColor:
                                  const Color(0xFFFFECB3),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white60,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16)),
                              elevation: 2,
                            ),
                            child: const Text('Check Answer',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildProgressBar(progress),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Feedback banner
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                offset:
                    _isAnswered ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                child: _buildFeedbackBanner(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'Multiplication Tables',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          // Show/Hide Table toggle
          GestureDetector(
            onTap: _toggleTable,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _showTable
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: Text(
                _showTable ? 'Hide' : 'Table',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _showTable
                      ? Colors.white
                      : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _isSoundEnabled
                  ? const Color(0xFFF59E0B)
                  : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
        ],
      ),
    );
  }

  // ── Times table grid ────────────────────────────────────────────────────────
  static const double _kCell = 30.0;
  static const double _kCellFont = 10.5;

  Widget _buildTimesTableGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: × | 1 2 3 … 12
            Row(children: [
              _gridCell('×',
                  bg: const Color(0xFFF59E0B),
                  textColor: Colors.white,
                  bold: true),
              for (int col = 1; col <= 12; col++)
                _gridCell('$col',
                    bg: col == _multiplier
                        ? const Color(0xFFFFE082)
                        : const Color(0xFFF59E0B),
                    textColor: col == _multiplier
                        ? const Color(0xFF7B5800)
                        : Colors.white,
                    bold: true),
            ]),
            // Data rows
            for (int row = 1; row <= 12; row++)
              Row(children: [
                // Row header
                _gridCell('$row',
                    bg: row == _table
                        ? const Color(0xFFFFE082)
                        : const Color(0xFFF59E0B),
                    textColor: row == _table
                        ? const Color(0xFF7B5800)
                        : Colors.white,
                    bold: true),
                // Product cells
                for (int col = 1; col <= 12; col++)
                  _productCell(row, col),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _gridCell(String text,
      {required Color bg,
      required Color textColor,
      bool bold = false}) {
    return Container(
      width: _kCell,
      height: _kCell,
      color: bg,
      child: Center(
        child: Text(text,
            style: TextStyle(
              fontSize: _kCellFont,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            )),
      ),
    );
  }

  Widget _productCell(int row, int col) {
    final isIntersection = row == _table && col == _multiplier;
    final isHighlighted = row == _table || col == _multiplier;

    final Color bg;
    final Color textColor;
    if (isIntersection) {
      bg = const Color(0xFFFF9800);
      textColor = Colors.white;
    } else if (isHighlighted) {
      bg = const Color(0xFFFFF9C4);
      textColor = const Color(0xFF5D4037);
    } else {
      bg = Colors.white;
      textColor = const Color(0xFF444444);
    }

    return Container(
      width: _kCell,
      height: _kCell,
      decoration: BoxDecoration(
        color: bg,
        border: const Border(
          right: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: Center(
        child: Text('${row * col}',
            style: TextStyle(
              fontSize: _kCellFont,
              fontWeight: isIntersection
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: textColor,
            )),
      ),
    );
  }

  // ── Score row ───────────────────────────────────────────────────────────────
  Widget _buildScoreRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCell(
              label: 'Score',
              value: '$_score / $_totalQuestions',
              color: const Color(0xFFF59E0B),
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

  // ── Question card ───────────────────────────────────────────────────────────
  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFF59E0B), width: 2.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$_table × $_multiplier = ?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: Color(0xFF333333),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Table of $_table',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Answer field ────────────────────────────────────────────────────────────
  Widget _buildAnswerField() {
    final borderColor = _isAnswered
        ? (_isCorrect
            ? const Color(0xFF4CAF50)
            : const Color(0xFFF44336))
        : const Color(0xFFF59E0B);

    return TextField(
      controller: _answerController,
      focusNode: _focusNode,
      enabled: !_isAnswered,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: 'Type your answer…',
        hintStyle:
            TextStyle(fontSize: 16, color: Colors.grey.shade400),
        filled: true,
        fillColor: _isAnswered
            ? (_isCorrect
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE))
            : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFF59E0B), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFF59E0B), width: 2.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
      onSubmitted: (_) => _checkAnswer(),
    );
  }

  // ── Feedback banner ─────────────────────────────────────────────────────────
  Widget _buildFeedbackBanner() {
    final bg =
        _isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final explanation =
        '$_table × $_multiplier = $_correctAnswer';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26,
              blurRadius: 14,
              offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _feedbackMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generateQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Next Question →',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ────────────────────────────────────────────────────────────
  Widget _buildProgressBar(double progress) {
    final Color barColor;
    if (progress >= 0.8) {
      barColor = const Color(0xFF4CAF50);
    } else if (progress >= 0.5) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFFF44336);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Accuracy',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161))),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                key: ValueKey(progress.toStringAsFixed(2)),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 14,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.animKey,
  });

  final String label, value;
  final Color color;
  final int animKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: const Color(0xFFEEEEEE));
}
