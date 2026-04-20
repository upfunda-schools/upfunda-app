import 'package:flutter/material.dart';

class MasterArithmeticGameInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String route;

  const MasterArithmeticGameInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
  });
}

const kMasterArithmeticGames = [
  MasterArithmeticGameInfo(
    title: 'Doubles Addition',
    description: 'Add a number to itself\n(e.g. 6 + 6)',
    icon: Icons.looks_two_rounded,
    color: Color(0xFFFF7043),
    route: '/games/doubles-addition',
  ),
  MasterArithmeticGameInfo(
    title: 'Near Doubles Addition',
    description: 'Add numbers that are\none apart (e.g. 6 + 7)',
    icon: Icons.compare_arrows_rounded,
    color: Color(0xFF7E57C2),
    route: '/games/near-doubles-addition',
  ),
  MasterArithmeticGameInfo(
    title: 'Making 10s',
    description: 'Find what is missing to\nreach 10',
    icon: Icons.looks_one_rounded,
    color: Color(0xFF26C6DA),
    route: '/games/making-10s',
  ),
  MasterArithmeticGameInfo(
    title: 'Making Next 10',
    description: 'Bridge numbers to\nthe next ten',
    icon: Icons.trending_up_rounded,
    color: Color(0xFFAB47BC),
    route: '/games/making-10s-to-100',
  ),
  MasterArithmeticGameInfo(
    title: 'Times Tables',
    description: 'Master multiplication\ntables 1-12',
    icon: Icons.close_rounded,
    color: Color(0xFF5CA1E8),
    route: '/games/multiplication-tables',
  ),
  MasterArithmeticGameInfo(
    title: 'Doubles & Halves',
    description: 'Use doubles and halves\nfor quick multiplication',
    icon: Icons.balance_rounded,
    color: Color(0xFF4586B4),
    route: '/games/doubles-halves',
  ),
  MasterArithmeticGameInfo(
    title: 'Division',
    description: 'Practice division facts\nand tables',
    icon: Icons.splitscreen_rounded,
    color: Color(0xFFC27174),
    route: '/games/division-tables',
  ),
  MasterArithmeticGameInfo(
    title: '2-Digit Addition',
    description: 'Add two-digit numbers\nwith and without regrouping',
    icon: Icons.add_rounded,
    color: Color(0xFFEC407A),
    route: '/games/two-digit-addition',
  ),
  MasterArithmeticGameInfo(
    title: 'Doubles Subtraction',
    description: 'Halve even numbers\nusing doubles knowledge',
    icon: Icons.remove_rounded,
    color: Color(0xFFFF7043),
    route: '/games/doubles-subtraction',
  ),
  MasterArithmeticGameInfo(
    title: '2-Digit Subtraction',
    description: 'Subtract two-digit numbers\nby tens and ones',
    icon: Icons.remove_rounded,
    color: Color(0xFF1976D2),
    route: '/games/two-digit-subtraction',
  ),
  MasterArithmeticGameInfo(
    title: 'Set Time',
    description: 'Set an analog clock\nto match a given time',
    icon: Icons.schedule_rounded,
    color: Color(0xFFD8AA42),
    route: '/games/set-time',
  ),
  MasterArithmeticGameInfo(
    title: 'Read Time',
    description: 'Read the time shown\non an analog clock',
    icon: Icons.access_time_filled_rounded,
    color: Color(0xFF49AFA5),
    route: '/games/read-time',
  ),
  MasterArithmeticGameInfo(
    title: 'Time Conversion',
    description: 'Convert between\n12-hour and 24-hour time',
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFF977AB8),
    route: '/games/time-conversion',
  ),
  MasterArithmeticGameInfo(
    title: 'Find Missing Numbers',
    description: 'Find missing digits\nin arithmetic problems',
    icon: Icons.search_rounded,
    color: Color(0xFF85C265),
    route: '/games/find-missing-numbers',
  ),
  MasterArithmeticGameInfo(
    title: 'Sudoku 4x4',
    description: 'Complete a 4x4 Sudoku\nwith numbers 1-4',
    icon: Icons.grid_view_rounded,
    color: Color(0xFF5CA1E8),
    route: '/games/sudoku-4x4',
  ),
  MasterArithmeticGameInfo(
    title: 'Balance Numbers',
    description: 'Balance equations by\nchoosing the missing number',
    icon: Icons.balance_rounded,
    color: Color(0xFFEFA046),
    route: '/games/balance-numbers',
  ),
];
