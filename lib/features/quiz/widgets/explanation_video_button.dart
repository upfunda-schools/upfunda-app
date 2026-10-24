import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vdo_player/embed.dart';

/// "Watch explanation video", shown only when the question has a video.
///
/// The lookup is by the same `question_id` the quiz API returns: the videos
/// were uploaded against the question bank's ids, so no mapping is needed.
class ExplanationVideoButton extends StatelessWidget {
  final String questionId;

  const ExplanationVideoButton({super.key, required this.questionId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: vdoHasVideo(questionId),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => VdoQuestionVideoScreen(questionId: questionId, title: 'Explanation video'),
              ),
            ),
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: Text(
              'Watch Explanation Video',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B63D4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
          ),
        );
      },
    );
  }
}
