import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/test_list_provider.dart';
import '../../providers/worksheet_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/topics_model.dart';

class WorksheetListScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const WorksheetListScreen({super.key, required this.subjectId});

  @override
  ConsumerState<WorksheetListScreen> createState() =>
      _WorksheetListScreenState();
}

class _WorksheetListScreenState extends ConsumerState<WorksheetListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(WorksheetListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId) {
      _loadData();
    }
  }

  void _loadData() {
    Future.microtask(
      () => ref.read(testListProvider.notifier).loadTopics(widget.subjectId),
    );
  }

  Color _getHeaderColor(String subjectId) {
    if (subjectId == 'sub-004') return const Color(0xFF44A5BA); // Logic Blue
    final state = ref.read(testListProvider);
    final name = state.data?.subjectName.toLowerCase() ?? '';
    if (name.contains('logical')) return const Color(0xFF44A5BA);
    if (name.contains('mental')) return const Color(0xFF8D72CC); // Lavender/Purple
    if (name.contains('olympiad')) return const Color(0xFF48AC56); // Green
    return const Color(0xFFD91E5B); // Academic Math Pink
  }

  String _getAssetPath(String subjectId) {
    if (subjectId == 'sub-004') return 'assets/8. Logical Reasoning';
    final state = ref.read(testListProvider);
    final name = state.data?.subjectName.toLowerCase() ?? '';
    if (name.contains('logical')) return 'assets/8. Logical Reasoning';
    if (name.contains('mental')) return 'assets/9. Mental Math';
    if (name.contains('olympiad')) return 'assets/10. Olympiad path';
    return 'assets/7. Academy Path';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testListProvider);
    final userState = ref.watch(userProvider);
    final isPremiumUser = (userState.profile?.isPremiumUser ?? false) ||
        (userState.homeData?.isPremiumUser ?? false);
    final subjectName = state.data?.subjectName ?? 'Topics';
    final assetPath = _getAssetPath(widget.subjectId);

    // Single scale factor relative to iPhone 13 Pro (390 logical px wide).
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 390.0).clamp(0.80, 1.35);

    final themeColor = _getHeaderColor(widget.subjectId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // ── 1. Thematic background (now scrollable) ──────────────
              Container(
                height: 410 * scale,
                width: double.infinity,
                color: themeColor,
                child: Opacity(
                  opacity: 0.40,
                  child: Image.asset(
                    '$assetPath/image 10.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // ── 2. Content Column (Header + Search + Cards) ───────────
              Column(
                children: [
                  // Proper spacing for top status bar
                  SizedBox(height: MediaQuery.of(context).padding.top + 8 * scale),

                  // Header (back button, subject title, premium controls)
                  _buildHeader(
                    context,
                    subjectName,
                    isPremiumUser,
                    scale,
                    assetPath,
                  ),

                  SizedBox(height: 10 * scale),
                  _buildMasterArithmeticButton(scale),
                  SizedBox(height: 15 * scale),
                  _buildSearchBar(scale),
                  SizedBox(height: 15 * scale),
                  Text(
                    '${state.filteredTopics.length} TOPICS FOUND',
                    style: GoogleFonts.cherryBombOne(
                      color: Colors.white,
                      fontSize: 16 * scale,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22 * scale),

                  // ── Wave + Banner + Cards stack ───────────────────────────
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // White wave transition
                      Transform.translate(
                        offset: Offset(0, -60 * scale),
                        child: Image.asset(
                          '$assetPath/Vector.png',
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                        ),
                      ),

                      // "SELECT A TOPIC" banner
                      Positioned(
                        top: 25 * scale,
                        child: Image.asset(
                          '$assetPath/Group 40.png',
                          width: 220 * scale,
                        ),
                      ),

                      // Topic cards
                      Container(
                        margin: EdgeInsets.only(top: 110 * scale),
                        width: double.infinity,
                        color: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 22 * scale,
                        ),
                        child: Column(
                          children: [
                              ...state.filteredTopics.map(
                                (topic) => _TopicCard(
                                  topic: topic,
                                  subjectId: widget.subjectId,
                                  isPremiumUser: isPremiumUser,
                                  scale: scale,
                                  assetPath: assetPath,
                                  themeColor: themeColor,
                                ),
                              ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

      ),
    );
  }

  // ── Header row (back button + subject name + premium badge) ──────────────

  Widget _buildHeader(
    BuildContext context,
    String subjectName,
    bool isPremiumUser,
    double scale,
    String assetPath,
  ) {
    final bool isAcademic = assetPath.contains('Academy Path');
    final subjects = ref.watch(worksheetProvider).data?.subjects ?? [];
    final currentIndex =
        subjects.indexWhere((s) => s.subjectId == widget.subjectId);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Nav Back + Premium Control ─────────────────
          SizedBox(
            height: 50 * scale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Image.asset(
                          '$assetPath/Vector (Stroke).png',
                          width: 22 * scale,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.arrow_back,
                                  color: Colors.white, size: 24 * scale),
                        ),
                        onPressed: () => context.go('/worksheets'),
                      ),
                      SizedBox(width: 4 * scale),
                      Flexible(
                        child: Text(
                          subjectName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4 * scale),
                isPremiumUser
                    ? _buildPremiumBadge(scale)
                    : _buildUnlockPremiumButton(scale, assetPath),
              ],
            ),
          ),
          // ── Row 2: Fixed Subject Title ────────────────────────
          SizedBox(
            height: 45 * scale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: subjects.isNotEmpty
                      ? () {
                          final targetIndex = currentIndex > 0
                              ? currentIndex - 1
                              : subjects.length - 1;
                          context.pushReplacement(
                              '/worksheets-list/${subjects[targetIndex].subjectId}');
                        }
                      : null,
                  child: Image.asset(
                    '$assetPath/Group 39.png',
                    width: 32 * scale,
                  ),
                ),
                SizedBox(width: 5 * scale),
                Flexible(
                  child: Center(
                    child: isAcademic
                        ? Image.asset(
                            '$assetPath/Academic Math.png',
                            height: 22 * scale,
                            fit: BoxFit.contain,
                          )
                        : assetPath.toLowerCase().contains('logical reasoning')
                            ? Image.asset(
                                '$assetPath/Logical Reasoning-1.png',
                                height: 22 * scale,
                                fit: BoxFit.contain,
                              )
                            : assetPath.toLowerCase().contains('mental math')
                                ? Image.asset(
                                    '$assetPath/Mental Math-1.png',
                                    height: 22 * scale,
                                    fit: BoxFit.contain,
                                  )
                                : assetPath.toLowerCase().contains('olympiad path')
                                    ? Image.asset(
                                        '$assetPath/Olympiad Math-1.png',
                                        height: 22 * scale,
                                        fit: BoxFit.contain,
                                      )
                                    : Text(
                                        subjectName.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 16 * scale,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                  ),
                ),
                SizedBox(width: 5 * scale),
                GestureDetector(
                  onTap: subjects.isNotEmpty
                      ? () {
                          final targetIndex = currentIndex < subjects.length - 1
                              ? currentIndex + 1
                              : 0;
                          context.pushReplacement(
                              '/worksheets-list/${subjects[targetIndex].subjectId}');
                        }
                      : null,
                  child: Image.asset(
                    '$assetPath/Group 38.png',
                    width: 32 * scale,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildUnlockPremiumButton(double scale, String assetPath) {
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




  Widget _buildMasterArithmeticButton(double scale) {
    return GestureDetector(
      onTap: () => context.push('/games/master-arithmetic'),
      child: Container(
        height: 38 * scale,
        padding: EdgeInsets.symmetric(horizontal: 22 * scale),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Master Arithmetic',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 8 * scale),
            Icon(
              Icons.psychology_outlined,
              color: Colors.white,
              size: 20 * scale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25 * scale),
      child: Container(
        height: 46 * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23 * scale),
          child: TextField(
            onChanged: (v) => ref.read(testListProvider.notifier).setSearchQuery(v),
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.montserrat(
              fontSize: 14 * scale,
              color: const Color(0xFF2D2D2D),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Search topics...',
              hintStyle: GoogleFonts.montserrat(
                color: const Color(0xFFBBBBBB),
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: const Color(0xFF2D2D2D),
                size: 20 * scale,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 12 * scale),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final String subjectId;
  final bool isPremiumUser;
  final double scale;
  final String assetPath;
  final Color themeColor;

  const _TopicCard({
    required this.topic,
    required this.subjectId,
    required this.isPremiumUser,
    required this.scale,
    required this.assetPath,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = topic.status == 'completed';
    final isNotStarted = topic.status == 'not_started';

    final barColor = themeColor;
    final textColor = themeColor;

    return Container(
      margin: EdgeInsets.only(bottom: 24 * scale),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 8 * scale,
            left: 6 * scale,
            right: -6 * scale,
            bottom: -8 * scale,
            child: Image.asset(
              '$assetPath/Rectangle 29.png',
              fit: BoxFit.fill,
            ),
          ),

          Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('$assetPath/Rectangle 28.png'),
                fit: BoxFit.fill,
              ),
              border: Border.all(color: const Color(0xFF2D2D2D), width: 2.2),
              borderRadius: BorderRadius.circular(24 * scale),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        topic.name,
                        style: GoogleFonts.cherryBombOne(
                          fontSize: 20 * scale,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Image.asset(
                      isCompleted
                          ? '$assetPath/Completed.png'
                          : isNotStarted
                              ? '$assetPath/Not Started.png'
                              : '$assetPath/Inprogress.png',
                      height: 12 * scale,
                    ),
                  ],
                ),

                SizedBox(height: 12 * scale),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final progress =
                              (topic.progressPercentage / 100).clamp(
                            0.001,
                            1.0,
                          );

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 8 * scale,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                    width: 1.0,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(4 * scale),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 8 * scale,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius:
                                        BorderRadius.circular(4 * scale),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: (constraints.maxWidth * progress) -
                                    11 * scale,
                                top: -8 * scale,
                                child: Image.asset(
                                  '$assetPath/Isolation_Mode.png',
                                  width: 24 * scale,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 15 * scale),
                    Text(
                      '${topic.progressPercentage.round()}%',
                      style: GoogleFonts.cherryBombOne(
                        fontSize: 18 * scale,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20 * scale),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _buildLevelBadge(context, 1),
                      SizedBox(width: 4 * scale),
                      _buildLevelBadge(context, 2),
                      SizedBox(width: 4 * scale),
                      _buildLevelBadge(context, 3),
                      SizedBox(width: 8 * scale),
                      _buildActionButton(context, assetPath),
                      SizedBox(width: 6 * scale),
                      _buildActivityButton(assetPath),
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

  Widget _buildLevelBadge(BuildContext context, int level) {
    final test = topic.tests.firstWhere(
      (t) => t.level == level,
      orElse: () => topic.tests.first,
    );

    String statusStr = 'Not Started';
    if (test.status == 'completed') {
      statusStr = 'Completed';
    } else if (test.status == 'in_progress') {
      statusStr = 'On progress';
    }

    final String assetPath = 'assets/Quiz Buttons/Quiz $statusStr $level.png';
    final bool isPremiumLocked = topic.isPremium && !isPremiumUser;

    final bool isCompleted = test.status == 'completed';

    return GestureDetector(
      onTap: (isPremiumLocked || isCompleted)
          ? null
          : () => context.go('/quiz/${test.testId}', extra: subjectId),
      child: Image.asset(
        assetPath,
        width: 58 * scale,
        height: 22 * scale,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String assetPath) {
    if (topic.isPremium && !isPremiumUser) {
      return _SharedUnlockPremiumButton(scale: scale, assetPath: assetPath);
    }
    final next = topic.tests.firstWhere(
      (t) => t.status != 'completed',
      orElse: () => topic.tests.last,
    );

    // Olympiad math uses its own start button asset
    final String actionPath = topic.status == 'not_started'
        ? (assetPath.contains('10. Olympiad path')
            ? '$assetPath/OBJECTS-3.png'
            : 'assets/7. Academy Path/start2.png')
        : '$assetPath/OBJECTS-4.png';

    final isTopicCompleted = topic.status == 'completed';

    return GestureDetector(
      onTap: isTopicCompleted
          ? null
          : () => context.go('/quiz/${next.testId}', extra: subjectId),
      child: Image.asset(
        actionPath,
        height: 34 * scale,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildActivityButton(String assetPath) => Image.asset(
        '$assetPath/OBJECTS-1.png',
        height: 34 * scale,
        fit: BoxFit.contain,
      );
}

class _SharedUnlockPremiumButton extends StatelessWidget {
  final double scale;
  final String assetPath;

  const _SharedUnlockPremiumButton({
    required this.scale,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Quiz Buttons/Premium Button.png',
      height: 38 * scale,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: 10 * scale, vertical: 4 * scale),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 10),
            const SizedBox(width: 4),
            Text(
              'UNLOCK',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 10 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
