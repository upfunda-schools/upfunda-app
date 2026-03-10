import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

enum Weather { sunny, cloudy, rainy }

enum GamePhase { shop, pricing, results, gameOver }

class _Supplies {
  final int lemons;
  final int sugar;
  final int cups;
  final int ice;
  const _Supplies({
    this.lemons = 0,
    this.sugar = 0,
    this.cups = 0,
    this.ice = 0,
  });
  _Supplies copyWith({int? lemons, int? sugar, int? cups, int? ice}) =>
      _Supplies(
        lemons: lemons ?? this.lemons,
        sugar: sugar ?? this.sugar,
        cups: cups ?? this.cups,
        ice: ice ?? this.ice,
      );
}

class _DayResult {
  final int day;
  final Weather weather;
  final int cupsSold;
  final double pricePerCup;
  final double revenue;
  final double expenses;
  final double profit;
  const _DayResult({
    required this.day,
    required this.weather,
    required this.cupsSold,
    required this.pricePerCup,
    required this.revenue,
    required this.expenses,
    required this.profit,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class LemonadeStandScreen extends StatefulWidget {
  const LemonadeStandScreen({super.key});

  @override
  State<LemonadeStandScreen> createState() => _LemonadeStandScreenState();
}

class _LemonadeStandScreenState extends State<LemonadeStandScreen>
    with TickerProviderStateMixin {
  // ── Game state ────────────────────────────────────────────────────────────
  double _money = 20.0;
  int _day = 1;
  GamePhase _phase = GamePhase.shop;
  Weather _weather = Weather.sunny;
  _Supplies _supplies = const _Supplies();
  double _pricePerCup = 1.50;
  double _dailyExpenses = 0.0;
  final List<_DayResult> _dayResults = [];
  _DayResult? _lastResult;
  bool _showHelp = false;

  final Random _random = Random();
  late AnimationController _resultAnimCtrl;
  late Animation<double> _resultAnim;

  // ── Ingredient costs ──────────────────────────────────────────────────────
  static const double _lemonCost = 0.50;
  static const double _sugarCost = 0.25;
  static const double _cupCost = 0.05;
  static const double _iceCost = 0.15;

  // ── Ingredient → cups produced ────────────────────────────────────────────
  static const int _lemonCups = 2;
  static const int _sugarCups = 4;
  static const int _iceCups = 3;
  // 1 paper cup = 1 cup (cups are 1:1)

  // ── Tips ──────────────────────────────────────────────────────────────────
  static const _tips = [
    'On rainy days, fewer people want lemonade. Try lowering your price!',
    'Pricing between \$1.00–\$1.50 usually attracts the most customers.',
    'Buying more supplies upfront lets you sell more cups!',
    'Sunny days bring up to 3× more customers than rainy days.',
    'The limiting ingredient caps your cup count — balance all four!',
    'Revenue = cups sold × price. Higher price = more money per cup.',
    'Profit = Revenue − Expenses. Spend wisely to stay in the green!',
    'Unsold cups mean wasted supplies — don\'t over-buy!',
  ];

  // ── Computed ──────────────────────────────────────────────────────────────
  int get _maxCups {
    if (_supplies.lemons == 0 ||
        _supplies.sugar == 0 ||
        _supplies.cups == 0 ||
        _supplies.ice == 0) {
      return 0;
    }
    return [
      _supplies.lemons * _lemonCups,
      _supplies.sugar * _sugarCups,
      _supplies.cups * 1,
      _supplies.ice * _iceCups,
    ].reduce(min);
  }

  double get _potentialRevenue => _maxCups * _pricePerCup;

  double get _totalRevenue =>
      _dayResults.fold(0.0, (s, r) => s + r.revenue);
  double get _totalExpenses =>
      _dayResults.fold(0.0, (s, r) => s + r.expenses);
  double get _totalProfit =>
      _dayResults.fold(0.0, (s, r) => s + r.profit);

  String get _weatherEmoji {
    switch (_weather) {
      case Weather.sunny: return '☀️';
      case Weather.cloudy: return '⛅';
      case Weather.rainy: return '🌧️';
    }
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  String get _currentDate {
    final date = DateTime.now().add(Duration(days: _day - 1));
    return '${date.day} ${_months[date.month - 1]}';
  }

  String get _weatherName {
    switch (_weather) {
      case Weather.sunny: return 'Sunny';
      case Weather.cloudy: return 'Cloudy';
      case Weather.rainy: return 'Rainy';
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _rollWeather();
    _resultAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultAnim = CurvedAnimation(
      parent: _resultAnimCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _resultAnimCtrl.dispose();
    super.dispose();
  }

  // ── Game logic ────────────────────────────────────────────────────────────
  void _rollWeather() {
    final r = _random.nextDouble();
    _weather = r < 0.50 ? Weather.sunny : r < 0.80 ? Weather.cloudy : Weather.rainy;
  }

  _DayResult _simulateSales() {
    // Base demand by weather
    final base = switch (_weather) {
      Weather.sunny => 25 + _random.nextInt(15),
      Weather.cloudy => 12 + _random.nextInt(13),
      Weather.rainy => 3 + _random.nextInt(8),
    };

    // Price elasticity multiplier
    double mult;
    if (_pricePerCup <= 0.75) {
      mult = 1.5;
    } else if (_pricePerCup <= 1.00) {
      mult = 1.3;
    } else if (_pricePerCup <= 1.50) {
      mult = 1.0;
    } else if (_pricePerCup <= 2.00) {
      mult = 0.75;
    } else if (_pricePerCup <= 2.50) {
      mult = 0.55;
    } else if (_pricePerCup <= 3.00) {
      mult = 0.40;
    } else if (_pricePerCup <= 3.50) {
      mult = 0.28;
    } else if (_pricePerCup <= 4.00) {
      mult = 0.18;
    } else {
      mult = 0.10;
    }

    final customers = (base * mult).round();
    final sold = min(_maxCups, customers);
    final revenue = sold * _pricePerCup;
    return _DayResult(
      day: _day,
      weather: _weather,
      cupsSold: sold,
      pricePerCup: _pricePerCup,
      revenue: revenue,
      expenses: _dailyExpenses,
      profit: revenue - _dailyExpenses,
    );
  }

  void _adjustIngredient(String type, int delta) {
    // delta > 0 = buy, delta < 0 = refund
    double unitCost;
    int current;
    switch (type) {
      case 'lemons':
        unitCost = _lemonCost;
        current = _supplies.lemons;
      case 'sugar':
        unitCost = _sugarCost;
        current = _supplies.sugar;
      case 'cups':
        unitCost = _cupCost;
        current = _supplies.cups;
      case 'ice':
        unitCost = _iceCost;
        current = _supplies.ice;
      default:
        return;
    }

    final newQty = current + delta;
    if (newQty < 0) return;
    final cost = unitCost * delta; // positive = buying, negative = refund
    if (delta > 0 && _money < cost) return;

    setState(() {
      _money -= cost;
      _dailyExpenses += cost;
      switch (type) {
        case 'lemons':
          _supplies = _supplies.copyWith(lemons: newQty);
        case 'sugar':
          _supplies = _supplies.copyWith(sugar: newQty);
        case 'cups':
          _supplies = _supplies.copyWith(cups: newQty);
        case 'ice':
          _supplies = _supplies.copyWith(ice: newQty);
      }
    });
  }

  void _proceedToPricing() {
    setState(() => _phase = GamePhase.pricing);
  }

  void _startSelling() {
    final result = _simulateSales();
    setState(() {
      _money += result.profit;
      _lastResult = result;
      _dayResults.add(result);
      _phase = GamePhase.results;
    });
    _resultAnimCtrl.forward(from: 0);
  }

  void _nextDay() {
    if (_money < 1.0) {
      setState(() => _phase = GamePhase.gameOver);
      return;
    }
    setState(() {
      _day++;
      _supplies = const _Supplies();
      _dailyExpenses = 0.0;
      _pricePerCup = 1.50;
      _rollWeather();
      _phase = GamePhase.shop;
    });
  }

  void _resetGame() {
    setState(() {
      _money = 20.0;
      _day = 1;
      _phase = GamePhase.shop;
      _supplies = const _Supplies();
      _pricePerCup = 1.50;
      _dailyExpenses = 0.0;
      _dayResults.clear();
      _lastResult = null;
      _rollWeather();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFDE7), Color(0xFFFFF176), Color(0xFFFFCA28)],
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
                  child: _buildPhase(),
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
          ),
          Expanded(
            child: Text(
              '🍋 Lemonade Stand',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6D4C00),
              ),
            ),
          ),
          _CircleBtn(
            icon: Icons.refresh_rounded,
            onTap: () => _showResetDialog(),
            tooltip: 'New Game',
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start New Game?'),
        content: const Text('Your current progress will be lost.'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('New Game', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(icon: Icons.calendar_today_rounded, label: 'Day $_day', value: _currentDate),
          _StatChip(emoji: '💰', label: 'Money', value: '\$${_money.toStringAsFixed(2)}'),
          _StatChip(emoji: _weatherEmoji, label: 'Weather', value: _weatherName),
          _StatChip(emoji: '🥤', label: 'Cups', value: '$_maxCups'),
        ],
      ),
    );
  }

  // ── Phase router ──────────────────────────────────────────────────────────
  Widget _buildPhase() {
    return switch (_phase) {
      GamePhase.shop => _buildShop(),
      GamePhase.pricing => _buildPricing(),
      GamePhase.results => _buildResults(),
      GamePhase.gameOver => _buildGameOver(),
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 1 — Shop
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildShop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),

        // Instruction banner
        _Banner(
          color: const Color(0xFF1E88E5),
          icon: '🛒',
          text: 'Buy your supplies for today! You have \$${_money.toStringAsFixed(2)} to spend.',
        ),

        const SizedBox(height: 16),

        // 2×2 ingredient grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _IngredientCard(
              emoji: '🍋',
              name: 'Lemons',
              cost: '\$${_lemonCost.toStringAsFixed(2)} each',
              note: 'Makes $_lemonCups cups',
              qty: _supplies.lemons,
              canBuy: _money >= _lemonCost,
              onAdd: () => _adjustIngredient('lemons', 1),
              onRemove: () => _adjustIngredient('lemons', -1),
            ),
            _IngredientCard(
              emoji: '🍬',
              name: 'Sugar',
              cost: '\$${_sugarCost.toStringAsFixed(2)} each',
              note: 'Makes $_sugarCups cups',
              qty: _supplies.sugar,
              canBuy: _money >= _sugarCost,
              onAdd: () => _adjustIngredient('sugar', 1),
              onRemove: () => _adjustIngredient('sugar', -1),
            ),
            _IngredientCard(
              emoji: '🥤',
              name: 'Cups',
              cost: '\$${_cupCost.toStringAsFixed(2)} each',
              note: '1 cup each',
              qty: _supplies.cups,
              canBuy: _money >= _cupCost,
              onAdd: () => _adjustIngredient('cups', 1),
              onRemove: () => _adjustIngredient('cups', -1),
            ),
            _IngredientCard(
              emoji: '🧊',
              name: 'Ice',
              cost: '\$${_iceCost.toStringAsFixed(2)} each',
              note: 'Makes $_iceCups cups',
              qty: _supplies.ice,
              canBuy: _money >= _iceCost,
              onAdd: () => _adjustIngredient('ice', 1),
              onRemove: () => _adjustIngredient('ice', -1),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Expenses:",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  Text(
                    '\$${_dailyExpenses.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lemonade Cups Ready:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  Text(
                    '$_maxCups cups',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Next button
        _GradientButton(
          label: 'Next: Set Your Price →',
          colors: const [Color(0xFFFF8F00), Color(0xFFFFB300)],
          enabled: _maxCups > 0,
          onTap: _proceedToPricing,
        ),

        const SizedBox(height: 20),

        // Help section
        _buildHelp(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 2 — Pricing
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPricing() {
    // Slider steps: $0.50 to $5.00 in $0.25 increments → 19 steps (0..18)
    const double minPrice = 0.50;
    const double maxPrice = 5.00;
    const int divisions = 18;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),

        _Banner(
          color: const Color(0xFF43A047),
          icon: '💲',
          text:
              'Set your price per cup! Weather today: $_weatherName $_weatherEmoji. Higher price = more profit per cup but fewer customers.',
        ),

        const SizedBox(height: 20),

        // Large price display
        Center(
          child: Text(
            '\$${_pricePerCup.toStringAsFixed(2)} / cup',
            style: GoogleFonts.montserrat(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF6D4C00),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFF8F00),
            inactiveTrackColor: const Color(0xFFFFE082),
            thumbColor: const Color(0xFFFF6F00),
            overlayColor: const Color(0x29FF8F00),
            valueIndicatorColor: const Color(0xFFFF6F00),
            trackHeight: 6,
          ),
          child: Slider(
            value: _pricePerCup,
            min: minPrice,
            max: maxPrice,
            divisions: divisions,
            label: '\$${_pricePerCup.toStringAsFixed(2)}',
            onChanged: (v) => setState(() => _pricePerCup = v),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('\$0.50', style: TextStyle(color: Colors.grey)),
            ),
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text('\$5.00', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Quick Math preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF90CAF9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Quick Math',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 12),
              _MathRow('Cups available:', '$_maxCups cups'),
              _MathRow('Price per cup:', '\$${_pricePerCup.toStringAsFixed(2)}'),
              _MathRow(
                'Potential Revenue:',
                '\$${_potentialRevenue.toStringAsFixed(2)}',
                valueColor: const Color(0xFF2E7D32),
              ),
              _MathRow(
                "Today's Expenses:",
                '-\$${_dailyExpenses.toStringAsFixed(2)}',
                valueColor: const Color(0xFFC62828),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _GradientButton(
          label: '🍋 Start Selling!',
          colors: const [Color(0xFF43A047), Color(0xFF00ACC1)],
          onTap: _startSelling,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 3 — Results
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildResults() {
    final r = _lastResult!;
    final isProfit = r.profit >= 0;
    final tip = _tips[_random.nextInt(_tips.length)];
    final isGameOver = _money < 1.0;

    return ScaleTransition(
      scale: _resultAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // Day header
          Center(
            child: Text(
              'Day ${r.day} Results  $_weatherEmoji',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6D4C00),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3-column summary
          Row(
            children: [
              Expanded(
                child: _ResultCard(
                  label: 'Cups Sold',
                  value: '${r.cupsSold}',
                  sub: '@ \$${r.pricePerCup.toStringAsFixed(2)}',
                  color: const Color(0xFF6D4C00),
                  bg: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultCard(
                  label: 'Revenue',
                  value: '\$${r.revenue.toStringAsFixed(2)}',
                  color: const Color(0xFF1B5E20),
                  bg: const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultCard(
                  label: 'Expenses',
                  value: '\$${r.expenses.toStringAsFixed(2)}',
                  color: const Color(0xFFB71C1C),
                  bg: const Color(0xFFFFEBEE),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Profit / Loss card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isProfit
                    ? const [Color(0xFF3949AB), Color(0xFF8E24AA)]
                    : const [Color(0xFFE53935), Color(0xFFFF7043)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isProfit ? Colors.indigo : Colors.red)
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  isProfit
                      ? '+\$${r.profit.toStringAsFixed(2)} Profit! 🎉'
                      : '-\$${r.profit.abs().toStringAsFixed(2)} Loss 😔',
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isProfit
                      ? 'Great job! You made a profit today!'
                      : "Don't give up! Try adjusting your prices tomorrow.",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance: \$${_money.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Did you know tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCC02)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Did you know?',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF6D4C00),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Overall Performance (from day 2)
          if (_dayResults.length >= 2) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📈 Overall Performance',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF6D4C00),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MathRow(
                    'Total Revenue:',
                    '\$${_totalRevenue.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF2E7D32),
                  ),
                  _MathRow(
                    'Total Expenses:',
                    '\$${_totalExpenses.toStringAsFixed(2)}',
                    valueColor: const Color(0xFFC62828),
                  ),
                  const Divider(height: 12),
                  _MathRow(
                    'Total Profit/Loss:',
                    '\$${_totalProfit.toStringAsFixed(2)}',
                    valueColor: _totalProfit >= 0
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFFB71C1C),
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Continue / Game Over
          if (isGameOver) ...[
            _buildGameOverInline(),
          ] else ...[
            _GradientButton(
              label: 'Continue to Day ${_day + 1} →',
              colors: const [Color(0xFFFF8F00), Color(0xFFFFB300)],
              onTap: _nextDay,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameOverInline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('😔 Game Over!', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'You ran out of money on Day $_day.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFB71C1C),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Game Over screen
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGameOver() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Text('😔', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Game Over!',
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF6D4C00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You ran out of money on Day $_day.',
            style: const TextStyle(fontSize: 16, color: Colors.brown),
          ),
          const SizedBox(height: 28),

          // Final stats
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Final Stats',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFF6D4C00),
                  ),
                ),
                const SizedBox(height: 12),
                _MathRow('Days survived:', '$_day'),
                _MathRow(
                  'Total revenue:',
                  '\$${_totalRevenue.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF2E7D32),
                ),
                _MathRow(
                  'Total profit/loss:',
                  '\$${_totalProfit.toStringAsFixed(2)}',
                  valueColor: _totalProfit >= 0
                      ? const Color(0xFF1B5E20)
                      : const Color(0xFFB71C1C),
                  bold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _GradientButton(
            label: '🔄 Play Again',
            colors: const [Color(0xFFFF8F00), Color(0xFFFFB300)],
            onTap: _resetGame,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Help section
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHelp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showHelp = !_showHelp),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('❓ How to Play', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                Icon(
                  _showHelp ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: Colors.orange[800],
                ),
              ],
            ),
          ),
        ),
        if (_showHelp) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpStep('1', '🛒 Buy Supplies', 'Purchase ingredients with your money'),
                _HelpStep('2', '💲 Set Your Price', 'Higher price = more profit per cup but fewer customers'),
                _HelpStep('3', '🌤️ Check the Weather', 'Sunny days bring more customers'),
                _HelpStep('4', '📊 See Results', 'Learn from each day and improve'),
                const Divider(height: 20),
                const Text('Tips:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                const _TipItem('☀️ Sunny days = high demand, you can charge more'),
                const _TipItem('🌧️ Rainy days = low demand, lower your price'),
                const _TipItem("🛍️ Don't overspend — only buy what you can sell"),
                const _TipItem('💡 Sweet spot price is usually \$1.00–\$1.50'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const _CircleBtn({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.15),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF6D4C00), size: 20),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String label;
  final String value;
  const _StatChip({this.emoji, this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 20, color: const Color(0xFF6D4C00))
        else
          Text(emoji ?? '', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: const Color(0xFF6D4C00),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.brown),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final String icon;
  final String text;
  const _Banner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 1.0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String cost;
  final String note;
  final int qty;
  final bool canBuy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _IngredientCard({
    required this.emoji,
    required this.name,
    required this.cost,
    required this.note,
    required this.qty,
    required this.canBuy,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Text(
            name,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          Text(cost, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            note,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6D4C00)),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QtyBtn(
                icon: Icons.remove_rounded,
                onTap: qty > 0 ? onRemove : null,
                color: const Color(0xFFE53935),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$qty',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _QtyBtn(
                icon: Icons.add_rounded,
                onTap: canBuy ? onAdd : null,
                color: const Color(0xFF43A047),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _QtyBtn({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? color : Colors.grey,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> colors;
  final bool enabled;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.colors,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(colors: colors)
              : const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _MathRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _MathRow(this.label, this.value, {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final Color bg;
  const _ResultCard({
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String num;
  final String title;
  final String desc;
  const _HelpStep(this.num, this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8F00),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('• $text', style: const TextStyle(fontSize: 12)),
    );
  }
}
