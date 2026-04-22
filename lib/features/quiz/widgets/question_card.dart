import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/quiz_model.dart';
import '../../../providers/quiz_provider.dart';

class QuestionCard extends ConsumerWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(quizMuteProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Color(0xFF6C97F9), size: 28),
              const SizedBox(width: 12),
              Text(
                'Questions $questionNumber/$totalQuestions',
                style: const TextStyle(
                  color: Color(0xFF2D327C),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star, color: Color(0xFF6C97F9), size: 28),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ref.read(quizMuteProvider.notifier).state = !isMuted;
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isMuted ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMuted ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Icon(
                    isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                    color: isMuted ? const Color(0xFFEF4444) : const Color(0xFF4B5563),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question content
          Builder(
            builder: (context) {
              final String rawText = question.text.trim();
              if (rawText.isEmpty) return const SizedBox.shrink();

              // Clean the HTML: Remove structural/layout tags but keep content and <img> tags
              final String sanitizedText = _sanitizeHtml(rawText);

              // If it's effectively an image-only question after cleaning, render directly
              if (_isImageOnly(sanitizedText)) {
                final match = RegExp('src=["\']([^"\']+)["\']').firstMatch(sanitizedText);
                if (match != null) {
                  final src = match.group(1)!;
                  return _buildDirectImage(src);
                }
              }

              return Html(
                data: sanitizedText,
                extensions: [
                  TagExtension(
                    tagsToExtend: {"img"},
                    builder: (extensionContext) {
                      final src = extensionContext.attributes["src"] ?? "";
                      if (src.isEmpty) return const SizedBox.shrink();
                      return _buildDirectImage(src);
                    },
                  ),
                ],
                style: {
                  'body': Style(
                    fontSize: FontSize(16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _sanitizeHtml(String html) {
    // Preserve <img> tags but strip most others that might break the card layout
    String sanitized = html
        .replaceAll(RegExp(r'<p[^>]*>'), '')
        .replaceAll('</p>', '<br/>')
        .replaceAll(RegExp(r'<div[^>]*>'), '')
        .replaceAll('</div>', '<br/>')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
    
    if (sanitized.endsWith('<br/>')) {
      sanitized = sanitized.substring(0, sanitized.length - 5);
    }
    return sanitized;
  }

  bool _isImageOnly(String html) {
    // Remove all whitespace and the img tag itself to see if anything is left
    final stripped = html.replaceAll(RegExp(r'<img[^>]*>'), '').replaceAll(RegExp(r'\s+'), '').trim();
    return stripped.isEmpty && html.contains('<img');
  }

  Widget _buildDirectImage(String src) {
    if (src.startsWith('data:image')) {
      try {
        final base64String = src.split(',').last;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(base64String),
            fit: BoxFit.contain,
          ),
        );
      } catch (_) {
        return const Icon(Icons.broken_image, color: Colors.grey);
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        src,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
