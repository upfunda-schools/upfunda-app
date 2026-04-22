import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/profile_storage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../shared/widgets/loader_widget.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/quick_menu_drawer.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  bool _canLoadStudentData() {
    final authState = ref.read(authProvider);
    return !authState.requiresProfileSelection || ProfileStorage.profileId != null;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final uid = ref.read(firebaseUserProvider).valueOrNull?.uid ?? '';
      final userState = ref.read(userProvider);
      // Skip if data was already loaded (e.g. coming from _selectProfile),
      // or if no profile has been selected yet (would fetch wrong student).
      if (uid.isNotEmpty &&
          _canLoadStudentData() &&
          ProfileStorage.profileId != null &&
          userState.homeData == null) {
        ref.read(userProvider.notifier).loadHome();
        ref.read(userProvider.notifier).loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(firebaseUserProvider, (prev, next) {
      final uid = next.valueOrNull?.uid ?? '';
      if (uid.isNotEmpty &&
          (prev?.valueOrNull?.uid ?? '') != uid &&
          _canLoadStudentData() &&
          ProfileStorage.profileId != null) {
        ref.read(userProvider.notifier).loadHome();
        ref.read(userProvider.notifier).loadProfile();
      }
    });

    final state = ref.watch(userProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FF),
      endDrawer: const QuickMenuDrawer(),
      body: SafeArea(
        child: state.isLoading && state.homeData == null
            ? const LoaderWidget(message: 'Loading...')
            : SingleChildScrollView(
                child: Stack(
                  children: [
                    // --- Background Decorations ---
                    Positioned(
                      top: 130,
                      left: 0,
                      child: Image.asset(
                        'assets/images/home/deco_four.png',
                        width: 90,
                      ),
                    ),
                    Positioned(
                      top: 140,
                      right: 15,
                      child: Image.asset(
                        'assets/images/home/deco_notebook.png',
                        width: 55,
                      ),
                    ),
                    Positioned(
                      top: 270,
                      right: -10,
                      child: Image.asset(
                        'assets/images/home/deco_ruler.png',
                        width: 65,
                      ),
                    ),
                    Positioned(
                      top: 200,
                      left: -30,
                      child: Image.asset(
                        'assets/images/home/deco_objects.png',
                        width: 110,
                      ),
                    ),

                    // --- Main Content ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        children: [
                          // Top Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                'assets/images/home/logo.png',
                                height: 35,
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => context.go('/profile'),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF6C5CE7),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        (state.profile?.name.isNotEmpty ==
                                                true)
                                            ? state.profile!.name[0]
                                                  .toUpperCase()
                                            : 'U',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Builder(
                                    builder: (context) => GestureDetector(
                                      onTap: () => Scaffold.of(context).openEndDrawer(),
                                      child: Image.asset(
                                        'assets/images/home/menu.png',
                                        width: 28,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Daily Quest Indicator
                          if (state.homeData != null)
                            Container(
                              height: 75,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    'assets/images/home/banner_bg.png',
                                  ),
                                  fit: BoxFit.fill,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/home/megaphone.png',
                                    width: 35,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Worksheet',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFA58AFF),
                                          ),
                                        ),
                                        Text(
                                          'Arithmetic Drill (${state.homeData != null ? state.homeData!.stats.solvedWorksheets : 0}/${state.homeData != null ? state.homeData!.stats.totalWorksheets : 1}) completed',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C5CE7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${(state.homeData != null && state.homeData!.stats.totalWorksheets > 0) ? (state.homeData!.stats.solvedWorksheets / state.homeData!.stats.totalWorksheets * 100).toInt() : 10}%',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Greeting
                          const SizedBox(height: 4),
                          Column(
                            children: [
                              Text(
                                'Hey',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9181F2),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '${state.profile?.name ?? 'Student'},',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9181F2),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'ready to solve?',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF1659C),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              state.profile?.schoolName ?? 'Upfunda School',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Choose Mission Button
                          Image.asset(
                            'assets/images/home/mission_button.png',
                            width: 210,
                          ),
                          const SizedBox(height: 16),

                          // Cards Grid
                          if (state.isLoading)
                            const GridSkeleton()
                          else
                            GridView.count(
                              crossAxisCount: isDesktop ? 4 : 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.8,
                              children: [
                                GestureDetector(
                                  onTap: () => context.go('/worksheets'),
                                  child: Image.asset(
                                    'assets/images/home/card_worksheets.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/challenge'),
                                  child: Image.asset(
                                    'assets/images/home/card_challenge.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context
                                      .push('/games/master-arithmetic'),
                                  child: Image.asset(
                                    'assets/images/home/card_math_gym.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/games'),
                                  child: Image.asset(
                                    'assets/images/home/card_games.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),

                          const SizedBox(height: 12),
                          // Leaderboard button
                          GestureDetector(
                            onTap: () => context.push('/leaderboard'),
                            child: Image.asset(
                              'assets/5. Home Page/Leader_Board_Button.png',
                              width: 220,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.75,
      children: List.generate(4, (_) => const SkeletonCard()),
    );
  }
}
