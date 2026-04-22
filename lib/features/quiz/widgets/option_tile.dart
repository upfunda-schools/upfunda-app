import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class OptionTile extends StatelessWidget {
  final String optionId;
  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final bool isHidden;
  final String? correctOptionId;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.optionId,
    required this.text,
    required this.index,
    this.isSelected = false,
    this.isCorrect = false,
    this.showResult = false,
    this.isHidden = false,
    this.correctOptionId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isHidden) return const SizedBox.shrink();

    const assetBadges = [
      'assets/images/quiz/noto_green-circle.png',
      'assets/images/quiz/noto_green-circle-2.png',
      'assets/images/quiz/noto_green-circle-1.png',
      'assets/images/quiz/noto_green-circle-3.png',
    ];

    return GestureDetector(
      onTap: isHidden || showResult ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Letter badge from asset
            if (index < assetBadges.length)
              Image.asset(assetBadges[index], height: 32)
            else
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle),
                child: Center(child: Text('${index + 1}')),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Html(
                data: text,
                extensions: [
                  TagExtension(
                    tagsToExtend: {"img"},
                    builder: (extensionContext) {
                      final src = extensionContext.attributes["src"] ?? "";
                      if (src.isEmpty) return const SizedBox.shrink();
                      if (src.startsWith('data:')) {
                        try {
                          final base64Str = src.split(',').last;
                          final bytes = base64Decode(base64Str);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          );
                        } catch (_) {
                          return const SizedBox.shrink();
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Image.network(
                          src,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
                ],
                style: {
                  'body': Style(
                    fontSize: FontSize(18),
                    color: const Color(0xFF2D327C),
                    fontWeight: FontWeight.bold,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                },
              ),
            ),
            if (showResult && optionId == correctOptionId)
              const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 24),
            if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 24),
          ],
        ),
      ),
    );
  }
}
