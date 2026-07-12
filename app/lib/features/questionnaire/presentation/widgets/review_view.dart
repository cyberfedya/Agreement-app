import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/skeletons.dart';
import 'package:app/features/questionnaire/domain/deal_review.dart';
import 'package:app/features/questionnaire/presentation/widgets/confidence_badge.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/shared/animation/entrance.dart';
import 'package:app/shared/widgets/pressable_scale.dart';

/// Final check before generating, rendered entirely from the backend's
/// `GET /deals/{id}/review` (via [QuestionnaireProvider.review]): the
/// backend decides what is auto-filled, manual, corrected, missing or
/// skipped, with source and confidence - nothing is classified locally.
class ReviewView extends StatelessWidget {
  const ReviewView({super.key, required this.templateTitle, this.fallbackMessage});

  final String templateTitle;

  /// Shown under the hero title only when the backend didn't send a
  /// `closingMessage` for this deal - the page picks this once (a
  /// rotating decorative line) so it doesn't reroll on every rebuild.
  final String? fallbackMessage;

  Future<void> _editField(BuildContext context, QuestionnaireProvider provider, DealReviewField field) async {
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => _EditFieldDialog(label: field.label, initialValue: field.value ?? ''),
    );
    if (newValue == null || newValue.trim().isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.editAnswer(field.fieldId, field.label, newValue);
    if (ok) {
      HapticFeedback.selectionClick();
    } else if (context.mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Не удалось сохранить изменение')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<QuestionnaireProvider>(
      builder: (context, provider, _) {
        final review = provider.review;
        if (review == null) return const _ReviewSkeleton();

        final manualCount = review.manual.length;
        var section = 0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x16, Insets.x20, Insets.x32),
          children: [
            Container(
              padding: const EdgeInsets.all(Insets.x20),
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: Corners.lgRadius),
              child: Row(
                children: [
                  Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                        child: const Center(child: Text('🎉', style: TextStyle(fontSize: 22))),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        duration: 450.ms,
                        curve: Curves.easeOutBack,
                      )
                      .fadeIn(duration: 250.ms),
                  const SizedBox(width: Insets.x16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Договор почти готов',
                          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: Insets.x4),
                        Text(
                          provider.closingMessage ?? fallbackMessage ?? 'Проверьте детали — и я подготовлю «$templateTitle».',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animateEntrance(),
            if (review.autoFilledCount > 0 || manualCount > 0) ...[
              const SizedBox(height: Insets.x12),
              Row(
                children: [
                  if (review.autoFilledCount > 0)
                    Expanded(
                      child: _StatChip(
                        icon: Icons.bolt_rounded,
                        value: '${review.autoFilledCount}',
                        label: 'заполнено\nавтоматически',
                      ),
                    ),
                  if (review.autoFilledCount > 0 && manualCount > 0) const SizedBox(width: Insets.x8),
                  if (manualCount > 0)
                    Expanded(
                      child: _StatChip(
                        icon: Icons.edit_outlined,
                        value: '$manualCount',
                        label: manualCount == 1 ? 'вопрос вы\nответили сами' : 'вопроса вы\nответили сами',
                      ),
                    ),
                ],
              ).animateEntranceStaggered(1),
            ],
            if (review.missing.isNotEmpty)
              _Section(
                index: ++section,
                title: 'Не хватает',
                subtitle: 'Без этих данных договор будет неполным',
                children: [
                  for (final field in review.missing)
                    _FieldCard(
                      field: field,
                      emphasizeMissing: true,
                      onTap: () => _editField(context, provider, field),
                    ),
                ],
              ),
            if (review.autoFilled.isNotEmpty)
              _Section(
                index: ++section,
                title: '📄 Заполнено автоматически',
                subtitle: 'Из ваших документов',
                children: [for (final field in review.autoFilled) _FieldCard(field: field, showConfidence: true)],
              ),
            if (review.corrected.isNotEmpty)
              _Section(
                index: ++section,
                title: '✏️ Исправлено вами',
                subtitle: 'Вы поправили то, что распознал документ',
                children: [
                  for (final field in review.corrected)
                    _FieldCard(field: field, onTap: () => _editField(context, provider, field)),
                ],
              ),
            if (review.manual.isNotEmpty)
              _Section(
                index: ++section,
                title: '✍️ Вы указали сами',
                children: [
                  for (final field in review.manual)
                    _FieldCard(field: field, onTap: () => _editField(context, provider, field)),
                ],
              ),
            if (review.skipped.isNotEmpty)
              _Section(
                index: ++section,
                title: '⏭️ Не требуется',
                subtitle: 'Подставляется системой или неактуально для вашего случая',
                children: [for (final field in review.skipped) _FieldCard(field: field, muted: true)],
              ),
          ],
        );
      },
    );
  }
}

/// A single backend-provided count (auto-filled fields, or questions the
/// user answered themselves), rendered as one glanceable stat - no local
/// math beyond formatting a list length already provided by [DealReview].
class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.mdRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: Insets.x8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.index, required this.title, this.subtitle, required this.children});

  final int index;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Insets.x4, Insets.x24, Insets.x4, Insets.x8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
            ],
          ),
        ),
        ...children,
      ],
    ).animateEntranceStaggered(index + 1);
  }
}

/// One backend review field. Editable only when [onTap] is provided (the
/// backend decides what is user-writable by grouping; the card just obeys).
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.field,
    this.onTap,
    this.showConfidence = false,
    this.emphasizeMissing = false,
    this.muted = false,
  });

  final DealReviewField field;
  final VoidCallback? onTap;
  final bool showConfidence;
  final bool emphasizeMissing;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = muted
        ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)
        : theme.textTheme.titleMedium?.copyWith(height: 1.35);

    final card = Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: Corners.lgRadius,
      child: InkWell(
        borderRadius: Corners.lgRadius,
        onTap: onTap,
        child: Container(
          decoration: emphasizeMissing
              ? BoxDecoration(borderRadius: Corners.lgRadius, border: Border.all(color: theme.colorScheme.outline))
              : null,
          padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            field.label,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    if (showConfidence && field.confidence > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: ConfidenceBadge(confidence: field.confidence),
                      ),
                    const SizedBox(height: Insets.x4),
                    Text(
                      field.value ?? (emphasizeMissing ? 'Нажмите, чтобы указать' : field.reason),
                      style: field.value == null && emphasizeMissing
                          ? theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary)
                          : valueStyle,
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: Insets.x12),
                Container(
                  padding: const EdgeInsets.all(Insets.x8),
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh, shape: BoxShape.circle),
                  child: Icon(
                    field.value == null ? Icons.add_rounded : Icons.edit_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.x8),
      child: onTap != null ? PressableScale(scale: 0.985, child: card) : card,
    );
  }
}

/// Shown for the moment between "ready to generate" and the review call
/// returning - same rhythm as the real list, so nothing jumps.
class _ReviewSkeleton extends StatelessWidget {
  const _ReviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x16, Insets.x20, Insets.x32),
      children: const [
        Skeleton(height: 96, radius: Corners.lg),
        SizedBox(height: Insets.x12),
        Skeleton(height: 48, radius: Corners.md),
        SizedBox(height: Insets.x32),
        Skeleton(width: 120, height: 14),
        SizedBox(height: Insets.x12),
        Skeleton(height: 68, radius: Corners.lg),
        SizedBox(height: Insets.x8),
        Skeleton(height: 68, radius: Corners.lg),
        SizedBox(height: Insets.x8),
        Skeleton(height: 68, radius: Corners.lg),
      ],
    );
  }
}

/// Owns its `TextEditingController` for the whole dialog route lifetime -
/// disposing it eagerly right after `showDialog` resolves (rather than
/// letting this widget's own `dispose()` do it once the exit animation
/// actually finishes) crashes the framework, because the still-animating
/// `TextField` tries to rebuild against an already-disposed controller.
class _EditFieldDialog extends StatefulWidget {
  const _EditFieldDialog({required this.label, required this.initialValue});

  final String label;
  final String initialValue;

  @override
  State<_EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<_EditFieldDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отмена')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
