import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/deal/domain/deal_history.dart';
import 'package:app/l10n/app_localizations.dart';

class DealStatusBadge extends StatelessWidget {
  const DealStatusBadge({super.key, required this.status});

  final DealHistoryStatus status;

  static (Color, Color) _colors(ColorScheme scheme, DealHistoryStatus status) => switch (status) {
    DealHistoryStatus.draft => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
    DealHistoryStatus.waitingSecondParty => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    DealHistoryStatus.waitingYourSignature => (scheme.primaryContainer, scheme.onPrimaryContainer),
    DealHistoryStatus.signed => (Colors.green.withValues(alpha: 0.16), Colors.green.shade800),
    DealHistoryStatus.cancelled => (scheme.errorContainer, scheme.onErrorContainer),
  };

  static String _label(AppLocalizations l10n, DealHistoryStatus status) => switch (status) {
    DealHistoryStatus.draft => l10n.historyStatusDraft,
    DealHistoryStatus.waitingSecondParty => l10n.historyStatusWaitingSecondParty,
    DealHistoryStatus.waitingYourSignature => l10n.historyStatusWaitingYourSignature,
    DealHistoryStatus.signed => l10n.historyStatusSigned,
    DealHistoryStatus.cancelled => l10n.historyStatusCancelled,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final (background, foreground) = _colors(theme.colorScheme, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        _label(l10n, status),
        style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
