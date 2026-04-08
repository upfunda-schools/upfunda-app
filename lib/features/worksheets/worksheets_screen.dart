import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/worksheet_provider.dart';
import '../../providers/user_provider.dart';
import '../../shared/widgets/loader_widget.dart';
import '../../data/models/home_model.dart';

class WorksheetsScreen extends ConsumerStatefulWidget {
  const WorksheetsScreen({super.key});

  @override
  ConsumerState<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends ConsumerState<WorksheetsScreen> {
  final String _assetPath = 'assets/images/home';
  final Color _navyColor = const Color(0xFF0B0B45);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(worksheetProvider.notifier).loadSubjects();
      ref.read(userProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(worksheetProvider);
    final userState = ref.watch(userProvider);
    final isPremium = (userState.profile?.isPremiumUser ?? false) ||
        (userState.homeData?.isPremiumUser ?? false);

    // Single scale factor relative to iPhone 13 Pro (390 logical px wide).
    // Clamped so tiny phones don't shrink too much and tablets don't over-expand.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 390.0).clamp(0.80, 1.35);
    final double safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: state.isLoading && state.data == null
          ? const LoaderWidget(message: 'Loading worksheets...')
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // ── Header ─────────────────────────────────────────
                        Padding(
                          padding: EdgeInsets.only(
                            top: safeTop + 25 * scale,
                            left: 10 * scale,
                            right: 15 * scale,
                            bottom: 10 * scale,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Image.asset(
                                        '$_assetPath/Vector_(Stroke).png',
                                        width: 18 * scale,
                                        color: _navyColor,
                                      ),
                                      onPressed: () =>
                                          context.go('/student-home'),
                                    ),
                                    SizedBox(width: 4 * scale),
                                    Flexible(
                                      child: Text(
                                        'Worksheets',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          color: _navyColor,
                                          fontSize: 18 * scale,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8 * scale),
                              _buildPremiumOrUnlock(isPremium, scale),
                            ],
                          ),
                        ),

                        // ── Stats cards (Accuracy + Task Tracker) ──────────
                        if (state.data != null)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 25 * scale,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatsPostIt(
                                    assetPath: _assetPath,
                                    bgAsset: 'Objects-1.png',
                                    iconAsset: 'gravity-ui_target-dart.png',
                                    label: 'Accuracy',
                                    value:
                                        '${state.data!.overallAccuracy.round()}%',
                                    valueLabel: 'Overall',
                                    iconColor: const Color(0xFFFF6781),
                                    textColor: const Color(0xFFFF6781),
                                    navyColor: _navyColor,
                                    scale: scale,
                                  ),
                                ),
                                SizedBox(width: 2 * scale),
                                Expanded(
                                  child: _StatsPostIt(
                                    assetPath: _assetPath,
                                    bgAsset: 'Objects.png',
                                    iconAsset: 'Group.png',
                                    label: 'Task Tracker',
                                    value: '${state.data!.pendingWorksheets}',
                                    valueLabel: 'Pending',
                                    iconColor: const Color(0xFF25D366),
                                    textColor: const Color(0xFF25D366),
                                    navyColor: _navyColor,
                                    scale: scale,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // ── Wave + Category grid ────────────────────────────
                        Transform.translate(
                          offset: Offset(0, -40 * scale),
                          child: Stack(
                            children: [
                              // Navy wave background
                              Image.asset(
                                '$_assetPath/Vector.png',
                                fit: BoxFit.fitWidth,
                                width: double.infinity,
                              ),

                              Padding(
                                padding: EdgeInsets.only(top: 130 * scale),
                                child: Column(
                                  children: [
                                    // Category heading
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20 * scale,
                                      ),
                                      child: Text(
                                        'Select a Category and solve\nthe worksheets',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16 * scale,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                    ),

                                    // Category grid
                                    if (state.data != null)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10 * scale,
                                        ),
                                        child: Center(
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 15 * scale,
                                            runSpacing: 15 * scale,
                                            children: List.generate(
                                              state.data!.subjects.length,
                                              (index) {
                                                final subject =
                                                    state.data!.subjects[index];
                                                return SizedBox(
                                                  width: 170 * scale,
                                                  height: 220 * scale,
                                                  child:
                                                      _CategoryCardAssetBased(
                                                    assetPath: _assetPath,
                                                    subject: subject,
                                                    index: index,
                                                    scale: scale,
                                                    onTap: () => context.go(
                                                      '/worksheets-list/${subject.subjectId}',
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Download report button
                                    GestureDetector(
                                      onTap: () {}, // Handle report download here
                                      child: Image.asset(
                                        'assets/images/home/Leader_Board_Button.png',
                                        height: 38 * scale,
                                        fit: BoxFit.contain,
                                      ),
                                    ),

                                    SizedBox(height: 20 * scale),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildPremiumOrUnlock(bool isPremium, double scale) {
    return isPremium ? _buildPremiumBadge(scale) : _buildUnlockButton(scale);
  }

  Widget _buildPremiumBadge(double scale) {
    return Image.asset(
      'assets/images/home/premium_main_2.png',
      height: 32 * scale,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 32 * scale,
        width: 95 * scale,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16 * scale),
        ),
      ),
    );
  }

  Widget _buildUnlockButton(double scale) {
    return Image.asset(
      'assets/images/home/premium_main_2.png',
      height: 32 * scale,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 32 * scale,
        width: 95 * scale,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16 * scale),
        ),
      ),
    );
  }
}

// ── Stats post-it card ────────────────────────────────────────────────────────

class _StatsPostIt extends StatelessWidget {
  final String assetPath;
  final String bgAsset;
  final String iconAsset;
  final String label;
  final String value;
  final String valueLabel;
  final Color iconColor;
  final Color textColor;
  final Color navyColor;
  final double scale;

  const _StatsPostIt({
    required this.assetPath,
    required this.bgAsset,
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.iconColor,
    required this.textColor,
    required this.navyColor,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          '$assetPath/$bgAsset',
          width: 160 * scale,
          fit: BoxFit.contain,
        ),
        Positioned(
          top: 75 * scale,
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    '$assetPath/$iconAsset',
                    width: 18 * scale,
                    color: iconColor,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value.replaceAll('%', ''),
                    style: GoogleFonts.fredoka(
                      fontSize: 38 * scale,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (value.contains('%'))
                    Text(
                      '%',
                      style: GoogleFonts.fredoka(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                ],
              ),
              Transform.translate(
                offset: Offset(0, -5 * scale),
                child: Text(
                  valueLabel,
                  style: GoogleFonts.fredoka(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCardAssetBased extends StatelessWidget {
  final String assetPath;
  final SubjectSummary subject;
  final int index;
  final VoidCallback onTap;
  final double scale;

  const _CategoryCardAssetBased({
    required this.assetPath,
    required this.subject,
    required this.index,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> bgAssets = [
      'Rectangle_17.png',
      'Rectangle_18.png',
      'Rectangle_25.png',
      'Rectangle_26.png',
    ];

    final String subjectKey = subject.name.toLowerCase();
    String iconAsset = 'vaadin_academy-cap.png';
    Color themeColor = const Color(0xFFEF2E73);

    if (subjectKey.contains('logical')) {
      iconAsset = 'Vector-1.png';
      themeColor = const Color(0xFF00A3FF);
    } else if (subjectKey.contains('mental')) {
      iconAsset = 'KERTAS1.png';
      themeColor = const Color(0xFF8D72CC);
    } else if (subjectKey.contains('olympiad')) {
      iconAsset = 'Union.png';
      themeColor = const Color(0xFF48AC56);
    }

    final String bgAsset = bgAssets[index % bgAssets.length];

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blob background
          Image.asset(
            '$assetPath/$bgAsset',
            width: 170 * scale,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 170 * scale,
              height: 220 * scale,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24 * scale),
                border: Border.all(color: themeColor.withValues(alpha: 0.2)),
              ),
            ),
          ),

          Positioned(
            top: 35 * scale,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular icon
                Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    '$assetPath/$iconAsset',
                    width: 26 * scale,
                    height: 26 * scale,
                    color: (subjectKey.contains('academic') ||
                            subjectKey.contains('academy'))
                        ? null
                        : themeColor,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 15 * scale),

                // Subject title text using Cherry Bomb One
                SizedBox(
                  width: 150 * scale,
                  height: 35 * scale,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subject.name,
                        style: GoogleFonts.cherryBombOne(
                          fontSize: 22 * scale,
                          color: const Color(0xFF2C2C4B),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4 * scale),

                // Progress cluster
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14 * scale),
                  child: Column(
                    children: [
                      // Grade + percentage row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grade 5',
                            style: GoogleFonts.fredoka(
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          Text(
                            '${subject.completedPercentage.round()}%',
                            style: GoogleFonts.fredoka(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w700,
                              color: themeColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4 * scale),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10 * scale),
                        child: LinearProgressIndicator(
                          value: subject.completedPercentage / 100,
                          backgroundColor: Colors.white,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor),
                          minHeight: 5 * scale,
                        ),
                      ),
                      SizedBox(height: 6 * scale),

                      // Mastered + To Do row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mastered: ${subject.solved}',
                            style: GoogleFonts.fredoka(
                              fontSize: 8.5 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          Text(
                            'To Do: ${subject.open}',
                            style: GoogleFonts.fredoka(
                              fontSize: 8.5 * scale,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
