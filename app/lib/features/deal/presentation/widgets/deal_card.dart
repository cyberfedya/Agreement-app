import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/deal/domain/deal_history.dart';
import 'package:app/features/deal/presentation/widgets/deal_status_badge.dart';
import 'package:app/shared/extensions/string_extensions.dart';
import 'package:app/shared/widgets/pressable_scale.dart';
import 'package:app/l10n/app_localizations.dart';

/// Minimalist list row for one deal in Deal History: title, category, date
/// and a status badge — deliberately no cover image or dense metadata.
class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.deal, required this.onTap});

  final DealSummary deal;
  final VoidCallback onTap;

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}.${two(local.month)}.${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return PressableScale(
      child: Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: Corners.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: Corners.mdRadius,
        child: Padding(
          padding: const EdgeInsets.all(Insets.x16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.templateTitle,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Insets.x4),
                    Text(
                      deal.templateDomain.isEmpty
                          ? _formatDate(deal.createdAt)
                          : '${deal.templateDomain.categoryLabel(l10n)} · ${_formatDate(deal.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.x12),
              DealStatusBadge(status: deal.status),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
