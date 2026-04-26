import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/loader_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userProvider.notifier).loadProfile();
      ref.read(authProvider.notifier).fetchProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.profileBgStart, AppColors.profileBgEnd],
          ),
        ),
        child: SafeArea(
          child: state.isLoading
              ? const LoaderWidget(message: 'Loading profile...')
              : state.profile == null
                  ? const Center(child: Text('No profile data'))
                  : _buildProfile(state),
        ),
      ),
    );
  }

  Widget _buildProfile(UserState state) {
    final profile = state.profile!;
    final authState = ref.watch(authProvider);
    final profiles = authState.profiles ?? [];

    final profilesForThisStudent = profiles
        .where((p) =>
            p.name.trim().toLowerCase() == profile.name.trim().toLowerCase())
        .toList();
    final canSwitchGrade = profilesForThisStudent.length > 1;

    final uniqueStudentNames =
        profiles.map((p) => p.name.trim().toLowerCase()).toSet();
    final canSwitchStudent = uniqueStudentNames.length > 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/student-home'),
              ),
              const Spacer(),
              if (profile.isPremiumUser)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE4B500), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    // Handle subscription
                  },
                  child: Image.asset(
                    'assets/Updated 2/Premium Main.png',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Profile card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4B500), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // UP Points badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${profile.upPoints} UP',
                        style: GoogleFonts.montserrat(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar circle
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    profile.initials,
                    style: GoogleFonts.montserrat(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  profile.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(
                    color: AppColors.grey600,
                    fontSize: 14,
                  ),
                ),
                if (profile.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.phone!,
                    style: const TextStyle(
                      color: AppColors.grey600,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Info pills
                _InfoPill(
                  icon: Icons.school_outlined,
                  label: (profile.className != null && profile.className!.isNotEmpty)
                      ? profile.className!
                      : 'N/A',
                ),
                const SizedBox(height: 10),
                _InfoPill(
                  icon: Icons.account_balance_outlined,
                  label: (profile.schoolName != null && profile.schoolName!.isNotEmpty)
                      ? profile.schoolName!
                      : 'N/A',
                ),
                const SizedBox(height: 10),
                _InfoPill(
                  icon: Icons.public_outlined,
                  label: (profile.country != null && profile.country!.isNotEmpty)
                      ? profile.country!
                      : 'N/A',
                ),
                const SizedBox(height: 28),

                // Profile switching buttons
                if (state.profile?.role == 'student') ...[
                  if (canSwitchGrade || canSwitchStudent) ...[
                    Row(
                      children: [
                        if (canSwitchGrade)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push(
                                '/select-profile?filterName=${profile.name}',
                              ),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6C5CE7),
                                      Color(0xFF8B5CF6)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C5CE7)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.school_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Switch Grade',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (canSwitchGrade && canSwitchStudent)
                          const SizedBox(width: 12),
                        if (canSwitchStudent)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/select-profile'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF1659C),
                                      Color(0xFFEC4899)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF1659C)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_alt_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Switch Student',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // Change password button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await ref
                          .read(authProvider.notifier)
                          .resetPassword(email: profile.email);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Password reset email sent to ${profile.email}'
                                  : ref.read(authProvider).error ??
                                      'Reset failed',
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4B500),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Change Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
