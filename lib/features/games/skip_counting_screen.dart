import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SkipCountingScreen extends StatefulWidget {
  const SkipCountingScreen({super.key});

  @override
  State<SkipCountingScreen> createState() => _SkipCountingScreenState();
}

class _SkipCountingScreenState extends State<SkipCountingScreen>
    with TickerProviderStateMixin {
  // ── Table selection ─────────────────────────────────────────────────────────
  // 0 = random any, 2-10 = specific table
  int _selectedTable = 0;
  int _currentTable = 2;

  // ── Question state ──────────────────────────────────────────────────────────
  List<int?> _sequence = []; // null marks the hidden position
  int _hiddenIndex = 0;
  int _correctAnswer = 0;

  // ── Game state ──────────────────────────────────────────────────────────────
  bool _isAnswered = false;
  bool _isCorrect = false;
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

  // ── Messages ────────────────────────────────────────────────────────────────
  static const _correctMsgs = [
    'You got it! 🌟', "You're on fire! 🔥", 'Brilliant! 💪',
    'Perfect! ⭐', 'Excellent! 🎯', 'Amazing! 🚀',
    'Outstanding! 🏆', 'Super! 🎉',
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

    _answerController.addListener(() => setState(() {}));

    _generateQuestion();
  }

  @override
  void dispose() {
    _questionAnim.dispose();
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Question generation ─────────────────────────────────────────────────────
  void _generateQuestion() {
    final table = _selectedTable == 0
        ? (_random.nextInt(9) + 2) // 2–10
        : _selectedTable;

    // Start from a random multiple, keep sequence length 5–6
    final startMult = _random.nextInt(8) + 1; // 1–8
    final seqLen = 5 + _random.nextInt(2);     // 5 or 6

    final full = List.generate(seqLen, (i) => (startMult + i) * table);

    // Hide a middle index (never first or last) so the pattern is clear
    final hiddenIdx = 1 + _random.nextInt(seqLen - 2);
    final correct = full[hiddenIdx];

    final seq = List<int?>.from(full);
    seq[hiddenIdx] = null;

    setState(() {
      _currentTable = table;
      _sequence = seq;
      _hiddenIndex = hiddenIdx;
      _correctAnswer = correct;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });

    _answerController.clear();
    _questionAnim.forward(from: 0);
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
      backgroundColor: const Color(0xFFE1F5FE),
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
                        _buildTableSelector(),
                        const SizedBox(height: 16),
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
                            onPressed: hasInput && !_isAnswered
                                ? _checkAnswer
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF0284C7),
                              disabledBackgroundColor:
                                  const Color(0xFFBAE6FD),
                              foregroundColor: Colors.white,
                              disabledForegroundColor:
                                  Colors.white60,
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
                                    fontWeight:
                                        FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              'Skip Counting',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333)),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _isSoundEnabled
                  ? const Color(0xFF0284C7)
                  : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
        ],
      ),
    );
  }

  // ── Table selector ──────────────────────────────────────────────────────────
  Widget _buildTableSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Count by:',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF546E7A)),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TableChip(
                label: 'Any',
                isSelected: _selectedTable == 0,
                onTap: () {
                  setState(() => _selectedTable = 0);
                  _generateQuestion();
                },
              ),
              ...List.generate(9, (i) {
                final t = i + 2;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _TableChip(
                    label: '$t',
                    isSelected: _selectedTable == t,
                    onTap: () {
                      setState(() => _selectedTable = t);
                      _generateQuestion();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
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
              color: const Color(0xFF0284C7),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: const Color(0xFF0284C7), width: 2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0284C7).withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Counting by $_currentTable  (+$_currentTable each step)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0284C7),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Number sequence with arrows
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _sequence.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF7ECFF5),
                        size: 20,
                      ),
                    ),
                  _SequenceBox(
                    value: _sequence[i],
                    isAnswered: _isAnswered,
                    isCorrect: _isCorrect,
                    correctAnswer: _correctAnswer,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // "What's the missing number?" prompt
          const Text(
            'What is the missing number?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF90A4AE),
              fontWeight: FontWeight.w500,
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
        : const Color(0xFF0284C7);

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
        hintText: 'Type the missing number…',
        hintStyle:
            TextStyle(fontSize: 15, color: Colors.grey.shade400),
        filled: true,
        fillColor: _isAnswered
            ? (_isCorrect
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFFFEBEE))
            : Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: Color(0xFF0284C7), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: Color(0xFF0284C7), width: 2.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18),
      ),
      onSubmitted: (_) => _checkAnswer(),
    );
  }

  // ── Feedback banner ─────────────────────────────────────────────────────────
  Widget _buildFeedbackBanner() {
    final bg =
        _isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    // Build explanation from neighbours
    final prev = _hiddenIndex > 0 ? _sequence[_hiddenIndex - 1] : null;
    final next = _hiddenIndex < _sequence.length - 1
        ? _sequence[_hiddenIndex + 1]
        : null;
    final String explanation;
    if (prev != null && next != null) {
      explanation =
          '$prev + $_currentTable = $_correctAnswer  •  $_correctAnswer + $_currentTable = $next';
    } else {
      explanation =
          'Counting by $_currentTable: the missing number is $_correctAnswer';
    }

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
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Next Question →',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
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
      barColor = const Color(0xFF0284C7);
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
                    color: Color(0xFF0284C7)),
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

// ── Sequence number box ────────────────────────────────────────────────────────

class _SequenceBox extends StatelessWidget {
  const _SequenceBox({
    required this.value,       // null = hidden position
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
  });

  final int? value;
  final bool isAnswered;
  final bool isCorrect;
  final int correctAnswer;

  @override
  Widget build(BuildContext context) {
    final isHidden = value == null;

    if (!isHidden) {
      // Regular number tile
      return Container(
        constraints: const BoxConstraints(minWidth: 54),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF7DD3FC), width: 1.5),
        ),
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C4A6E),
          ),
        ),
      );
    }

    // Hidden / answer box
    Color bg;
    Color border;
    String label;
    Color textColor;

    if (!isAnswered) {
      bg = const Color(0xFFFFF8E1);
      border = const Color(0xFFFFB300);
      label = '?';
      textColor = const Color(0xFFFF8F00);
    } else if (isCorrect) {
      bg = const Color(0xFF4CAF50);
      border = const Color(0xFF388E3C);
      label = '$correctAnswer';
      textColor = Colors.white;
    } else {
      bg = const Color(0xFFF44336);
      border = const Color(0xFFC62828);
      label = '$correctAnswer';
      textColor = Colors.white;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 2.5),
        boxShadow: !isAnswered
            ? [
                BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : [],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Table chip ─────────────────────────────────────────────────────────────────

class _TableChip extends StatelessWidget {
  const _TableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0284C7)
                : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFF0284C7).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF546E7A),
          ),
        ),
      ),
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
