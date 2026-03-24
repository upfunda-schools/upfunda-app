import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/challenge_room_provider.dart';

class ChallengeRoomLobbyScreen extends ConsumerStatefulWidget {
  const ChallengeRoomLobbyScreen({super.key});

  @override
  ConsumerState<ChallengeRoomLobbyScreen> createState() =>
      _ChallengeRoomLobbyScreenState();
}

class _ChallengeRoomLobbyScreenState
    extends ConsumerState<ChallengeRoomLobbyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeRoomProvider);

    // Navigate to quiz when room becomes active
    ref.listen<ChallengeRoomState>(challengeRoomProvider, (prev, next) {
      if (prev?.status != 'active' && next.status == 'active' &&
          next.questions.isNotEmpty) {
        context.pushReplacement('/challenge/room/quiz');
      }
      // If host: when opponent joins (result has 2 players in waiting), allow start
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(challengeRoomProvider.notifier).reset();
                      context.pop();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Text(
                    'Challenge a Friend',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Create Room'),
                Tab(text: 'Join Room'),
              ],
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.grey600,
              indicatorColor: AppColors.accent,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CreateTab(state: state),
                  _JoinTab(
                    state: state,
                    codeController: _codeController,
                    joining: _joining,
                    onJoin: _joinRoom,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _joining = true);
    await ref.read(challengeRoomProvider.notifier).joinRoom(code);
    if (mounted) setState(() => _joining = false);
  }
}

class _CreateTab extends ConsumerWidget {
  final ChallengeRoomState state;

  const _CreateTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRoom = state.roomId != null;
    final isLoading = state.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 48, color: AppColors.accent),
                const SizedBox(height: 16),
                if (!hasRoom && !isLoading) ...[
                  Text(
                    'Create a challenge room and share the code with your friend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.grey600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => ref
                          .read(challengeRoomProvider.notifier)
                          .createRoom(),
                      child: const Text('Create Room',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ] else if (isLoading) ...[
                  const CircularProgressIndicator(
                      color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text('Creating room...',
                      style: TextStyle(color: AppColors.grey600)),
                ] else ...[
                  Text(
                    'Room Code',
                    style: TextStyle(
                        color: AppColors.grey600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: state.roomCode ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Code copied!'),
                            duration: Duration(seconds: 1)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.accent.withValues(
                                alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.roomCode ?? '',
                            style: GoogleFonts.montserrat(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.copy_rounded,
                              color: AppColors.accent, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state.status == 'waiting') ...[
                    const CircularProgressIndicator(
                        color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Waiting for opponent to join...',
                      style: TextStyle(
                          color: AppColors.grey600, fontSize: 13),
                    ),
                  ] else if (state.status == 'active' ||
                      (state.result?.players.length ?? 0) >= 2) ...[
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.correct, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Opponent joined!',
                      style: TextStyle(
                          color: AppColors.correct,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.correct,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => ref
                            .read(challengeRoomProvider.notifier)
                            .startRoom(),
                        child: const Text('Start Challenge!',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(state.error!,
                        style: const TextStyle(
                            color: AppColors.incorrect, fontSize: 12),
                        textAlign: TextAlign.center),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinTab extends StatelessWidget {
  final ChallengeRoomState state;
  final TextEditingController codeController;
  final bool joining;
  final VoidCallback onJoin;

  const _JoinTab({
    required this.state,
    required this.codeController,
    required this.joining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final hasJoined = state.roomId != null && state.roomCode == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.login_rounded,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                if (!hasJoined) ...[
                  Text(
                    'Enter the 6-character room code from your friend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.grey600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4),
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'ABC123',
                      hintStyle: GoogleFonts.montserrat(
                          color: AppColors.grey400,
                          fontSize: 24,
                          letterSpacing: 4),
                      counterText: '',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.grey200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state.error != null) ...[
                    Text(state.error!,
                        style: const TextStyle(
                            color: AppColors.incorrect, fontSize: 12)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: joining ? null : onJoin,
                      child: joining
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text('Join Room',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                    ),
                  ),
                ] else ...[
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.correct, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Joined! Waiting for host to start...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.grey600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                      color: AppColors.primary),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
