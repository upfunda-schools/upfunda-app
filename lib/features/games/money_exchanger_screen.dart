import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Currency data
// ─────────────────────────────────────────────────────────────────────────────

class _CurrencyInfo {
  final String flag;
  final String code;
  final String name;
  final double fallbackRate; // 1 foreign unit = X INR

  const _CurrencyInfo({
    required this.flag,
    required this.code,
    required this.name,
    required this.fallbackRate,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MoneyExchangerScreen extends StatefulWidget {
  const MoneyExchangerScreen({super.key});

  @override
  State<MoneyExchangerScreen> createState() => _MoneyExchangerScreenState();
}

class _MoneyExchangerScreenState extends State<MoneyExchangerScreen> {
  static const _currencies = [
    _CurrencyInfo(flag: '🇺🇸', code: 'USD', name: 'US Dollar',          fallbackRate: 88.0),
    _CurrencyInfo(flag: '🇬🇧', code: 'GBP', name: 'British Pound',       fallbackRate: 112.0),
    _CurrencyInfo(flag: '🇪🇺', code: 'EUR', name: 'Euro',                fallbackRate: 95.0),
    _CurrencyInfo(flag: '🇦🇪', code: 'AED', name: 'UAE Dirham',          fallbackRate: 24.0),
    _CurrencyInfo(flag: '🇯🇵', code: 'JPY', name: 'Japanese Yen',        fallbackRate: 0.58),
    _CurrencyInfo(flag: '🇦🇺', code: 'AUD', name: 'Australian Dollar',   fallbackRate: 57.0),
    _CurrencyInfo(flag: '🇨🇦', code: 'CAD', name: 'Canadian Dollar',     fallbackRate: 63.0),
    _CurrencyInfo(flag: '🇸🇬', code: 'SGD', name: 'Singapore Dollar',    fallbackRate: 66.0),
  ];

  // ── Rates ─────────────────────────────────────────────────────────────────
  Map<String, double> _rates = {};
  bool _isLoadingRates = true;
  bool _usingLiveRates = false;

  // ── Game state ────────────────────────────────────────────────────────────
  int _level = 1;
  int _score = 0;
  int _streak = 0;
  int _questionsAnswered = 0;
  int _correctInLevel = 0;
  int _lastPoints = 0;

  _CurrencyInfo? _currentCurrency;
  int _currentAmount = 1;
  String? _feedback; // null | 'correct' | 'wrong'
  double _correctAnswer = 0;

  final _answerCtrl = TextEditingController();
  final _answerFocus = FocusNode();

  // ── Calculator ────────────────────────────────────────────────────────────
  bool _showCalculator = false;
  String _calcDisplay = '0';
  String _calcLeft = '';
  bool _hasOperator = false;
  String _calcRight = '';
  double? _calcResult;

  final _random = Random();

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _rates = {for (final c in _currencies) c.code: c.fallbackRate};
    _loadRates();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _answerFocus.dispose();
    super.dispose();
  }

  // ── Rate loading ──────────────────────────────────────────────────────────
  Future<void> _loadRates() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();

    if (prefs.getString('mex_date') == today) {
      final cached = prefs.getString('mex_rates');
      if (cached != null) {
        try {
          final map = jsonDecode(cached) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _rates = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
              _isLoadingRates = false;
              _usingLiveRates = true;
            });
          }
          _generateQuestion();
          return;
        } catch (_) {}
      }
    }

    // Fetch live
    try {
      final res = await Dio().get(
        'https://api.exchangerate-api.com/v4/latest/INR',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.statusCode == 200) {
        final apiRates = (res.data['rates'] as Map<String, dynamic>);
        final rates = <String, double>{};
        for (final c in _currencies) {
          final r = (apiRates[c.code] as num?)?.toDouble();
          rates[c.code] = (r != null && r > 0) ? 1.0 / r : c.fallbackRate;
        }
        await prefs.setString('mex_date', today);
        await prefs.setString('mex_rates', jsonEncode(rates));
        if (mounted) {
          setState(() {
            _rates = rates;
            _isLoadingRates = false;
            _usingLiveRates = true;
          });
        }
        _generateQuestion();
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingRates = false);
    _generateQuestion();
  }

  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  // ── Question ──────────────────────────────────────────────────────────────
  void _generateQuestion() {
    final maxAmount = _level <= 2 ? 10 : _level <= 4 ? 50 : 100;
    final c = _currencies[_random.nextInt(_currencies.length)];
    final amount = 1 + _random.nextInt(maxAmount);
    final rate = _rates[c.code] ?? c.fallbackRate;

    setState(() {
      _currentCurrency = c;
      _currentAmount = amount;
      _correctAnswer = amount * rate;
      _feedback = null;
      _answerCtrl.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _answerFocus.requestFocus();
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  void _submitAnswer() {
    final userAnswer = double.tryParse(_answerCtrl.text.trim());
    if (userAnswer == null) return;

    final tolerance = _correctAnswer * 0.01;
    final isCorrect = (userAnswer - _correctAnswer).abs() <= tolerance;

    setState(() {
      _questionsAnswered++;
      _feedback = isCorrect ? 'correct' : 'wrong';
      if (isCorrect) {
        _lastPoints = 10 + (_streak * 2);
        _score += _lastPoints;
        _streak++;
        _correctInLevel++;
        if (_correctInLevel >= 5) {
          _level++;
          _correctInLevel = 0;
        }
      } else {
        _lastPoints = 0;
        _streak = 0;
      }
    });
  }

  // ── Calculator ────────────────────────────────────────────────────────────
  void _calcPress(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _calcDisplay = '0';
          _calcLeft = '';
          _hasOperator = false;
          _calcRight = '';
          _calcResult = null;
          break;
        case '×':
          if (_calcLeft.isNotEmpty && !_hasOperator) {
            _hasOperator = true;
            _calcDisplay = '$_calcLeft ×';
            _calcResult = null;
          }
          break;
        case '=':
          if (_calcLeft.isNotEmpty && _hasOperator && _calcRight.isNotEmpty) {
            final l = double.tryParse(_calcLeft) ?? 0;
            final r = double.tryParse(_calcRight) ?? 0;
            _calcResult = l * r;
            _calcLeft = _calcResult!.toStringAsFixed(2);
            _hasOperator = false;
            _calcRight = '';
            _calcDisplay = _calcLeft;
          }
          break;
        case '⌫':
          if (_hasOperator) {
            if (_calcRight.isNotEmpty) {
              _calcRight = _calcRight.substring(0, _calcRight.length - 1);
              _calcDisplay = _calcRight.isEmpty ? '$_calcLeft ×' : '$_calcLeft × $_calcRight';
              _calcResult = null;
            }
          } else if (_calcLeft.isNotEmpty) {
            _calcLeft = _calcLeft.substring(0, _calcLeft.length - 1);
            _calcDisplay = _calcLeft.isEmpty ? '0' : _calcLeft;
            _calcResult = null;
          }
          break;
        default:
          // digit or dot
          if (_hasOperator) {
            if (key == '.' && _calcRight.contains('.')) return;
            _calcRight = (_calcRight == '0' && key != '.') ? key : _calcRight + key;
            _calcDisplay = '$_calcLeft × $_calcRight';
          } else {
            final startFreshAfterResult = _calcResult != null;
            if (startFreshAfterResult) {
              _calcLeft = key == '.' ? '0.' : key;
            } else {
              if (key == '.' && _calcLeft.contains('.')) return;
              _calcLeft = (_calcLeft == '0' && key != '.') ? key : _calcLeft + key;
            }
            _calcDisplay = _calcLeft;
          }
          _calcResult = null;
          break;
      }
    });
  }

  void _useCalcResult() {
    if (_calcResult != null) {
      _answerCtrl.text = _calcResult!.toStringAsFixed(2);
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void _resetGame() {
    setState(() {
      _level = 1;
      _score = 0;
      _streak = 0;
      _questionsAnswered = 0;
      _correctInLevel = 0;
    });
    _generateQuestion();
  }

  double _rateFor(_CurrencyInfo c) => _rates[c.code] ?? c.fallbackRate;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildStatsBar(),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      if (_streak >= 5) ...[
                        const SizedBox(height: 8),
                        _buildStreakBadge(),
                      ],
                      const SizedBox(height: 12),
                      _buildQuestionCard(),
                      const SizedBox(height: 12),
                      _buildCalculatorSection(),
                      const SizedBox(height: 16),
                      _buildCurrencyTable(),
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

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
            tint: const Color(0xFF1B5E20),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '💱 Money Exchanger',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingRates) ...[
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      const SizedBox(width: 4),
                      const Text('Loading rates…', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ] else
                      Text(
                        _usingLiveRates ? '🟢 Live rates' : '🟡 Fallback rates',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _CircleBtn(
            icon: Icons.refresh_rounded,
            onTap: _showResetDialog,
            tint: const Color(0xFF1B5E20),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Game?'),
        content: const Text('Your score and level will be reset.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatPill(label: 'Level',     value: '$_level',               color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          _StatPill(label: 'Score',     value: '$_score',               color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          _StatPill(label: 'Streak',    value: '$_streak 🔥',           color: const Color(0xFFE65100)),
          const SizedBox(width: 8),
          _StatPill(label: 'Questions', value: '$_questionsAnswered',   color: const Color(0xFF6A1B9A)),
        ],
      ),
    );
  }

  // ── Streak badge ──────────────────────────────────────────────────────────
  Widget _buildStreakBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '🔥 On Fire! 🔥',
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────
  Widget _buildQuestionCard() {
    if (_currentCurrency == null) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }

    final c = _currentCurrency!;
    final rate = _rateFor(c);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency header row
          Row(
            children: [
              Text(c.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Text(c.code, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Level $_level',
                  style: const TextStyle(
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Question
          Center(
            child: Text(
              '$_currentAmount ${c.code}  →  ₹ ?',
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B5E20),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Hint
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCC02)),
            ),
            child: Text(
              '💡  1 ${c.code} = ₹${rate.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6D4C00),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_feedback == null) ...[
            // Input field
            TextField(
              controller: _answerCtrl,
              focusNode: _answerFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
                hintText: 'Enter amount in ₹',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
              onSubmitted: (_) => _submitAnswer(),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: const Text('Submit'),
              ),
            ),
          ] else ...[
            _buildFeedback(c, rate),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedback(_CurrencyInfo c, double rate) {
    final isCorrect = _feedback == 'correct';
    final userAnswer = double.tryParse(_answerCtrl.text.trim()) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCorrect ? const Color(0xFF43A047) : const Color(0xFFE53935),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isCorrect ? '✅  Correct!' : '❌  Not quite!',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isCorrect ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                    ),
                  ),
                  if (isCorrect) ...[
                    const Spacer(),
                    Text(
                      '+$_lastPoints pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isCorrect
                    ? '$_currentAmount × ₹${rate.toStringAsFixed(2)} = ₹${_correctAnswer.toStringAsFixed(2)}'
                    : 'Correct: ₹${_correctAnswer.toStringAsFixed(2)}   |   Yours: ₹${userAnswer.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _generateQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8F00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: const Text('Next Question →'),
          ),
        ),
      ],
    );
  }

  // ── Calculator section ────────────────────────────────────────────────────
  Widget _buildCalculatorSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showCalculator = !_showCalculator),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_rounded, size: 20, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Text(
                  'Calculator',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                Icon(
                  _showCalculator ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_showCalculator) ...[
          const SizedBox(height: 8),
          _buildCalculator(),
        ],
      ],
    );
  }

  Widget _buildCalculator() {
    const rows = [
      ['7', '8', '9', '×'],
      ['4', '5', '6', 'C'],
      ['1', '2', '3', '='],
      ['.', '0', '⌫', ''],
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _calcDisplay,
              textAlign: TextAlign.right,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.greenAccent,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Key grid
          ...rows.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((k) {
                if (k.isEmpty) return const Expanded(child: SizedBox());
                final isOp = k == '×' || k == 'C' || k == '=' || k == '⌫';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: isOp ? const Color(0xFF2D2D44) : const Color(0xFF252535),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _calcPress(k),
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 46,
                          child: Center(
                            child: Text(
                              k,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isOp ? Colors.orangeAccent : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )),

          // Use Result button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calcResult != null ? _useCalcResult : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey[800],
                disabledForegroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Use Result'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Currency reference table ──────────────────────────────────────────────
  Widget _buildCurrencyTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 1, child: Text('',       style: TextStyle(color: Colors.white70, fontSize: 12))),
                const Expanded(flex: 2, child: Text('Code',   style: TextStyle(color: Colors.white70, fontSize: 12))),
                const Expanded(flex: 3, child: Text('Name',   style: TextStyle(color: Colors.white70, fontSize: 12))),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      const Text('1 unit = ₹', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      if (_isLoadingRates) ...[
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 10, height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Data rows
          ...List.generate(_currencies.length, (i) {
            final c = _currencies[i];
            final isActive = _currentCurrency?.code == c.code && _feedback == null;
            final isLast = i == _currencies.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1565C0).withValues(alpha: 0.08)
                    : i.isOdd
                        ? const Color(0xFFF5F5F5)
                        : Colors.white,
                borderRadius: isLast
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text(c.flag, style: const TextStyle(fontSize: 20))),
                  Expanded(
                    flex: 2,
                    child: Text(
                      c.code,
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(c.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${_rateFor(c).toStringAsFixed(2)}',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color tint;
  const _CircleBtn({required this.icon, required this.onTap, required this.tint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: tint.withValues(alpha: 0.15), blurRadius: 6),
          ],
        ),
        child: Icon(icon, color: tint, size: 20),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
