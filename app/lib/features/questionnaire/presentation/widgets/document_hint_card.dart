import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:app/core/theme/app_tokens.dart';

/// The optional "you don't have to type this" nudge shown under a
/// document-friendly question. Strictly a suggestion: it never blocks the
/// composer underneath, and dismissing it (or ignoring it and just
/// answering) is always frictionless - there is no "are you sure" here.
class DocumentHintCard extends StatelessWidget {
  const DocumentHintCard({super.key, required this.onUpload, required this.onDismiss});

  final VoidCallback onUpload;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Insets.x16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.description_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: Insets.x8),
              Expanded(
                child: Text('Можно не вводить вручную', style: theme.textTheme.titleSmall),
              ),
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(Insets.x4),
                  child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.x4),
          Padding(
            padding: const EdgeInsets.only(left: (Insets.x24 + Insets.x4)),
            child: Text(
              'Если удобнее, загрузите фотографию документа — я сам заполню эти данные автоматически.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ),
          const SizedBox(height: Insets.x12),
          Padding(
            padding: const EdgeInsets.only(left: (Insets.x24 + Insets.x4)),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Загрузить документ'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.x8),
          Padding(
            padding: const EdgeInsets.only(left: (Insets.x24 + Insets.x4)),
            child: Text(
              'Или просто ответьте голосом или напишите вручную.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut).slideY(begin: 0.06, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}
