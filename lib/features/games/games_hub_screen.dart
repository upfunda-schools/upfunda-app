import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  static const _games = [
    _GameCard(
      emoji: '🍋',
      title: 'Lemonade Stand',
      description: 'Run a lemonade business! Buy supplies, set prices, and earn profit over multiple days.',
      tags: ['Business', 'Money', 'Strategy'],
      gradient: [Color(0xFFFFB300), Color(0xFFFF8F00)],
      route: '/games/lemonade-stand',
    ),
    _GameCard(
      emoji: '💱',
      title: 'Money Exchanger',
      description: 'Convert currencies to Indian Rupees using live exchange rates. Level up as you improve!',
      tags: ['Currency', 'Maths', 'Finance'],
      gradient: [Color(0xFF2E7D32), Color(0xFF1565C0)],
      route: '/games/money-exchanger',
    ),
    _GameCard(
      emoji: '🏦',
      title: 'Toy Store Challenge',
      description: 'Pick a toy, calculate how long to save, then decide — save patiently or borrow and pay interest!',
      tags: ['Saving', 'Borrowing', 'Interest'],
      gradient: [Color(0xFF6A1B9A), Color(0xFF4527A0)],
      route: '/games/saving-vs-borrowing',
    ),
    _GameCard(
      emoji: '🏎️',
      title: 'Arithmetic Car Race',
      description: 'Answer maths questions to race your car against AI opponents. First to finish wins!',
      tags: ['Maths', 'Speed', 'Racing'],
      gradient: [Color(0xFF1A237E), Color(0xFFAD1457)],
      route: '/games/race-to-finish',
    ),
    _GameCard(
      emoji: '🪢',
      title: 'Tug of War Maths',
      description: 'Answer maths questions to pull the rope! Beat the AI across 8 levels of difficulty.',
      tags: ['Maths', 'Strategy', 'AI'],
      gradient: [Color(0xFF0A1628), Color(0xFF311B92)],
      route: '/games/tug-of-war',
    ),
    _GameCard(
      emoji: '🔍',
      title: 'Number Detective',
      description: 'Crack logical clues to uncover the mystery number! Grades 1–5 with 3 attempts per case.',
      tags: ['Logic', 'Maths', 'Deduction'],
      gradient: [Color(0xFFF59E0B), Color(0xFFEAB308)],
      route: '/games/number-detective',
    ),
    _GameCard(
      emoji: '🟩',
      title: 'Wordle',
      description: 'Guess the hidden 5-letter word in 6 tries! Color clues guide you to the answer.',
      tags: ['Words', 'Spelling', 'Logic'],
      gradient: [Color(0xFF16A34A), Color(0xFF15803D)],
      route: '/games/wordle',
    ),
    _GameCard(
      emoji: '🔷',
      title: 'Four Shapes',
      description: 'Drag and sort 12 mixed shapes into 4 columns — one shape type per column!',
      tags: ['Shapes', 'Puzzle', 'Sorting'],
      gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      route: '/games/four-shapes',
    ),
    _GameCard(
      emoji: '🔤',
      title: 'Word Scramble',
      description: 'Unscramble the shuffled letters to find the hidden word. 35 words with helpful hints!',
      tags: ['Words', 'Spelling', 'Puzzle'],
      gradient: [Color(0xFF7C3AED), Color(0xFFDB2777)],
      route: '/games/word-scramble',
    ),
    _GameCard(
      emoji: '💧',
      title: 'Water Reflections',
      description: 'Spot the correct water reflection of a grid pattern. Learn vertical flip, mirror, and rotation!',
      tags: ['Patterns', 'Logic', 'Geometry'],
      gradient: [Color(0xFF2563EB), Color(0xFF0891B2)],
      route: '/games/water-reflections',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F6FF), Color(0xFFEDE7F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '🎮 Games',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4A148C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(
                  'Learn by playing! Choose a game to start.',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // Games list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _games.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) => _GameTile(game: _games[i]),
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
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _GameCard {
  final String emoji;
  final String title;
  final String description;
  final List<String> tags;
  final List<Color> gradient;
  final String route;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.tags,
    required this.gradient,
    required this.route,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile widget
// ─────────────────────────────────────────────────────────────────────────────

class _GameTile extends StatelessWidget {
  final _GameCard game;
  const _GameTile({required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(game.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: game.gradient.first.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji side
            Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: game.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Text(game.emoji, style: const TextStyle(fontSize: 42)),
              ),
            ),

            // Info side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: game.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: game.gradient.first.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: game.gradient.first,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: game.gradient.first,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
