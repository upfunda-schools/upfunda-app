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
import '../../features/games/number_detective_screen.dart';
import '../../features/games/wordle_screen.dart';
import '../../features/games/four_shapes_screen.dart';
import '../../features/games/word_scramble_screen.dart';
import '../../features/games/water_reflections_screen.dart';
import '../../features/games/mirror_images_screen.dart';
import '../../features/games/game_2048_screen.dart';
import '../../features/games/what_comes_next_screen.dart';
import '../../features/games/seventy_five_screen.dart';
import '../../features/games/lines_of_symmetry_screen.dart';
import '../../features/games/memory_matching_screen.dart';
import '../../features/auth/open_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/challenge/challenge_home_screen.dart';
import '../../features/challenge/bot/challenge_bot_screen.dart';
import '../../features/challenge/bot/challenge_bot_result_screen.dart';
import '../../features/challenge/room/challenge_room_lobby_screen.dart';
import '../../features/challenge/room/challenge_room_quiz_screen.dart';
import '../../features/challenge/room/challenge_room_result_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier();

  ref.listen(authProvider, (_, __) => notifier.notify());

  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSignupRoute = state.matchedLocation == '/signup';
      final isOpenRoute = state.matchedLocation == '/';

      // Hard-lock: If we are on Login or Signup and not logged in, NEVER redirect to landing page
      if (!isLoggedIn && (isLoginRoute || isSignupRoute)) {
        return null;
      }

      // Only redirect to landing page if truly at an unknown route AND not logged in
      if (!isLoggedIn && !isLoginRoute && !isSignupRoute && !isOpenRoute) {
        return '/';
      }

      // Redirect to home if logged in and trying to access auth pages
      if (isLoggedIn && (isLoginRoute || isOpenRoute || isSignupRoute)) {
        return '/student-home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const OpenScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
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
          final subjectId = state.extra as String? ?? '';
          return QuizScreen(testId: testId, subjectId: subjectId);
        },
      ),
      GoRoute(
        path: '/games/master-arithmetic',
        builder: (context, state) => const MasterArithmeticScreen(),
      ),
      GoRoute(
        path: '/academic-math',
        builder: (context, state) => const WorksheetListScreen(subjectId: 'sub-001'),
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
      GoRoute(
        path: '/games/number-detective',
        builder: (context, state) => const NumberDetectiveScreen(),
      ),
      GoRoute(
        path: '/games/wordle',
        builder: (context, state) => const WordleScreen(),
      ),
      GoRoute(
        path: '/games/four-shapes',
        builder: (context, state) => const FourShapesScreen(),
      ),
      GoRoute(
        path: '/games/word-scramble',
        builder: (context, state) => const WordScrambleScreen(),
      ),
      GoRoute(
        path: '/games/water-reflections',
        builder: (context, state) => const WaterReflectionsScreen(),
      ),
      GoRoute(
        path: '/games/mirror-images',
        builder: (context, state) => const MirrorImagesScreen(),
      ),
      GoRoute(
        path: '/games/2048',
        builder: (context, state) => const Game2048Screen(),
      ),
      GoRoute(
        path: '/games/what-comes-next',
        builder: (context, state) => const WhatComesNextScreen(),
      ),
      GoRoute(
        path: '/games/seventy-five',
        builder: (context, state) => const SeventyFiveScreen(),
      ),
      GoRoute(
        path: '/games/lines-of-symmetry',
        builder: (context, state) => const LinesOfSymmetryScreen(),
      ),
      GoRoute(
        path: '/games/memory-matching',
        builder: (context, state) => const MemoryMatchingScreen(),
      ),

      // Challenge routes
      GoRoute(
        path: '/challenge',
        builder: (context, state) => const ChallengeHomeScreen(),
      ),
      GoRoute(
        path: '/challenge/bot',
        builder: (context, state) => const ChallengeBotScreen(),
      ),
      GoRoute(
        path: '/challenge/bot/result',
        builder: (context, state) => const ChallengeBotResultScreen(),
      ),
      GoRoute(
        path: '/challenge/room/lobby',
        builder: (context, state) => const ChallengeRoomLobbyScreen(),
      ),
      GoRoute(
        path: '/challenge/room/quiz',
        builder: (context, state) => const ChallengeRoomQuizScreen(),
      ),
      GoRoute(
        path: '/challenge/room/result',
        builder: (context, state) => const ChallengeRoomResultScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
