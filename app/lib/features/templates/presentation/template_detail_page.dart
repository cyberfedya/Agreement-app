import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/templates/providers/template_detail_provider.dart';
import 'package:app/shared/extensions/string_extensions.dart';
import 'package:app/shared/widgets/primary_button.dart';

class TemplateDetailPage extends StatefulWidget {
  const TemplateDetailPage({super.key, required this.templateKey});

  final String templateKey;

  @override
  State<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends State<TemplateDetailPage> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<TemplateDetailProvider>();
    Future.microtask(() => provider.load(widget.templateKey));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Template')),
      body: Consumer<TemplateDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const _DetailSkeleton();
          }
          if (provider.errorMessage != null) {
            return AppErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.load(widget.templateKey),
            );
          }

          final template = provider.template;
          if (template == null) {
            return const AppEmptyView(title: 'Not found', message: 'This agreement template is unavailable.');
          }

          return CenteredContent(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x16, Insets.x20, Insets.x32),
              children: [
                // Hero
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: Corners.mdRadius,
                  ),
                  child: Icon(Icons.description_outlined, size: 28, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: Insets.x16),
                Text(template.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: Insets.x16),

                // Facts
                Row(
                  children: [
                    Expanded(
                      child: InfoTile(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: template.domain.asCategoryLabel,
                      ),
                    ),
                    if (provider.questionCount != null) ...[
                      const SizedBox(width: Insets.x12),
                      Expanded(
                        child: InfoTile(
                          icon: Icons.quiz_outlined,
                          label: 'Questions',
                          value: '${provider.questionCount}',
                        ),
                      ),
                    ],
                    if (provider.estimatedMinutes != null) ...[
                      const SizedBox(width: Insets.x12),
                      Expanded(
                        child: InfoTile(
                          icon: Icons.schedule_outlined,
                          label: 'Est. time',
                          value: '~${provider.estimatedMinutes} min',
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Insets.x24),

                // Description
                const SectionTitle(title: 'About this agreement'),
                const SizedBox(height: Insets.x8),
                Text(template.description, style: theme.textTheme.bodyLarge),

                if (template.sourceUrl != null) ...[
                  const SizedBox(height: Insets.x24),
                  const SectionTitle(title: 'Source'),
                  const SizedBox(height: Insets.x8),
                  Text(
                    template.sourceUrl!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<TemplateDetailProvider>(
        builder: (context, provider, _) {
          if (provider.template == null) return const SizedBox.shrink();
          return BottomActionBar(
            child: PrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: () => Navigator.of(context)
                  .pushNamed(AppRoutes.questionnaire, arguments: widget.templateKey),
            ),
          );
        },
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const CenteredContent(
      child: Padding(
        padding: EdgeInsets.all(Insets.x20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 56, height: 56, radius: Corners.md),
            SizedBox(height: Insets.x16),
            Skeleton(width: 280, height: 24),
            SizedBox(height: Insets.x8),
            Skeleton(width: 200, height: 24),
            SizedBox(height: Insets.x24),
            Row(
              children: [
                Expanded(child: Skeleton(height: 88, radius: Corners.md)),
                SizedBox(width: Insets.x12),
                Expanded(child: Skeleton(height: 88, radius: Corners.md)),
                SizedBox(width: Insets.x12),
                Expanded(child: Skeleton(height: 88, radius: Corners.md)),
              ],
            ),
            SizedBox(height: Insets.x24),
            Skeleton(height: 14),
            SizedBox(height: Insets.x8),
            Skeleton(height: 14),
            SizedBox(height: Insets.x8),
            Skeleton(width: 220, height: 14),
          ],
        ),
      ),
    );
  }
}
