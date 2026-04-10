import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/user_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/submit_model.dart';

class LeaderBoardScreen extends ConsumerStatefulWidget {
  const LeaderBoardScreen({super.key});

  @override
  ConsumerState<LeaderBoardScreen> createState() => _LeaderBoardScreenState();
}

class _LeaderBoardScreenState extends ConsumerState<LeaderBoardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(leaderboardProvider.notifier).loadLeaderboard());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final userState = ref.watch(userProvider);
    final profile = userState.profile;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1133),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Leaderboard',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${profile.upPoints} UP',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA58AFF)))
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'Oops! Something went wrong',
                        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 18),
                      ),
                      TextButton(
                        onPressed: () => ref.read(leaderboardProvider.notifier).loadLeaderboard(),
                        child: const Text('Try Again', style: TextStyle(color: Color(0xFFA58AFF))),
                      ),
                    ],
                  ),
                )
              : state.entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined, color: Colors.white.withValues(alpha: 0.3), size: 100),
                          const SizedBox(height: 24),
                          Text(
                            'Let\'s Go Champ!',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start your quiz and grab your spot!',
                            style: GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(leaderboardProvider.notifier).loadLeaderboard(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildBadges(profile),
                            const SizedBox(height: 24),
                            _buildPodium(state.entries),
                            const SizedBox(height: 32),
                            _buildList(state.entries),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildBadges(UserProfile? profile) {
    if (profile == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (profile.schoolName != null)
          _Badge(label: profile.schoolName!, color: Colors.blue.withValues(alpha: 0.5)),
        if (profile.className != null)
          _Badge(label: 'Class ${profile.className}', color: Colors.purple.withValues(alpha: 0.5)),
        if (profile.sectionName != null)
          _Badge(label: 'Section ${profile.sectionName}', color: Colors.white.withValues(alpha: 0.1)),
      ],
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    final topThree = entries.take(3).toList();
    if (topThree.isEmpty) return const SizedBox.shrink();

    // Reorder for display: 2nd, 1st, 3rd
    final displayOrder = <dynamic>[];
    if (topThree.length >= 2) displayOrder.add(topThree[1]);
    displayOrder.add(topThree[0]);
    if (topThree.length >= 3) displayOrder.add(topThree[2]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (topThree.length >= 2)
            Expanded(
              child: _PodiumMember(
                entry: topThree[1],
                rank: 2,
                height: 100,
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                avatarSize: 60,
              ),
            ),
          // 1st Place
          Expanded(
            child: _PodiumMember(
              entry: topThree[0],
              rank: 1,
              height: 140,
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.7),
              avatarSize: 80,
              hasCrown: true,
            ),
          ),
          // 3rd Place
          if (topThree.length >= 3)
            Expanded(
              child: _PodiumMember(
                entry: topThree[2],
                rank: 3,
                height: 80,
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                avatarSize: 55,
              ),
            )
          else if (topThree.length < 3)
             const Spacer(),
        ],
      ),
    );
  }

  Widget _buildList(List<LeaderboardEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: List.generate(
          entries.length > 10 ? 10 : entries.length,
          (index) {
            final entry = entries[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: index == (entries.length > 10 ? 9 : entries.length - 1)
                    ? null
                    : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                color: index % 2 == 0 ? Colors.white.withValues(alpha: 0.02) : Colors.transparent,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${entry.rank}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Avatar(avatar: entry.avatar, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFCAA2FF), Color(0xFFFFB5E8)],
                    ).createShader(bounds),
                    child: Text(
                      '${entry.score.round()}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PodiumMember extends StatelessWidget {
  final dynamic entry;
  final int rank;
  final double height;
  final Color color;
  final double avatarSize;
  final bool hasCrown;

  const _PodiumMember({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    required this.avatarSize,
    this.hasCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            _Avatar(
              avatar: entry.avatar,
              size: avatarSize,
              borderColor: rank == 1
                  ? Colors.yellow
                  : rank == 2
                      ? Colors.grey
                      : Colors.orange,
            ),
            if (hasCrown)
              const Positioned(
                top: -25,
                child: Icon(Icons.emoji_events, color: Colors.yellow, size: 30),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            entry.name,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatar;
  final double size;
  final Color? borderColor;

  const _Avatar({this.avatar, required this.size, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        color: Colors.grey[800],
      ),
      child: const Icon(Icons.person, color: Colors.white54),
    );
  }
}
