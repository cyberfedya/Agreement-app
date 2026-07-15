import 'package:flutter/material.dart';

import 'package:app/l10n/app_localizations.dart';

/// Search field used across the app. When [onTap] is provided (and no
/// controller), the bar acts as a button that leads to the search screen.
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hint,
    this.onTap,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      readOnly: onTap != null,
      onTap: onTap,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint ?? l10n.searchHint,
        prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
        suffixIcon: controller != null
            ? ListenableBuilder(
                listenable: controller!,
                builder: (context, _) => controller!.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: controller!.clear,
                        tooltip: l10n.searchClearTooltip,
                      ),
              )
            : null,
      ),
    );
  }
}
