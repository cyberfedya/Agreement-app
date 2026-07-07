import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';

/// Sticky bottom bar for page-level CTAs. Adds a hairline divider and
/// safe-area padding so buttons never collide with system gestures.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x12, Insets.x20, Insets.x16),
          child: CenteredContent(child: child),
        ),
      ),
    );
  }
}
