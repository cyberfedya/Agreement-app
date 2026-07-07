import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/config/app_config.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_search_bar.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/templates/presentation/widgets/agreement_card.dart';
import 'package:app/features/templates/providers/templates_list_provider.dart';
import 'package:app/shared/extensions/string_extensions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _exploreCount = 6;
  static const _categoryCount = 8;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TemplatesListProvider>();
    Future.microtask(provider.load);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _openTemplates({String? category}) {
    Navigator.of(context).pushNamed(AppRoutes.templates, arguments: category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Consumer<TemplatesListProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: provider.refresh,
              child: CenteredContent(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x24, Insets.x20, Insets.x40),
                  children: [
                    // Welcome
                    Text(_greeting, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: Insets.x4),
                    Text('Welcome to ${AppConfig.appName}', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: Insets.x8),
                    Text(
                      'Create ready-to-use legal agreements in minutes.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: Insets.x24),

                    // Search (acts as a shortcut into the catalog)
                    AppSearchBar(onTap: _openTemplates),
                    const SizedBox(height: Insets.x24),

                    if (provider.errorMessage != null && provider.templates.isEmpty)
                      AppErrorView(message: provider.errorMessage!, onRetry: provider.refresh)
                    else ...[
                      // Statistics
                      _StatsRow(provider: provider),
                      const SizedBox(height: Insets.x32),

                      // Categories
                      const SectionTitle(title: 'Categories'),
                      const SizedBox(height: Insets.x12),
                      _CategoriesWrap(
                        provider: provider,
                        maxVisible: _categoryCount,
                        onSelected: (category) => _openTemplates(category: category),
                      ),
                      const SizedBox(height: Insets.x32),

                      // Explore rail
                      SectionTitle(
                        title: 'Explore templates',
                        action: TextButton(onPressed: _openTemplates, child: const Text('See all')),
                      ),
                      const SizedBox(height: Insets.x12),
                      _ExploreRail(provider: provider, count: _exploreCount),
                      const SizedBox(height: Insets.x32),

                      // Quick action
                      Card(
                        child: InkWell(
                          onTap: _openTemplates,
                          child: Padding(
                            padding: const EdgeInsets.all(Insets.x20),
                            child: Row(
                              children: [
                                Icon(Icons.grid_view_rounded, color: theme.colorScheme.primary),
                                const SizedBox(width: Insets.x16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Browse all templates', style: theme.textTheme.titleSmall),
                                      const SizedBox(height: Insets.x4),
                                      Text(
                                        'Search the full catalog by name or category.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.provider});

  final TemplatesListProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.templates.isEmpty) {
      return const Row(
        children: [
          Expanded(child: Skeleton(height: 108, radius: Corners.md)),
          SizedBox(width: Insets.x12),
          Expanded(child: Skeleton(height: 108, radius: Corners.md)),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: '${provider.templates.length}',
            label: 'Templates',
            icon: Icons.description_outlined,
          ),
        ),
        const SizedBox(width: Insets.x12),
        Expanded(
          child: StatCard(
            value: '${provider.categories.length}',
            label: 'Categories',
            icon: Icons.category_outlined,
          ),
        ),
      ],
    );
  }
}

class _CategoriesWrap extends StatelessWidget {
  const _CategoriesWrap({required this.provider, required this.maxVisible, required this.onSelected});

  final TemplatesListProvider provider;
  final int maxVisible;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.templates.isEmpty) {
      return const Wrap(
        spacing: Insets.x8,
        runSpacing: Insets.x8,
        children: [
          Skeleton(width: 96, height: 36),
          Skeleton(width: 120, height: 36),
          Skeleton(width: 88, height: 36),
          Skeleton(width: 110, height: 36),
        ],
      );
    }
    final categories = provider.categories.take(maxVisible).toList();
    return Wrap(
      spacing: Insets.x8,
      runSpacing: Insets.x8,
      children: [
        for (final category in categories)
          ActionChip(label: Text(category.asCategoryLabel), onPressed: () => onSelected(category)),
      ],
    );
  }
}

class _ExploreRail extends StatelessWidget {
  const _ExploreRail({required this.provider, required this.count});

  final TemplatesListProvider provider;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.templates.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Row(
          children: [
            Expanded(child: Skeleton(height: 160, radius: Corners.md)),
            SizedBox(width: Insets.x12),
            Expanded(child: Skeleton(height: 160, radius: Corners.md)),
          ],
        ),
      );
    }
    final featured = provider.templates.take(count).toList();
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: featured.length,
        separatorBuilder: (_, _) => const SizedBox(width: Insets.x12),
        itemBuilder: (context, index) {
          final template = featured[index];
          return AgreementRailCard(
            template: template,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.templateDetail, arguments: template.key),
          );
        },
      ),
    );
  }
}
