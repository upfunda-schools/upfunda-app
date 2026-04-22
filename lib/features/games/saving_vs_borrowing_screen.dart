import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { intro, calculating, choosing, saving, results }

enum _Choice { save, borrow }

class _Toy {
  final String emoji;
  final String name;
  final int price;
  const _Toy(this.emoji, this.name, this.price);
}

class _LevelConfig {
  final int allowance;
  final List<_Toy> toys;
  final double interestRate;
  final bool allowBorrowing;
  const _LevelConfig({
    required this.allowance,
    required this.toys,
    required this.interestRate,
    required this.allowBorrowing,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SavingVsBorrowingScreen extends StatefulWidget {
  const SavingVsBorrowingScreen({super.key});

  @override
  State<SavingVsBorrowingScreen> createState() =>
      _SavingVsBorrowingScreenState();
}

class _SavingVsBorrowingScreenState extends State<SavingVsBorrowingScreen> {
  // ── Level configurations (mirrors frontend ToyStoreChallenge) ─────────────
  static const _levels = [
    _LevelConfig(
      allowance: 50,
      toys: [_Toy('🚗', 'Small Car', 100), _Toy('📚', 'Coloring Book', 150)],
      interestRate: 0,
      allowBorrowing: false,
    ),
    _LevelConfig(
      allowance: 40,
      toys: [_Toy('🧩', 'Puzzle Set', 120), _Toy('⚽', 'Ball', 160)],
      interestRate: 0,
      allowBorrowing: false,
    ),
    _LevelConfig(
      allowance: 60,
      toys: [
        _Toy('🧱', 'Building Blocks', 180),
        _Toy('🎨', 'Art Set', 240),
      ],
      interestRate: 0,
      allowBorrowing: false,
    ),
    _LevelConfig(
      allowance: 50,
      toys: [_Toy('🤖', 'Robot Toy', 200), _Toy('🎲', 'Board Game', 300)],
      interestRate: 10,
      allowBorrowing: true,
    ),
    _LevelConfig(
      allowance: 60,
      toys: [_Toy('🚲', 'Bicycle', 300), _Toy('🎮', 'Video Game', 360)],
      interestRate: 15,
      allowBorrowing: true,
    ),
    _LevelConfig(
      allowance: 50,
      toys: [_Toy('🚁', 'Drone', 400), _Toy('🔬', 'Science Kit', 250)],
      interestRate: 20,
      allowBorrowing: true,
    ),
    _LevelConfig(
      allowance: 75,
      toys: [_Toy('🔭', 'Telescope', 450), _Toy('🎸', 'Guitar', 600)],
      interestRate: 15,
      allowBorrowing: true,
    ),
    _LevelConfig(
      allowance: 80,
      toys: [_Toy('📷', 'Camera', 640), _Toy('🛹', 'Skateboard', 480)],
      interestRate: 25,
      allowBorrowing: true,
    ),
    _LevelConfig(
      allowance: 70,
      toys: [
        _Toy('🎮', 'Gaming Console', 700),
        _Toy('⌚', 'Smart Watch', 560),
      ],
      interestRate: 20,
      allowBorrowing: true,
    ),
    _LevelConfig(
      allowance: 100,
      toys: [
        _Toy('💻', 'Laptop', 1000),
        _Toy('🛴', 'Electric Scooter', 800),
      ],
      interestRate: 30,
      allowBorrowing: true,
    ),
  ];

  // ── Game state ────────────────────────────────────────────────────────────
  int _currentLevel = 1;
  int _score = 0;
  _Phase _phase = _Phase.intro;

  _Toy? _selectedToy;

  // Calculating
  int _attempts = 0;
  bool _showHint = false;
  String? _calcFeedback;
  final _calcCtrl = TextEditingController();

  // Choosing
  _Choice? _choice;

  // Saving
  int _savings = 0;
  int _weeksPassed = 0;

  // Results
  int _roundPoints = 0;

  // ── Computed ──────────────────────────────────────────────────────────────
  _LevelConfig get _config => _levels[_currentLevel - 1];
  int get _allowance => _config.allowance;
  bool get _borrowingUnlocked => _config.allowBorrowing;
  int get _weeksNeeded => (_selectedToy!.price / _allowance).ceil();
  double get _interestRate => _config.interestRate;
  int get _interestAmount =>
      (_selectedToy!.price * _interestRate / 100).round();
  int get _totalRepay => _selectedToy!.price + _interestAmount;
  bool get _isLastLevel => _currentLevel >= 10;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _calcCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _startNextLevel() {
    setState(() {
      _currentLevel++;
      _phase = _Phase.intro;
      _selectedToy = null;
      _attempts = 0;
      _showHint = false;
      _calcFeedback = null;
      _calcCtrl.clear();
      _choice = null;
      _savings = 0;
      _weeksPassed = 0;
      _roundPoints = 0;
    });
  }

  void _resetGame() {
    setState(() {
      _currentLevel = 1;
      _score = 0;
      _phase = _Phase.intro;
      _selectedToy = null;
      _attempts = 0;
      _showHint = false;
      _calcFeedback = null;
      _calcCtrl.clear();
      _choice = null;
      _savings = 0;
      _weeksPassed = 0;
      _roundPoints = 0;
    });
  }

  void _selectToy(_Toy toy) {
    setState(() {
      _selectedToy = toy;
      _phase = _Phase.calculating;
      _attempts = 0;
      _showHint = false;
      _calcFeedback = null;
      _calcCtrl.clear();
    });
  }

  void _submitCalc() {
    final input = int.tryParse(_calcCtrl.text.trim());
    if (input == null) return;

    if (input == _weeksNeeded) {
      final pts = _attempts == 0 ? 50 : 25;
      setState(() {
        _score += pts;
        _calcFeedback = 'correct';
      });
    } else {
      setState(() {
        _attempts++;
        _calcFeedback = 'wrong';
        if (_attempts >= 2) _showHint = true;
      });
    }
  }

  void _skipCalc() {
    setState(() => _phase = _Phase.choosing);
  }

  void _proceedToChoosing() {
    setState(() => _phase = _Phase.choosing);
  }

  void _choose(_Choice choice) {
    if (choice == _Choice.save) {
      setState(() {
        _choice = choice;
        _phase = _Phase.saving;
        _savings = 0;
        _weeksPassed = 0;
      });
    } else {
      final pts = 50 + (_currentLevel * 5);
      setState(() {
        _choice = choice;
        _roundPoints = pts;
        _score += pts;
        _phase = _Phase.results;
      });
    }
  }

  void _saveWeek() {
    setState(() {
      _weeksPassed++;
      _savings = (_savings + _allowance).clamp(0, _selectedToy!.price);
    });
  }

  void _finishSaving() {
    final pts = 100 + (_currentLevel * 10);
    setState(() {
      _roundPoints = pts;
      _score += pts;
      _phase = _Phase.results;
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
            colors: [Color(0xFFEDE7F6), Color(0xFFE8EAF6), Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildStatsBar(),
              const SizedBox(height: 4),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
              onTap: () => context.pop()),
          Expanded(
            child: Text(
              '🏦 Toy Store Challenge',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4A148C),
              ),
            ),
          ),
          _CircleBtn(
            icon: Icons.refresh_rounded,
            onTap: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Reset Game?'),
                content: const Text('All progress will be lost.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetGame();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A)),
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
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
          _StatPill('Level', '$_currentLevel/10', const Color(0xFF6A1B9A)),
          const SizedBox(width: 8),
          _StatPill('Score', '$_score', const Color(0xFF1B5E20)),
          const SizedBox(width: 8),
          _StatPill(
              'Allowance', '₹$_allowance/wk', const Color(0xFF0D47A1)),
          const SizedBox(width: 8),
          _StatPill(
            'Borrow',
            _borrowingUnlocked ? '🔓' : '🔒 Lvl 4',
            const Color(0xFFB71C1C),
          ),
        ],
      ),
    );
  }

  // ── Phase router ──────────────────────────────────────────────────────────
  Widget _buildPhase() {
    return switch (_phase) {
      _Phase.intro => _buildIntro(),
      _Phase.calculating => _buildCalculating(),
      _Phase.choosing => _buildChoosing(),
      _Phase.saving => _buildSaving(),
      _Phase.results => _buildResults(),
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 1 — Intro
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        _Banner(
          color: const Color(0xFF6A1B9A),
          icon: '🛍️',
          text:
              'Pick a toy you want to buy! Then we\'ll figure out how to get it.',
        ),

        const SizedBox(height: 20),

        Text(
          'Choose a toy:',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),

        const SizedBox(height: 12),

        Row(
          children: _config.toys
              .map((toy) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _ToyCard(
                        toy: toy,
                        onTap: () => _selectToy(toy),
                      ),
                    ),
                  ))
              .toList(),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: '💰',
                label: 'Weekly Allowance',
                value: '₹$_allowance',
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: _borrowingUnlocked ? '🔓' : '🔒',
                label: 'Borrowing',
                value: _borrowingUnlocked
                    ? 'Unlocked!'
                    : 'Unlock at Level 4',
                color: _borrowingUnlocked
                    ? const Color(0xFF1565C0)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 2 — Calculating
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCalculating() {
    final toy = _selectedToy!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: toy.emoji,
                label: 'Toy Price',
                value: '₹${toy.price}',
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoCard(
                icon: '💵',
                label: 'Weekly Allowance',
                value: '₹$_allowance',
                color: const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '🤔 How many weeks do you need to save to buy this toy?',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A148C),
                ),
              ),

              const SizedBox(height: 16),

              if (_calcFeedback == null || _calcFeedback == 'wrong') ...[
                TextField(
                  controller: _calcCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.montserrat(
                      fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    suffixText: 'weeks',
                    hintText: 'Enter number of weeks',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF6A1B9A), width: 2),
                    ),
                  ),
                  onSubmitted: (_) => _submitCalc(),
                ),

                if (_calcFeedback == 'wrong') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF9A9A)),
                    ),
                    child: Text(
                      '❌ Not quite! Try again. (Attempt $_attempts/2)',
                      style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _submitCalc,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Submit Answer'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF43A047)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('✅  Correct!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B5E20),
                              )),
                          const Spacer(),
                          Text(
                            '+${_attempts == 0 ? 50 : 25} pts',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${toy.price} ÷ ₹$_allowance = $_weeksNeeded weeks',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _proceedToChoosing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F00),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Continue →'),
                ),
              ],
            ],
          ),
        ),

        if (_showHint && _calcFeedback != 'correct') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFCC02)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    'Divide toy price by weekly allowance:\n₹${toy.price} ÷ ₹$_allowance = ${toy.price / _allowance}\nRemember to round UP if you get a decimal!',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        TextButton(
          onPressed: _skipCalc,
          child: const Text(
            'Skip Challenge (no points)',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 3 — Choosing
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildChoosing() {
    final toy = _selectedToy!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        Center(
          child: Text(
            '${toy.emoji} ${toy.name}  •  ₹${toy.price}',
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4A148C)),
          ),
        ),

        const SizedBox(height: 6),

        const Center(
          child: Text(
            'How would you like to get it?',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChoiceCard(
                label: 'Save 💚',
                color: const Color(0xFF2E7D32),
                rows: [
                  _ChoiceRow('Weekly allowance', '₹$_allowance'),
                  _ChoiceRow('Weeks needed', '$_weeksNeeded weeks'),
                  _ChoiceRow('Total cost', '₹${toy.price}'),
                  _ChoiceRow('Interest', '₹0'),
                ],
                buttonLabel: '✅ Choose Saving',
                buttonColor: const Color(0xFF2E7D32),
                onTap: () => _choose(_Choice.save),
                locked: false,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _ChoiceCard(
                label: 'Borrow ❤️',
                color: const Color(0xFFC62828),
                rows: [
                  _ChoiceRow('Principal', '₹${toy.price}'),
                  _ChoiceRow('Interest rate', '${_interestRate.toInt()}%'),
                  _ChoiceRow('Interest amount', '₹$_interestAmount'),
                  _ChoiceRow('Total to repay', '₹$_totalRepay'),
                ],
                buttonLabel: _borrowingUnlocked
                    ? '⚡ Choose Borrowing'
                    : '🔒 Unlock at Level 4',
                buttonColor: const Color(0xFFC62828),
                onTap: _borrowingUnlocked
                    ? () => _choose(_Choice.borrow)
                    : null,
                locked: !_borrowingUnlocked,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 4 — Saving
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSaving() {
    final toy = _selectedToy!;
    final progress = (_savings / toy.price).clamp(0.0, 1.0);
    final isDone = _savings >= toy.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        Center(child: Text(toy.emoji, style: const TextStyle(fontSize: 64))),
        const SizedBox(height: 8),
        Center(
          child: Text(
            toy.name,
            style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF4A148C)),
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Savings: ₹$_savings',
                    style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B5E20)),
                  ),
                  Text(
                    'Target: ₹${toy.price}',
                    style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6A1B9A)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 18,
                  backgroundColor: const Color(0xFFEDE7F6),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFF7B1FA2)),
                ),
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B1FA2)),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Week $_weeksPassed of $_weeksNeeded',
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (!isDone) ...[
                ElevatedButton.icon(
                  onPressed: _saveWeek,
                  icon: const Icon(Icons.savings_rounded),
                  label: Text(
                      'Save Week ${_weeksPassed + 1}\'s Allowance (+₹$_allowance)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.montserrat(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '🎉 You\'ve saved enough!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _finishSaving,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F00),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  child: Text('Buy ${toy.name}! 🎉'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Phase 5 — Results
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildResults() {
    final toy = _selectedToy!;
    final saved = _choice == _Choice.save;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: saved
                  ? const [Color(0xFF1B5E20), Color(0xFF2E7D32)]
                  : const [Color(0xFF1565C0), Color(0xFF0D47A1)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                'Congratulations!',
                style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '${toy.emoji} ${toy.name} is yours!',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: saved
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: saved
                  ? const Color(0xFF43A047)
                  : const Color(0xFF1565C0),
            ),
          ),
          child: Text(
            saved
                ? '✅  You chose to SAVE money!'
                : '⚡  You chose to BORROW money!',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: saved
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFF1565C0),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: saved
                ? [
                    _ResultRow('⏳ Weeks waited', '$_weeksPassed weeks'),
                    _ResultRow('💸 Interest paid', '₹0'),
                    _ResultRow('💰 Total cost', '₹${toy.price}'),
                  ]
                : [
                    _ResultRow('📦 Principal', '₹${toy.price}'),
                    _ResultRow(
                        '📈 Interest rate', '${_interestRate.toInt()}%'),
                    _ResultRow('💸 Interest paid', '₹$_interestAmount'),
                    _ResultRow('💳 Total paid', '₹$_totalRepay'),
                  ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFCC02)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(saved ? '🌟 ' : '📚 ',
                  style: const TextStyle(fontSize: 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saved ? 'Wisdom Tip' : 'Learning Point',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF6D4C00)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      saved
                          ? 'By saving, you paid no extra money in interest. Patience saves money! You waited $_weeksPassed weeks and got ${toy.name} for exactly ₹${toy.price}.'
                          : 'By borrowing, you paid ₹$_interestAmount extra in interest. Borrowing is fast but costs more! You paid ₹$_totalRepay for something worth ₹${toy.price}.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                '+$_roundPoints points earned!',
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              Text(
                'Total score: $_score',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_isLastLevel) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF9A825), Color(0xFFF57F17)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  'Game Complete!',
                  style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Final Score: $_score',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: const Text('Play Again 🎮'),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: _startNextLevel,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: Text('Next Level  →  Level ${_currentLevel + 1}'),
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
  const _CircleBtn({required this.icon, required this.onTap});

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
            BoxShadow(
                color: Colors.purple.withValues(alpha: 0.15), blurRadius: 6)
          ],
        ),
        child: Icon(icon, color: const Color(0xFF4A148C), size: 20),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 12, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(label,
                style:
                    TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final String icon;
  final String text;
  const _Banner(
      {required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToyCard extends StatelessWidget {
  final _Toy toy;
  final VoidCallback onTap;
  const _ToyCard({required this.toy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.purple.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(toy.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(
              toy.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '₹${toy.price}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF4A148C),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Pick This',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _InfoCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ChoiceRow {
  final String label;
  final String value;
  const _ChoiceRow(this.label, this.value);
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final Color color;
  final List<_ChoiceRow> rows;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback? onTap;
  final bool locked;

  const _ChoiceCard({
    required this.label,
    required this.color,
    required this.rows,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: color.withValues(alpha: locked ? 0.15 : 0.3), width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: locked ? Colors.grey : color,
              ),
            ),
          ),
          const Divider(height: 16),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r.label,
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  locked ? Colors.grey : Colors.black87)),
                    ),
                    Text(
                      r.value,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: locked ? Colors.grey : color,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: locked ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: locked ? Colors.grey[300] : buttonColor,
              foregroundColor: locked ? Colors.grey : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(buttonLabel, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
