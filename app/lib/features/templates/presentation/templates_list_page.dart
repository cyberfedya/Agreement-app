import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_search_bar.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/templates/domain/template.dart';
import 'package:app/features/templates/presentation/widgets/agreement_card.dart';
import 'package:app/features/templates/presentation/widgets/category_chip.dart';
import 'package:app/features/templates/providers/templates_list_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/animation/entrance.dart';

class TemplatesListPage extends StatefulWidget {
  const TemplatesListPage({super.key, this.initialCategory, this.initialQuery});

  /// Pre-selects a category filter (used when arriving from Home).
  final String? initialCategory;

  /// Pre-fills the search box (used when arriving from the Home composer).
  final String? initialQuery;

  @override
  State<TemplatesListPage> createState() => _TemplatesListPageState();
}

class _TemplatesListPageState extends State<TemplatesListPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!.trim();
      _query = _searchController.text.toLowerCase();
    }
    final provider = context.read<TemplatesListProvider>();
    Future.microtask(provider.load);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TemplateSummary> _filter(List<TemplateSummary> templates) {
    return templates.where((t) {
      if (_selectedCategory != null && t.domain != _selectedCategory) return false;
      if (_query.isEmpty) return true;
      return t.title.toLowerCase().contains(_query) ||
          t.description.toLowerCase().contains(_query) ||
          t.domain.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.templatesTitle)),
      body: CenteredContent(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x8, Insets.x20, 0),
              child: AppSearchBar(controller: _searchController, autofocus: false),
            ),
            const SizedBox(height: Insets.x12),
            _CategoryFilterRow(
              selected: _selectedCategory,
              onChanged: (category) => setState(() => _selectedCategory = category),
            ),
            const SizedBox(height: Insets.x4),
            Expanded(
              child: Consumer<TemplatesListProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.templates.isEmpty) {
                    return const SkeletonList();
                  }
                  if (provider.errorMessage != null && provider.templates.isEmpty) {
                    return AppErrorView(message: provider.errorMessage!, onRetry: provider.refresh);
                  }
                  final templates = _filter(provider.templates);
                  if (templates.isEmpty) {
                    return AppEmptyView(
                      title: l10n.templatesNothingFoundTitle,
                      message: l10n.templatesNothingFoundMessage,
                      action: (_query.isNotEmpty || _selectedCategory != null)
                          ? OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _selectedCategory = null);
                              },
                              child: Text(l10n.templatesResetFilters),
                            )
                          : null,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: provider.refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x12, Insets.x20, Insets.x32),
                      itemCount: templates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: Insets.x12),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return AgreementCard(
                          template: template,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.templateDetail, arguments: template.key),
                        ).animateEntranceStaggered(index.clamp(0, 8));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: Selector<TemplatesListProvider, List<String>>(
        selector: (_, provider) => provider.categories,
        builder: (context, categories, _) {
          if (categories.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Insets.x20),
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: Insets.x8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return FilterChip(
                  label: Text(l10n.templatesAll),
                  selected: selected == null,
                  showCheckmark: false,
                  onSelected: (_) => onChanged(null),
                );
              }
              final category = categories[index - 1];
              return CategoryChip(
                category: category,
                selected: selected == category,
                onSelected: (_) => onChanged(selected == category ? null : category),
              );
            },
          );
        },
      ),
    );
  }
}
