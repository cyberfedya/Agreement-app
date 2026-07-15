import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/core/widgets/bottom_action_bar.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/deal/data/deal_repository.dart';
import 'package:app/features/templates/presentation/widgets/domain_visuals.dart';
import 'package:app/features/templates/providers/template_detail_provider.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/shared/extensions/string_extensions.dart';
import 'package:app/shared/models/result.dart';
import 'package:app/shared/widgets/primary_button.dart';

class TemplateDetailPage extends StatefulWidget {
  const TemplateDetailPage({super.key, required this.templateKey});

  final String templateKey;

  @override
  State<TemplateDetailPage> createState() => _TemplateDetailPageState();
}

class _TemplateDetailPageState extends State<TemplateDetailPage> {
  bool _creatingDeal = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TemplateDetailProvider>();
    Future.microtask(() => provider.load(widget.templateKey));
  }

  Future<void> _continue(String templateTitle) async {
    setState(() => _creatingDeal = true);
    final result = await context.read<DealRepository>().createFromTemplate(widget.templateKey);
    if (!mounted) return;
    setState(() => _creatingDeal = false);

    switch (result) {
      case Success(:final value):
        Navigator.of(context).pushNamed(
          AppRoutes.questionnaire,
          arguments: QuestionnaireRouteArgs(dealId: value.id, templateTitle: templateTitle),
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.templateDetailTitle)),
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
            return AppEmptyView(
              title: l10n.templateDetailNotFoundTitle,
              message: l10n.templateDetailNotFoundMessage,
            );
          }

          return CenteredContent(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x16, Insets.x20, Insets.x32),
              children: [
                // Hero
                Hero(
                  tag: templateHeroTag(template.key),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: Corners.mdRadius,
                    ),
                    child: Icon(iconForDomain(template.domain), size: 28, color: theme.colorScheme.onPrimaryContainer),
                  ),
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
                        label: l10n.templateDetailCategoryLabel,
                        value: template.domain.categoryLabel(l10n),
                      ),
                    ),
                    if (provider.questionCount != null) ...[
                      const SizedBox(width: Insets.x12),
                      Expanded(
                        child: InfoTile(
                          icon: Icons.quiz_outlined,
                          label: l10n.templateDetailQuestionsLabel,
                          value: '${provider.questionCount}',
                        ),
                      ),
                    ],
                    if (provider.estimatedMinutes != null) ...[
                      const SizedBox(width: Insets.x12),
                      Expanded(
                        child: InfoTile(
                          icon: Icons.schedule_outlined,
                          label: l10n.templateDetailTimeLabel,
                          value: l10n.templateDetailTimeValue(provider.estimatedMinutes!),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Insets.x24),

                // Description
                SectionTitle(title: l10n.templateDetailAboutTitle),
                const SizedBox(height: Insets.x8),
                Text(template.description, style: theme.textTheme.bodyLarge),

                if (template.sourceUrl != null) ...[
                  const SizedBox(height: Insets.x24),
                  SectionTitle(title: l10n.templateDetailSourceTitle),
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
          final l10n = AppLocalizations.of(context)!;
          return BottomActionBar(
            child: PrimaryButton(
              label: l10n.templateDetailContinue,
              icon: Icons.arrow_forward,
              loading: _creatingDeal,
              onPressed: () => _continue(provider.template!.title),
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
