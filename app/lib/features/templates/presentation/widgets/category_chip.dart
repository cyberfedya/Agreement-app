import 'package:flutter/material.dart';

import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/extensions/string_extensions.dart';

/// Selectable category filter chip. Renders the raw category slug as a
/// human-readable label.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final String category;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FilterChip(
      label: Text(category.categoryLabel(l10n)),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected,
    );
  }
}
