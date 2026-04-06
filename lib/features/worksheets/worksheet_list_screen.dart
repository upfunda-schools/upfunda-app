import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/topics_model.dart';
import '../../providers/test_list_provider.dart';
import '../../providers/worksheet_provider.dart';
import '../../shared/widgets/loader_widget.dart';
import '../../shared/widgets/progress_bar.dart';

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
    Future.microtask(
      () => ref.read(testListProvider.notifier).loadTopics(widget.subjectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testListProvider);
    final isPremiumUser =
        ref.watch(worksheetProvider).data?.isPremiumUser ?? false;

    return Scaffold(
      backgroundColor: AppColors.worksheetListBg,
      body: SafeArea(
        child: state.isLoading && state.data == null
            ? const LoaderWidget(message: 'Loading topics...')
            : Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.go('/worksheets'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.data?.subjectName ?? 'Topics',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      onChanged: (v) =>
                          ref.read(testListProvider.notifier).setSearchQuery(v),
                      decoration: InputDecoration(
                        hintText: 'Search topics...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Teacher gated message
                  if (state.data?.teacherGated == true)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.review),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Worksheets Not Available Yet. Your teacher has not assigned worksheets.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Topics count
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${state.filteredTopics.length} Topics',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Topic list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: state.filteredTopics.length,
                      itemBuilder: (context, index) {
                        final topic = state.filteredTopics[index];
                        return _TopicCard(
                          topic: topic,
                          subjectId: widget.subjectId,
                          isPremiumUser: isPremiumUser,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final String subjectId;
  final bool isPremiumUser;
  const _TopicCard({
    required this.topic,
    required this.subjectId,
    required this.isPremiumUser,
  });

  Color get _statusColor {
    switch (topic.status) {
      case 'completed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.review;
      default:
        return AppColors.grey400;
    }
  }

  String get _statusLabel {
    switch (topic.status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Not Started';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic.name,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (topic.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4B500).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPremiumUser ? Icons.star : Icons.lock,
                        size: 12,
                        color: const Color(0xFFE4B500),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE4B500),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _statusLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(value: topic.progressPercentage, height: 6),
          const SizedBox(height: 12),

          // Test level buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topic.tests.map((test) {
              final bool locked = topic.isPremium && !isPremiumUser;

              if (locked) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.grey400, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 14, color: AppColors.grey400),
                      SizedBox(width: 4),
                      Text(
                        'Premium Only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final Color buttonColor;
              final String buttonLabel;
              final IconData buttonIcon;
              switch (test.status) {
                case 'completed':
                  buttonColor = AppColors.success;
                  buttonLabel = 'Done';
                  buttonIcon = Icons.check_circle;
                  break;
                case 'in_progress':
                case 'paused':
                  buttonColor = AppColors.review;
                  buttonLabel = 'Continue';
                  buttonIcon = Icons.play_circle_outline;
                  break;
                default:
                  buttonColor = AppColors.primary;
                  buttonLabel = 'Level ${test.level}';
                  buttonIcon = Icons.play_arrow;
              }
              return GestureDetector(
                onTap: () => context.go('/quiz/${test.testId}', extra: subjectId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: buttonColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: buttonColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(buttonIcon, size: 14, color: buttonColor),
                      const SizedBox(width: 4),
                      Text(
                        buttonLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: buttonColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
