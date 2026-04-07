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
    final isPremium = userState.profile?.isPremiumUser ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: state.isLoading && state.data == null
          ? const LoaderWidget(message: 'Loading worksheets...')
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        // Pixel Perfect Header
                        Padding(
                          padding: EdgeInsets.only(
                            top:
                                MediaQuery.of(context).padding.top +
                                25, // 👈 INCREASE move DOWN
                            left: 10,
                            right: 15,
                            bottom: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Image.asset(
                                      '$_assetPath/Vector_(Stroke).png',
                                      width: 18,
                                      color: _navyColor,
                                    ),
                                    onPressed: () =>
                                        context.go('/student-home'),
                                  ),
                                  Text(
                                    'Worksheets',
                                    style: GoogleFonts.montserrat(
                                      color: _navyColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 140, // Reserved space
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: isPremium
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFFD700),
                                                Color(0xFFFFA500)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.workspace_premium,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'PREMIUM',
                                                style: GoogleFonts.montserrat(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () {},
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B0B2A),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.lock_outline,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Unlock Premium',
                                                  style: GoogleFonts.montserrat(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stats Cards
                        if (state.data != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
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
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: _StatsPostIt(
                                    assetPath: _assetPath,
                                    bgAsset:
                                        'Objects.png', // Green Post-it asset
                                    iconAsset:
                                        'Group.png', // Checkmark/Group icon
                                    label: 'Task Tracker',
                                    value: '${state.data!.pendingWorksheets}',
                                    valueLabel: 'Pending',
                                    iconColor: const Color(0xFF25D366),
                                    textColor: const Color(0xFF25D366),
                                    navyColor: _navyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Wave and Grid
                        Transform.translate(
                          offset: const Offset(0, -40),
                          child: Stack(
                            children: [
                              Image.asset(
                                '$_assetPath/vector.png', // Hero background wave
                                fit: BoxFit.fitWidth,
                                width: double.infinity,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 130,
                                ), // 👈 INCREASE move DOWN
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Text(
                                        'Select a Category and solve\nthe worksheets',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 0,
                                    ), // 👈 INCREASE move DOWN, DECREASE move UP
                                    if (state.data != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Center(
                                          child: Wrap(
                                            spacing: 12,
                                            runSpacing: 10,
                                            children: List.generate(
                                              state.data!.subjects.length,
                                              (index) {
                                                final subject =
                                                    state.data!.subjects[index];
                                                return SizedBox(
                                                  width:
                                                      170, // 👈 Subject card width
                                                  height:
                                                      220, // 👈 Subject card height
                                                  child: _CategoryCardAssetBased(
                                                    assetPath: _assetPath,
                                                    subject: subject,
                                                    index: index,
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
                                    const SizedBox(
                                      height: 0,
                                    ), // 👈 INCREASE move DOWN, DECREASE move UP
                                    GestureDetector(
                                      onTap: () {
                                        // TODO: Implement Download Report functionality
                                      },
                                      child: Image.asset(
                                        '$_assetPath/Leader_Board_Button.png', // The red "Download Report" button asset
                                        height: 45,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ), // 👈 Bottom padding for scrollability
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
}

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
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset('$assetPath/$bgAsset', width: 160, fit: BoxFit.contain),
        Positioned(
          top: 75, // 👈 INCREASE move DOWN, DECREASE move UP
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    '$assetPath/$iconAsset',
                    width: 18,
                    color: iconColor,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value.replaceAll('%', ''),
                    style: GoogleFonts.fredoka(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (value.contains('%'))
                    Text(
                      '%',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -5),
                child: Text(
                  valueLabel,
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
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

class _CategoryCardAssetBased extends StatelessWidget {
  final String assetPath;
  final SubjectSummary subject;
  final int index;
  final VoidCallback onTap;

  const _CategoryCardAssetBased({
    required this.assetPath,
    required this.subject,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Subject specific backgrounds (blobs)
    final List<String> bgAssets = [
      'Rectangle_17.png',
      'Rectangle_18.png',
      'Rectangle_25.png',
      'Rectangle_26.png',
    ];

    // Exact mapping for Title+Header assets
    final String subjectKey = subject.name.toLowerCase();
    String contentAsset = 'Academic_Math.png';
    String iconAsset = 'vaadin_academy-cap.png';
    Color themeColor = const Color(0xFFEF2E73);

    if (subjectKey.contains('logical')) {
      contentAsset = 'Logical_Reasoning.png';
      iconAsset = 'Vector-1.png'; // Puzzle piece
      themeColor = const Color(0xFF00A3FF);
    } else if (subjectKey.contains('mental')) {
      contentAsset = 'Mental_Math.png';
      iconAsset = 'KERTAS1.png'; // Brain icon
      themeColor = const Color(0xFF6366F1); // Modern Indigo/Purple
    } else if (subjectKey.contains('olympiad')) {
      contentAsset = 'Olympiad_Math.png';
      iconAsset = 'Union.png'; // Trophy
      themeColor = const Color(0xFF4ADE80);
    }

    final String bgAsset = bgAssets[index % bgAssets.length];

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Blob Background
          Image.asset('$assetPath/$bgAsset', width: 170, fit: BoxFit.contain),

          // Use Positioned with left/right 0 to ensure horizontal centering
          Positioned(
            top: 35, // 👈 INCREASE move DOWN, DECREASE move UP
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 2. Circular Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    '$assetPath/$iconAsset',
                    width: 26,
                    height: 26,
                    color: subjectKey.contains('academic')
                        ? null
                        : themeColor, // Use original color for Academy Math
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 15),
                // 3. Title Asset
                Image.asset(
                  '$assetPath/$contentAsset',
                  width: 120,
                  height: 35,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 4),
                // 4. Dynamic Progress Bar Cluster
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      // Header: Grade and Percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grade 5', // Static for now or can be dynamic from User
                            style: GoogleFonts.fredoka(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          Text(
                            '${subject.completedPercentage.round()}%',
                            style: GoogleFonts.fredoka(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: themeColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // The Progress Bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value:
                                              subject.completedPercentage / 100,
                                          backgroundColor: Colors.white,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  themeColor),
                                          minHeight: 5,
                                        ),
                                      ),
                      const SizedBox(height: 6),
                      // Footer: Mastered and To Do
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mastered: ${subject.solved}',
                            style: GoogleFonts.fredoka(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          Text(
                            'To Do: ${subject.open}',
                            style: GoogleFonts.fredoka(
                              fontSize: 8.5,
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
