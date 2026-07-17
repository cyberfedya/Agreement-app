import 'package:flutter/material.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/animation/entrance.dart';

class DocumentHintCard extends StatelessWidget {
  const DocumentHintCard({super.key, required this.onUpload, required this.onDismiss});
  final VoidCallback onUpload;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
                child: Text(l10n.questionnaireUploadNotRequired, style: theme.textTheme.titleSmall),
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
              l10n.questionnaireUploadNudgeBody,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ),
          const SizedBox(height: Insets.x12),
          Padding(
            padding: const EdgeInsets.only(left: (Insets.x24 + Insets.x4)),
            child: Row(
              children: [
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(l10n.questionnaireUploadDocument, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x8),
                    ),
                  ),
                ),
              ],
             ),
          ),
          const SizedBox(height: Insets.x8),
          Padding(
            padding: const EdgeInsets.only(left: (Insets.x24 + Insets.x4)),
            child: Text(
              l10n.questionnaireUploadNudgeAlt,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    ).animateEntrance();
  }
}