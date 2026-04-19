import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/profile_storage.dart';
import '../../data/models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/worksheet_provider.dart';

class SelectProfileScreen extends ConsumerStatefulWidget {
  const SelectProfileScreen({super.key});

  @override
  ConsumerState<SelectProfileScreen> createState() =>
      _SelectProfileScreenState();
}

class _SelectProfileScreenState extends ConsumerState<SelectProfileScreen> {
  List<StudentProfile> _profiles = [];
  bool _isLoading = true;
  String? _error;
  String? _selectingId;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final api = ref.read(apiServiceProvider);
      final profiles = await api.getStudentProfiles();
      if (mounted) {
        if (profiles.isEmpty) {
          context.go('/add-student');
          return;
        }
        setState(() {
          _profiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // If profile fetch fails (e.g. user record not found in DB yet), 
        // redirect to add-student to create the first profile.
        context.go('/add-student');
      }
    }
  }

  Future<void> _selectProfile(StudentProfile profile) async {
    setState(() => _selectingId = profile.profileId);
    ProfileStorage.profileId = profile.profileId;
    ref.read(authProvider.notifier).completeProfileSelection();
    ref.read(userProvider.notifier).clear();
    ref.read(worksheetProvider.notifier).clear();
    try {
      await Future.wait([
        ref.read(userProvider.notifier).loadHome(),
        ref.read(userProvider.notifier).loadProfile(),
      ]);
    } catch (_) {
      // If refresh fails, still continue and let the home screen retry.
    }
    if (mounted) context.go('/student-home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Select Your Profile',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Multiple profiles are linked to this account. Choose the grade you want to continue with.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.incorrect,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                              _loadProfiles();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_profiles.isEmpty)
                    Center(
                      child: Text(
                        'No profiles found.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _profiles
                          .map((profile) => _ProfileCard(
                                profile: profile,
                                isSelecting: _selectingId == profile.profileId,
                                disabled: _selectingId != null,
                                onTap: () => _selectProfile(profile),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StudentProfile profile;
  final bool isSelecting;
  final bool disabled;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.isSelecting,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (profile.classGrade.isNotEmpty) 'Grade ${profile.classGrade}',
      if (profile.sectionName != null && profile.sectionName!.isNotEmpty)
        'Section ${profile.sectionName}',
      profile.schoolName,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a3d),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha(31),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withAlpha(102),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
