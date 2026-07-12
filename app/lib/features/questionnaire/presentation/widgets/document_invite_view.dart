import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/domain/interview_step.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/widgets/primary_button.dart';

/// The document-first moment: before any typing, the assistant offers to
/// read a document and fill the agreement itself. One clear promise, one
/// primary action (camera), gallery as a peer, skip as a quiet text link.
class DocumentInviteView extends StatelessWidget {
  const DocumentInviteView({
    super.key,
    required this.suggestion,
    required this.onCamera,
    required this.onGallery,
    required this.onSkip,
  });

  final DocumentSuggestion suggestion;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x24, Insets.x24, Insets.x32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Insets.x24),
          // Layered soft circles instead of a bare icon - depth without
          // shadows.
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              ),
              child: Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primaryContainer),
                  child: Icon(Icons.document_scanner_outlined, size: 38, color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ),
          ).animateEntrance(),
          const SizedBox(height: Insets.x32),
          Text(
            suggestion.title,
            style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
            textAlign: TextAlign.center,
          ).animateEntranceStaggered(1),
          const SizedBox(height: Insets.x12),
          Text(
            suggestion.description,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ).animateEntranceStaggered(2),
          if (suggestion.matchedFieldCount > 2) ...[
            const SizedBox(height: Insets.x16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Insets.x12, vertical: Insets.x8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: Corners.x2lRadius,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: Insets.x4 + 2),
                    Text(
                      'Заполню около ${suggestion.matchedFieldCount} полей автоматически',
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ).animateEntranceStaggered(3),
          ],
          const SizedBox(height: Insets.x40),
          PrimaryButton(label: 'Сфотографировать', icon: Icons.photo_camera_outlined, onPressed: onCamera)
              .animateEntranceStaggered(4),
          const SizedBox(height: Insets.x12),
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('Выбрать из галереи'),
          ).animateEntranceStaggered(5),
          const SizedBox(height: Insets.x8),
          TextButton(onPressed: onSkip, child: const Text('Продолжить без документа')).animateEntranceStaggered(6),
        ],
      ),
    );
  }
}
