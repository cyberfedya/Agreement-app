import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/l10n/app_localizations.dart';

/// Slim progress header for multi-step flows: "3 of 15" plus an animated bar.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.current, required this.total});

  /// 1-based index of the current step.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.progressStepOf(current, total),
          style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: Insets.x8),
        TweenAnimationBuilder<double>(
          duration: Motion.slow,
          curve: Motion.curve,
          tween: Tween(end: total == 0 ? 0 : current / total),
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
            ),
          ),
        ),
      ],
    );
  }
}
