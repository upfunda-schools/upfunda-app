import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FindMissingNumbersScreen extends StatefulWidget {
  const FindMissingNumbersScreen({super.key});

  @override
  State<FindMissingNumbersScreen> createState() =>
      _FindMissingNumbersScreenState();
}
class _FindMissingNumbersScreenState extends State<FindMissingNumbersScreen>
    with TickerProviderStateMixin {
  // ── Question state ──────────────────────────────────────────────────────────
  int _num1 = 0;
  int _num2 = 0;
  int _result = 0;
  String _operation = '+';
  int _hiddenDigit = 0;
  String _topStr = '';    // num1 display (may contain '_')
  String _bottomStr = ''; // num2 display (may contain '_')
  String _resultStr = ''; // result always full

  // ── Game state ──────────────────────────────────────────────────────────────
  int? _selectedDigit;
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

  final Random _random = Random();

  // ── Animation ───────────────────────────────────────────────────────────────
  late final AnimationController _questionAnim;
  late final Animation<double> _questionFade;
  late final Animation<Offset> _questionSlide;

  // ── Messages ────────────────────────────────────────────────────────────────
  static const _correctMsgs = [
    'You found it! 🌟', 'Brilliant! 🔥', 'Perfect! 💪',
    'Spot on! ⭐', 'Excellent! 🎯', 'Amazing! 🚀',
    'Outstanding! 🏆', 'Super work! 🎉',
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
    ).animate(CurvedAnimation(parent: _questionAnim, curve: Curves.easeOut));
    _generateQuestion();
  }

  @override
  void dispose() {
    _questionAnim.dispose();
    super.dispose();
  }

  // ── Question generation ─────────────────────────────────────────────────────
  void _generateQuestion() {
    final use3Digits = _random.nextBool();
    final isAddition = _random.nextBool();

    int num1, num2, result;
    final String operation;

    if (isAddition) {
      operation = '+';
      if (use3Digits) {
        // num1: 100–998  so  999-num1 >= 1
        num1 = _random.nextInt(899) + 100;
        num2 = _random.nextInt(999 - num1) + 1;
      } else {
        // num1: 10–98  so  99-num1 >= 1
        num1 = _random.nextInt(89) + 10;
        num2 = _random.nextInt(99 - num1) + 1;
      }
      result = num1 + num2;
    } else {
      operation = '-';
      if (use3Digits) {
        result = _random.nextInt(900) + 100; // 100–999
        num2 = _random.nextInt(result) + 1;  // 1–result
      } else {
        result = _random.nextInt(90) + 10;   // 10–99
        num2 = _random.nextInt(result) + 1;  // 1–result
      }
      num1 = result + num2; // num1 - num2 = result
    }

    // Hide one digit from num1 (top) or num2 (bottom)
    final hideFromTop = _random.nextBool();
    final target = hideFromTop ? num1 : num2;
    final targetStr = target.toString();
    final missingPos = _random.nextInt(targetStr.length);
    final hiddenDigit = int.parse(targetStr[missingPos]);

    // Build display strings (replace hidden digit with '_')
    String num1Str = num1.toString();
    String num2Str = num2.toString();
    if (hideFromTop) {
      num1Str = '${num1Str.substring(0, missingPos)}_${num1Str.substring(missingPos + 1)}';
    } else {
      num2Str = '${num2Str.substring(0, missingPos)}_${num2Str.substring(missingPos + 1)}';
    }

    setState(() {
      _num1 = num1;
      _num2 = num2;
      _result = result;
      _operation = operation;
      _hiddenDigit = hiddenDigit;
      _topStr = num1Str;
      _bottomStr = num2Str;
      _resultStr = result.toString();
      _selectedDigit = null;
      _isAnswered = false;
      _isCorrect = false;
      _feedbackMessage = '';
    });

    _questionAnim.forward(from: 0);
  }

  // ── Answer checking ─────────────────────────────────────────────────────────
  void _checkAnswer() {
    if (_selectedDigit == null || _isAnswered) return;
    final correct = _selectedDigit == _hiddenDigit;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildScoreRow(),
                        const SizedBox(height: 20),
                        SlideTransition(
                          position: _questionSlide,
                          child: FadeTransition(
                            opacity: _questionFade,
                            child: Column(
                              children: [
                                _buildMathCard(),
                                const SizedBox(height: 12),
                                const Text(
                                  'What is the missing digit? (0–9)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF616161),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildNumberPad(),
                        const SizedBox(height: 14),
                        _buildCheckButton(),
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
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
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
              'Find Missing Numbers',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSoundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _isSoundEnabled
                  ? const Color(0xFF1565C0)
                  : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isSoundEnabled = !_isSoundEnabled),
          ),
        ],
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
              color: const Color(0xFF1565C0),
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

  // ── Math card ───────────────────────────────────────────────────────────────
  // Cell dimensions for monospace digit display
  static const double _kFontSize = 40.0;
  static const double _kCellW = _kFontSize * 0.60;
  static const double _kCellH = _kFontSize * 1.25;

  Widget _buildMathCard() {
    final maxLen = [_topStr.length, _bottomStr.length, _resultStr.length]
        .reduce(max);

    final paddedTop = _topStr.padLeft(maxLen);
    final paddedBottom = _bottomStr.padLeft(maxLen);
    final paddedResult = _resultStr.padLeft(maxLen);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0), width: 2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMathRow(' ', paddedTop),
            const SizedBox(height: 4),
            _buildMathRow(_operation, paddedBottom),
            const SizedBox(height: 6),
            _buildMathDivider(maxLen),
            const SizedBox(height: 6),
            _buildMathRow(' ', paddedResult),
          ],
        ),
      ),
    );
  }

  Widget _buildMathRow(String prefix, String content) {
    final cells = <Widget>[];

    // Prefix cell: operator or blank
    cells.add(SizedBox(
      width: _kCellW,
      height: _kCellH,
      child: Center(
        child: Text(
          prefix,
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: _kFontSize,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
            height: 1.0,
          ),
        ),
      ),
    ));

    // Content cells
    for (int i = 0; i < content.length; i++) {
      final ch = content[i];
      if (ch == '_') {
        cells.add(_buildBoxCell());
      } else if (ch == ' ') {
        cells.add(SizedBox(width: _kCellW, height: _kCellH));
      } else {
        cells.add(SizedBox(
          width: _kCellW,
          height: _kCellH,
          child: Center(
            child: Text(
              ch,
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: _kFontSize,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                height: 1.0,
              ),
            ),
          ),
        ));
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: cells);
  }

  Widget _buildBoxCell() {
    final Color bg;
    final Color borderColor;
    String label = '';

    if (!_isAnswered) {
      bg = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFB300);
    } else if (_isCorrect) {
      bg = const Color(0xFF4CAF50);
      borderColor = const Color(0xFF4CAF50);
      label = '$_hiddenDigit';
    } else {
      bg = const Color(0xFFF44336);
      borderColor = const Color(0xFFF44336);
      label = '$_hiddenDigit';
    }

    return Container(
      width: _kCellW + 2,
      height: _kCellH * 0.78,
      margin: EdgeInsets.symmetric(vertical: _kCellH * 0.11),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor, width: 2.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Courier New',
            fontSize: _kFontSize * 0.82,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildMathDivider(int maxLen) {
    final totalCells = 1 + maxLen; // prefix + content
    return Container(
      width: _kCellW * totalCells,
      height: 2.5,
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Number pad ──────────────────────────────────────────────────────────────
  Widget _buildNumberPad() {
    // 5×2 grid — row 1: 1–5, row 2: 6–9, 0
    const digits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];

    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: digits
          .map((d) => _DigitButton(
                digit: d,
                isSelected: !_isAnswered && _selectedDigit == d,
                isAnswered: _isAnswered,
                isHiddenDigit: _isAnswered && d == _hiddenDigit,
                isWrong: _isAnswered &&
                    !_isCorrect &&
                    _selectedDigit == d,
                onTap: _isAnswered
                    ? null
                    : () => setState(() => _selectedDigit = d),
              ))
          .toList(),
    );
  }

  // ── Check button ────────────────────────────────────────────────────────────
  Widget _buildCheckButton() {
    final enabled = _selectedDigit != null && !_isAnswered;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? _checkAnswer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          disabledBackgroundColor: const Color(0xFFBBDEFB),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white60,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: enabled ? 2 : 0,
        ),
        child: const Text('Check Answer',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Feedback banner ─────────────────────────────────────────────────────────
  Widget _buildFeedbackBanner() {
    final bg =
        _isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final explanation =
        '$_num1 $_operation $_num2 = $_result, missing digit is $_hiddenDigit';

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
              color: Colors.white.withValues(alpha: 0.4),
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
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
      barColor = const Color(0xFF1565C0);
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
                    color: Color(0xFF1565C0)),
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

// ── Digit button ───────────────────────────────────────────────────────────────

class _DigitButton extends StatelessWidget {
  const _DigitButton({
    required this.digit,
    required this.isSelected,
    required this.isAnswered,
    required this.isHiddenDigit,
    required this.isWrong,
    required this.onTap,
  });

  final int digit;
  final bool isSelected, isAnswered, isHiddenDigit, isWrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color border = const Color(0xFFBDBDBD);
    Color text = const Color(0xFF333333);

    if (isAnswered) {
      if (isHiddenDigit) {
        bg = const Color(0xFF4CAF50);
        border = const Color(0xFF4CAF50);
        text = Colors.white;
      } else if (isWrong) {
        bg = const Color(0xFFF44336);
        border = const Color(0xFFF44336);
        text = Colors.white;
      } else {
        bg = const Color(0xFFF5F5F5);
        border = Colors.grey.shade300;
        text = Colors.grey.shade400;
      }
    } else if (isSelected) {
      bg = const Color(0xFFFFB300);
      border = const Color(0xFFFFB300);
      text = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
                color: border.withValues(alpha: isSelected ? 0.35 : 0.1),
                blurRadius: 5,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Text(
            '$digit',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: text),
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
