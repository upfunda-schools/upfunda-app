import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/student_home/student_home_screen.dart';
import '../../features/worksheets/worksheets_screen.dart';
import '../../features/worksheets/worksheet_list_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/games/doubles_addition_screen.dart';
import '../../features/games/master_arithmetic_screen.dart';
import '../../features/games/near_doubles_screen.dart';
import '../../features/games/making_tens_screen.dart';
import '../../features/games/making_next_ten_screen.dart';
import '../../features/games/two_digit_addition_screen.dart';
import '../../features/games/doubles_subtraction_screen.dart';
import '../../features/games/two_digit_subtraction_screen.dart';
import '../../features/games/balance_numbers_screen.dart';
import '../../features/games/find_missing_numbers_screen.dart';
import '../../features/games/multiplication_tables_screen.dart';
import '../../features/games/skip_counting_screen.dart';
import '../../features/games/doubles_halves_screen.dart';
import '../../features/games/division_screen.dart';
import '../../features/games/set_time_screen.dart';
import '../../features/games/read_time_screen.dart';
import '../../features/games/time_conversion_screen.dart';
import '../../features/games/sudoku_screen.dart';
import '../../features/games/games_hub_screen.dart';
import '../../features/games/lemonade_stand_screen.dart';
import '../../features/games/money_exchanger_screen.dart';
import '../../features/games/saving_vs_borrowing_screen.dart';
import '../../features/games/race_to_finish_screen.dart';
import '../../features/games/tug_of_war_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/student-home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student-home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/worksheets',
        builder: (context, state) => const WorksheetsScreen(),
      ),
      GoRoute(
        path: '/worksheets-list/:id',
        builder: (context, state) {
          final subjectId = state.pathParameters['id']!;
          return WorksheetListScreen(subjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/quiz/:id',
        builder: (context, state) {
          final testId = state.pathParameters['id']!;
          return QuizScreen(testId: testId);
        },
      ),
      GoRoute(
        path: '/games/master-arithmetic',
        builder: (context, state) => const MasterArithmeticScreen(),
      ),
      GoRoute(
        path: '/games/doubles-addition',
        builder: (context, state) => const DoublesAdditionScreen(),
      ),
      GoRoute(
        path: '/games/near-doubles',
        builder: (context, state) => const NearDoublesScreen(),
      ),
      GoRoute(
        path: '/games/making-tens',
        builder: (context, state) => const MakingTensScreen(),
      ),
      GoRoute(
        path: '/games/making-next-ten',
        builder: (context, state) => const MakingNextTenScreen(),
      ),
      GoRoute(
        path: '/games/two-digit-addition',
        builder: (context, state) => const TwoDigitAdditionScreen(),
      ),
      GoRoute(
        path: '/games/doubles-subtraction',
        builder: (context, state) => const DoublesSubtractionScreen(),
      ),
      GoRoute(
        path: '/games/two-digit-subtraction',
        builder: (context, state) => const TwoDigitSubtractionScreen(),
      ),
      GoRoute(
        path: '/games/balance-numbers',
        builder: (context, state) => const BalanceNumbersScreen(),
      ),
      GoRoute(
        path: '/games/find-missing-numbers',
        builder: (context, state) => const FindMissingNumbersScreen(),
      ),
      GoRoute(
        path: '/games/times-tables',
        builder: (context, state) => const MultiplicationTablesScreen(),
      ),
      GoRoute(
        path: '/games/skip-counting',
        builder: (context, state) => const SkipCountingScreen(),
      ),
      GoRoute(
        path: '/games/doubles-halves',
        builder: (context, state) => const DoublesHalvesScreen(),
      ),
      GoRoute(
        path: '/games/division',
        builder: (context, state) => const DivisionScreen(),
      ),
      GoRoute(
        path: '/games/set-time',
        builder: (context, state) => const SetTimeScreen(),
      ),
      GoRoute(
        path: '/games/read-time',
        builder: (context, state) => const ReadTimeScreen(),
      ),
      GoRoute(
        path: '/games/time-conversion',
        builder: (context, state) => const TimeConversionScreen(),
      ),
      GoRoute(
        path: '/games/sudoku',
        builder: (context, state) => const SudokuScreen(),
      ),
      GoRoute(
        path: '/games',
        builder: (context, state) => const GamesHubScreen(),
      ),
      GoRoute(
        path: '/games/lemonade-stand',
        builder: (context, state) => const LemonadeStandScreen(),
      ),
      GoRoute(
        path: '/games/money-exchanger',
        builder: (context, state) => const MoneyExchangerScreen(),
      ),
      GoRoute(
        path: '/games/saving-vs-borrowing',
        builder: (context, state) => const SavingVsBorrowingScreen(),
      ),
      GoRoute(
        path: '/games/race-to-finish',
        builder: (context, state) => const RaceToFinishScreen(),
      ),
      GoRoute(
        path: '/games/tug-of-war',
        builder: (context, state) => const TugOfWarScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
