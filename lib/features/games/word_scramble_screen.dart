import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Word bank
// ─────────────────────────────────────────────────────────────────────────────

class _WordEntry {
  final String word;
  final String hint;
  const _WordEntry(this.word, this.hint);
}

const _wordBank = [
  _WordEntry('STAR', 'You can see these in the night sky'),
  _WordEntry('FISH', 'Lives in water and has fins'),
  _WordEntry('BOOK', 'You read this to learn stories'),
  _WordEntry('TREE', 'Has branches and grows from the ground'),
  _WordEntry('MOON', 'Glows in the night sky'),
  _WordEntry('BIRD', 'Has wings and can fly'),
  _WordEntry('APPLE', 'A round red or green fruit'),
  _WordEntry('BREAD', 'Baked food made from flour'),
  _WordEntry('CHAIR', 'You sit on this'),
  _WordEntry('DREAM', 'Happens when you sleep'),
  _WordEntry('EARTH', 'The planet we live on'),
  _WordEntry('FLAME', 'Hot, glowing light from fire'),
  _WordEntry('GRAPE', 'Small round fruit that grows in clusters'),
  _WordEntry('HEART', 'Pumps blood through your body'),
  _WordEntry('HOUSE', 'A place where people live'),
  _WordEntry('LEMON', 'Sour yellow citrus fruit'),
  _WordEntry('MUSIC', 'Sounds made in a pleasing way'),
  _WordEntry('OCEAN', 'A vast body of salt water'),
  _WordEntry('PHONE', 'Device used to make calls'),
  _WordEntry('PLANT', 'A living thing that grows in soil'),
  _WordEntry('RIVER', 'Flowing water between banks'),
  _WordEntry('SMILE', 'What your face does when happy'),
  _WordEntry('TIGER', 'A large striped wild cat'),
  _WordEntry('WATER', 'Clear liquid we drink'),
  _WordEntry('YELLOW', 'Color of the sun'),
  _WordEntry('FLOWER', 'Colorful part of a plant'),
  _WordEntry('GARDEN', 'Place where plants are grown'),
  _WordEntry('ORANGE', 'Round citrus fruit, also a color'),
  _WordEntry('PLANET', 'Large object orbiting a star'),
  _WordEntry('PENCIL', 'Tool used to write or draw'),
  _WordEntry('RABBIT', 'Small furry animal with long ears'),
  _WordEntry('SPRING', 'Season after winter'),
  _WordEntry('SUMMER', 'Hottest season of the year'),
  _WordEntry('TURTLE', 'Slow reptile with a hard shell'),
  _WordEntry('WINTER', 'Coldest season of the year'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Scramble helper
// ─────────────────────────────────────────────────────────────────────────────

String _scramble(String word) {
  final rng = Random();
  final chars = word.split('');
  String result;
  do {
    for (var i = chars.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
    result = chars.join();
  } while (result == word);
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class WordScrambleScreen extends StatefulWidget {
  const WordScrambleScreen({super.key});

  @override
  State<WordScrambleScreen> createState() => _WordScrambleScreenState();
}

class _WordScrambleScreenState extends State<WordScrambleScreen> {
  late _WordEntry _current;
  late String _scrambled;
  String _userInput = '';
  int _score = 0;
  int _round = 1;
  final List<String> _usedWords = [];
  String? _showResult; // 'correct' | 'incorrect' | null
  bool _showHint = false;
  bool _gameComplete = false;

  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  Timer? _resultTimer;

  @override
  void initState() {
    super.initState();
    _startNextWord();
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    _inputCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _startNextWord() {
    final rng = Random();
    final available = _wordBank.where((e) => !_usedWords.contains(e.word)).toList();
    if (available.isEmpty) {
      setState(() => _gameComplete = true);
      return;
    }
    final entry = available[rng.nextInt(available.length)];
    _usedWords.add(entry.word);
    setState(() {
      _current = entry;
      _scrambled = _scramble(entry.word);
      _userInput = '';
      _showResult = null;
      _showHint = false;
    });
    _inputCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inputFocus.requestFocus());
  }

  void _checkAnswer() {
    if (_userInput.isEmpty || _showResult != null) return;
    final correct = _userInput.toUpperCase() == _current.word;
    setState(() => _showResult = correct ? 'correct' : 'incorrect');
    if (correct) setState(() => _score += 10);

    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (correct) {
        setState(() => _round++);
        _startNextWord();
      } else {
        setState(() {
          _showResult = null;
          _userInput = '';
        });
        _inputCtrl.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) => _inputFocus.requestFocus());
      }
    });
  }

  void _skip() {
    if (_showResult != null) return;
    setState(() => _round++);
    _startNextWord();
  }

  void _resetGame() {
    _resultTimer?.cancel();
    _usedWords.clear();
    setState(() {
      _score = 0;
      _round = 1;
      _showResult = null;
      _showHint = false;
      _gameComplete = false;
    });
    _startNextWord();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F0FF), Color(0xFFFFEFF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 14),
                      _buildScoreBar(),
                      const SizedBox(height: 18),
                      _gameComplete ? _buildCompleteCard() : _buildGameCard(),
                      const SizedBox(height: 18),
                      if (!_gameComplete) _buildHowToPlay(),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF7C3AED)),
            label: Text(
              'Games',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Word Scramble',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6D28D9),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF7C3AED)),
            label: Text(
              'New Game',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Guess the Word',
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF6D28D9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Unscramble the letters to find the hidden word',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildScoreBar() {
    return Row(
      children: [
        _StatCard(label: 'Round', value: '$_round / 35', color: const Color(0xFF7C3AED)),
        const SizedBox(width: 12),
        _StatCard(label: 'Score', value: '$_score pts', color: const Color(0xFFDB2777)),
      ],
    );
  }

  Widget _buildGameCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Scrambled letter tiles
          _buildLetterTiles(),
          const SizedBox(height: 20),

          // Hint button + text
          _buildHintSection(),
          const SizedBox(height: 20),

          // Text input
          _buildInput(),
          const SizedBox(height: 16),

          // Result message
          if (_showResult != null) ...[
            _buildResultBanner(),
            const SizedBox(height: 16),
          ],

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildLetterTiles() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _scrambled.split('').map((letter) {
        return Container(
          width: 46,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF6D28D9),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHintSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showHint = !_showHint),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _showHint ? 'Hide Hint' : 'Show Hint',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showHint) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _current.hint,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInput() {
    return TextField(
      controller: _inputCtrl,
      focusNode: _inputFocus,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      maxLength: _current.word.length,
      style: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 4,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '_ ' * _current.word.length,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.4),
          letterSpacing: 4,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      onChanged: (val) {
        final upper = val.toUpperCase();
        setState(() => _userInput = upper);
        if (_inputCtrl.text != upper) {
          _inputCtrl.value = _inputCtrl.value.copyWith(
            text: upper,
            selection: TextSelection.collapsed(offset: upper.length),
          );
        }
      },
      onSubmitted: (_) => _checkAnswer(),
    );
  }

  Widget _buildResultBanner() {
    final isCorrect = _showResult == 'correct';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
                .withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            isCorrect ? 'Correct! +10 points' : 'Try Again! Keep going!',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final disabled = _userInput.isEmpty || _showResult != null;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showResult != null ? null : _skip,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: Text(
                'Skip',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: disabled ? null : _checkAnswer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: disabled ? Colors.white.withValues(alpha: 0.3) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: disabled
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                'Check Answer',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: disabled ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6D28D9),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0FF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Game Complete!',
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF6D28D9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Final Score: $_score points',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDB2777),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You completed all 35 words!',
            style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _resetGame,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Play Again',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlay() {
    final tips = [
      'Unscramble the letters to form a word',
      'Use the hint if you need help',
      'Each correct answer = 10 points',
      'Skip words you don\'t know',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Play',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF6D28D9)),
          ),
          const SizedBox(height: 8),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
