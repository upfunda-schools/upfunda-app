import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/worksheet_provider.dart';
import '../../shared/widgets/loader_widget.dart';
import '../../shared/widgets/progress_bar.dart';
import '../../shared/widgets/skeleton_loader.dart';

class WorksheetsScreen extends ConsumerStatefulWidget {
  const WorksheetsScreen({super.key});

  @override
  ConsumerState<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends ConsumerState<WorksheetsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(worksheetProvider.notifier).loadSubjects());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(worksheetProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: state.isLoading && state.data == null
            ? const LoaderWidget(message: 'Loading worksheets...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.go('/student-home'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Worksheets',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
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
                              Icon(Icons.lock_open, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Unlock Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stats banner
                    if (state.data != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                icon: Icons.analytics_outlined,
                                label: 'Overall Accuracy',
                                value: '${state.data!.overallAccuracy.round()}%',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.grey400,
                            ),
                            Expanded(
                              child: _StatItem(
                                icon: Icons.pending_actions_outlined,
                                label: 'Pending',
                                value: '${state.data!.pendingWorksheets}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Subtitle
                    Text(
                      'Select a category and solve the worksheets',
                      style: TextStyle(
                        color: AppColors.grey600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subject grid
                    if (state.isLoading) ...[
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(4, (_) => const SkeletonCard()),
                      ),
                    ] else if (state.data != null) ...[
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.data!.subjects.length,
                        itemBuilder: (context, index) {
                          final subject = state.data!.subjects[index];
                          return _SubjectCard(
                            name: subject.name,
                            solved: subject.solved,
                            open: subject.open,
                            completedPercentage: subject.completedPercentage,
                            onTap: () => context.go(
                              '/worksheets-list/${subject.subjectId}',
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String name;
  final int solved;
  final int open;
  final double completedPercentage;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.name,
    required this.solved,
    required this.open,
    required this.completedPercentage,
    required this.onTap,
  });

  IconData get _subjectIcon {
    switch (name.toLowerCase()) {
      case 'academic math':
        return Icons.school;
      case 'mental math':
        return Icons.psychology;
      case 'olympiad math':
        return Icons.emoji_events;
      case 'logical reasoning':
        return Icons.lightbulb;
      default:
        return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_subjectIcon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            ProgressBar(value: completedPercentage),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mastered: $solved',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'To Do: $open',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
