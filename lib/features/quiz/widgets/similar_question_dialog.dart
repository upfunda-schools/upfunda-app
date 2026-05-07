import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/quiz_model.dart';

class SimilarQuestionDialog extends StatefulWidget {
  final Question question;
  final VoidCallback onContinue;

  const SimilarQuestionDialog({
    super.key,
    required this.question,
    required this.onContinue,
  });

  @override
  State<SimilarQuestionDialog> createState() => _SimilarQuestionDialogState();
}

class _SimilarQuestionDialogState extends State<SimilarQuestionDialog> {
  String? selectedOptionId;
  bool isChecked = false;
  bool? isCorrect;

  void _handleCheck() {
    if (selectedOptionId == null) return;

    final correctOptionId = widget.question.solution?.correctOptionId;
    setState(() {
      isChecked = true;
      isCorrect = selectedOptionId == correctOptionId;
    });
  }

  void _handleTryAgain() {
    setState(() {
      selectedOptionId = null;
      isChecked = false;
      isCorrect = null;
    });
  }

  String _stripHtml(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/quiz_similar/Rectangle 55.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/quiz_similar/close_icon.png',
                      width: 20,
                    ),
                  ),
                ),
              ),

              // Title
              Image.asset(
                'assets/quiz_similar/challenge_title.png',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              // Question Box
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Purple Shape (Rectangle 75) - Bold full-height accent
                  Positioned(
                    left: -8,
                    top: 0,
                    bottom: 0,
                    width: 40, // Significantly increased width
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        bottomLeft: Radius.circular(32),
                      ),
                      child: Image.asset(
                        'assets/quiz_similar/Rectangle 75.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  // White Shape (Rectangle 74) - Main Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              'assets/quiz_similar/Rectangle 74.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
                          child: Text(
                            _stripHtml(widget.question.text),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Options
              if (widget.question.options.isNotEmpty)
                ...widget.question.options.asMap().entries.map((entry) {
                  return _buildOption(entry.value, entry.key);
                })
              else
                const Text("No options available"),

              const SizedBox(height: 24),

              // Feedback Box
              if (isChecked) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isCorrect!
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCorrect!
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFFEDD5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCorrect! ? Icons.check_circle : Icons.cancel,
                            color: isCorrect!
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF97316),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCorrect! ? 'Excellent Work' : 'Keep Practicing!',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isCorrect!
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isCorrect!
                            ? 'You got it right! Great understanding of the concept'
                            : "Not quite right, but that's how we learn. Try again!",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isCorrect!
                              ? const Color(0xFF15803D)
                              : const Color(0xFFC2410C),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              if (!isChecked)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: selectedOptionId != null ? _handleCheck : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Check Answer',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _handleTryAgain,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9333EA),
                            side: const BorderSide(
                              color: Color(0xFF9333EA),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.refresh, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Try again',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onContinue();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9333EA),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_forward, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Continue Quiz',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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

              const SizedBox(height: 16),

              // Footer
              Image.asset(
                'assets/quiz_similar/practice_footer.png',
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(QuestionOption option, int index) {
    final isSelected = selectedOptionId == option.optionId;
    final isCorrectOption =
        option.optionId == widget.question.solution?.correctOptionId;

    return GestureDetector(
      onTap: isChecked
          ? null
          : () => setState(() => selectedOptionId = option.optionId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isChecked
              ? (isCorrectOption
                    ? const Color(0xFFDCFCE7)
                    : (isSelected ? const Color(0xFFFEE2E2) : Colors.grey[50]))
              : (isSelected ? const Color(0xFFF3E8FF) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isChecked
                ? (isCorrectOption
                      ? const Color(0xFF22C55E)
                      : (isSelected
                            ? const Color(0xFFEF4444)
                            : Colors.grey[200]!))
                : (isSelected ? const Color(0xFF9333EA) : Colors.grey[200]!),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

        child: Row(
          children: [
            // Radio Icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isChecked
                      ? (isCorrectOption
                            ? const Color(0xFF22C55E)
                            : (isSelected
                                  ? const Color(0xFFEF4444)
                                  : Colors.grey[400]!))
                      : (isSelected
                            ? const Color(0xFF9333EA)
                            : Colors.grey[400]!),
                  width: 2,
                ),
              ),
              child: isSelected || (isChecked && isCorrectOption)
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isChecked
                              ? (isCorrectOption
                                    ? const Color(0xFF22C55E)
                                    : (isSelected
                                          ? const Color(0xFFEF4444)
                                          : Colors.transparent))
                              : const Color(0xFF9333EA),
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _stripHtml(option.text),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
            ),

            if (isChecked && (isSelected || isCorrectOption))
              Icon(
                isCorrectOption
                    ? Icons.check_circle_outline
                    : Icons.highlight_off,
                color: isCorrectOption
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
