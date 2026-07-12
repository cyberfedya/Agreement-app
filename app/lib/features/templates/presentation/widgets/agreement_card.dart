import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/features/templates/presentation/widgets/domain_visuals.dart';
import 'package:app/shared/extensions/string_extensions.dart';

/// List card for one agreement template: leading category glyph, title,
/// description, and a category tag.
class AgreementCard extends StatelessWidget {
  const AgreementCard({super.key, required this.template, required this.onTap});

  final TemplateSummary template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.x16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: templateHeroTag(template.key),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: Corners.smRadius,
                  ),
                  child: Icon(iconForDomain(template.domain), size: 22, color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: Insets.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Insets.x4),
                    Text(
                      template.description,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Insets.x8),
                    Text(
                      template.domain.asCategoryLabel,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.x8),
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact card used in the Home "Explore" horizontal rail.
class AgreementRailCard extends StatelessWidget {
  const AgreementRailCard({super.key, required this.template, required this.onTap});

  final TemplateSummary template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Insets.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(height: Insets.x12),
                Expanded(
                  child: Text(
                    template.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: Insets.x8),
                Text(
                  template.domain.asCategoryLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
