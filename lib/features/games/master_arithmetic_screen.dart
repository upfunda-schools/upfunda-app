import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MasterArithmeticScreen extends StatelessWidget {
  const MasterArithmeticScreen({super.key});

  static const _games = [
    _GameInfo(
      title: 'Doubles Addition',
      description: 'Add a number to itself (e.g. 6 + 6)',
      icon: Icons.looks_two_rounded,
      color: Color(0xFFFF6B35),
      route: '/games/doubles-addition',
    ),
    _GameInfo(
      title: 'Near Doubles',
      description: 'Add numbers that are one apart (e.g. 6 + 7)',
      icon: Icons.compare_arrows_rounded,
      color: Color(0xFF6C5CE7),
      route: '/games/near-doubles',
    ),
    _GameInfo(
      title: 'Making 10s',
      description: 'Find what\'s missing to reach 10 or the next ten',
      icon: Icons.looks_one_rounded,
      color: Color(0xFF00BCD4),
      route: '/games/making-tens',
    ),
    _GameInfo(
      title: 'Making Next 10',
      description: 'Bridge two-digit numbers to the next ten',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF9C27B0),
      route: '/games/making-next-ten',
    ),
    _GameInfo(
      title: '2 Digit Addition',
      description: 'Add two-digit numbers with and without regrouping',
      icon: Icons.add_circle_outline_rounded,
      color: Color(0xFFEF2E73),
      route: '/games/two-digit-addition',
    ),
    _GameInfo(
      title: 'Doubles Subtraction',
      description: 'Halve even numbers using your doubles knowledge',
      icon: Icons.remove_circle_outline_rounded,
      color: Color(0xFFFF5722),
      route: '/games/doubles-subtraction',
    ),
    _GameInfo(
      title: '2 Digit Subtraction',
      description: 'Subtract two-digit numbers by splitting into tens and ones',
      icon: Icons.remove_circle_outline_rounded,
      color: Color(0xFF1976D2),
      route: '/games/two-digit-subtraction',
    ),
    _GameInfo(
      title: 'Balance Numbers',
      description: 'Find the missing number to balance the scale',
      icon: Icons.balance_rounded,
      color: Color(0xFFFF9800),
      route: '/games/balance-numbers',
    ),
    _GameInfo(
      title: 'Find Missing Numbers',
      description: 'Find the hidden digit in column arithmetic',
      icon: Icons.search_rounded,
      color: Color(0xFF1565C0),
      route: '/games/find-missing-numbers',
    ),
    _GameInfo(
      title: 'Skip Counting',
      description: 'Count by 2s, 3s, 4s … 10s',
      icon: Icons.skip_next_rounded,
      color: Color(0xFF0EA5E9),
      route: '/games/skip-counting',
    ),
    _GameInfo(
      title: 'Times Tables',
      description: 'Master multiplication facts',
      icon: Icons.grid_4x4_rounded,
      color: Color(0xFFF59E0B),
      route: '/games/times-tables',
    ),
    _GameInfo(
      title: 'Doubles & Halves',
      description: 'Smart multiplication by halving one, doubling the other',
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFF009688),
      route: '/games/doubles-halves',
    ),
    _GameInfo(
      title: 'Division',
      description: 'Practice division tables — dividends up to 144',
      icon: Icons.splitscreen_rounded,
      color: Color(0xFF3F51B5),
      route: '/games/division',
    ),
    _GameInfo(
      title: 'Set the Time',
      description: 'Drag clock hands to match the target time',
      icon: Icons.schedule_rounded,
      color: Color(0xFF7C3AED),
      route: '/games/set-time',
    ),
    _GameInfo(
      title: 'Read the Time',
      description: 'Look at the clock and type the time you see',
      icon: Icons.watch_rounded,
      color: Color(0xFFD946EF),
      route: '/games/read-time',
    ),
    _GameInfo(
      title: 'Time Conversion',
      description: 'Convert between 12-hour and 24-hour formats',
      icon: Icons.swap_vert_circle_rounded,
      color: Color(0xFF10B981),
      route: '/games/time-conversion',
    ),
    _GameInfo(
      title: 'Sudoku 4×4',
      description: 'Fill the grid — every row, column and box has 1–4',
      icon: Icons.grid_4x4_rounded,
      color: Color(0xFF7C3AED),
      route: '/games/sudoku',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: _games.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) => _GameTile(game: _games[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.calculate_rounded,
                      color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master Arithmetic',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    const Text(
                      'Pick a game and start practising',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game tile ─────────────────────────────────────────────────────────────────

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});

  final _GameInfo game;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(game.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: game.color.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: game.color.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: game.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  game.icon,
                  color: game.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      game.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Arrow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: game.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _GameInfo {
  const _GameInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    this.comingSoon = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
}
