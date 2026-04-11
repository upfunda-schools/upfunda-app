import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/quiz_model.dart';

class QuestionCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.quizPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Question $questionNumber of $totalQuestions',
              style: const TextStyle(
                color: AppColors.quizPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
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
                    lineHeight: LineHeight(1.6),
                    color: AppColors.grey800,
                    fontWeight: FontWeight.w700,
                    margin: Margins.all(0),
                    padding: HtmlPaddings.all(0),
                  ),
                  'p': Style(
                    fontSize: FontSize(16),
                    lineHeight: LineHeight(1.6),
                    color: AppColors.grey800,
                    fontWeight: FontWeight.w700,
                    margin: Margins.only(bottom: 8),
                  ),
                  'strong': Style(
                    fontWeight: FontWeight.w700,
                  ),
                },
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isImageOnly(String html) {
    if (html.isEmpty) return false;
    // Check if there's any visible text after stripping ALL HTML tags
    final cleanText = html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', '').trim();
    return cleanText.isEmpty && html.contains('<img');
  }

  String _sanitizeHtml(String html) {
    if (html.isEmpty) return html;
    
    // 1. List of STRUCTURAL tags to remove completely (keeping their content)
    const stripTags = [
      'table', 'tr', 'td', 'th', 'thead', 'tbody', 'tfoot', 'colgroup', 'col',
      'div', 'span', 'section', 'article', 'header', 'footer'
    ];
    
    String output = html;
    for (final tag in stripTags) {
      output = output.replaceAll(RegExp('<$tag[^>]*>', caseSensitive: false), ' ');
      output = output.replaceAll(RegExp('</$tag>', caseSensitive: false), ' ');
    }

    // 2. List of formatting tags to PRESERVE
    const keepTags = ['p', 'b', 'i', 'img', 'br', 'strong', 'em', 'sub', 'sup', 'u'];
    
    // 3. Escape '<' if it's NOT part of a 'keep' tag (handles math symbols like <ABC)
    final tagPattern = [...keepTags, ...keepTags.map((t) => '/$t')].join('|');
    final regex = RegExp('<(?!(?:$tagPattern)(?:\\s|>))', caseSensitive: false);
    
    output = output.replaceAll(regex, '&lt;');
    
    return output.trim();
  }

  Widget _buildDirectImage(String src) {
    if (src.startsWith('data:')) {
      try {
        final base64Str = src.split(',').last;
        final bytes = base64Decode(base64Str);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Image.network(
        src,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
