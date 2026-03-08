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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
