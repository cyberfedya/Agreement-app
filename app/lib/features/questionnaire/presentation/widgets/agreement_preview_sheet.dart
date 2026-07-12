import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';

/// The live agreement: a paper-styled document where every answered field
/// materializes as real text and every missing one stays a soft blank
/// line. Watches [QuestionnaireProvider] directly, so it updates by itself
/// while open - no refresh anywhere.
class AgreementPreviewSheet extends StatelessWidget {
  const AgreementPreviewSheet({super.key, required this.title});

  final String title;

  static Future<void> show(BuildContext context, {required String title}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgreementPreviewSheet(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Corners.x2l)),
          ),
          child: Consumer<QuestionnaireProvider>(
            builder: (context, provider, _) {
              final questions = provider.allFields;
              final answers = provider.answers;
              final filled = questions.where((q) => (answers[q.fieldId] ?? '').trim().isNotEmpty).length;
              final progress = questions.isEmpty ? 0.0 : filled / questions.length;

              return Column(
                children: [
                  const SizedBox(height: Insets.x12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x16, Insets.x24, Insets.x12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Договор создаётся в реальном времени', style: theme.textTheme.titleSmall),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.x24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 600),
                        curve: Motion.emphasized,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 3,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(Insets.x16),
                      // The "paper": a white page floating on the sheet's
                      // grey backdrop.
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x32, Insets.x24, Insets.x40),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: Corners.mdRadius,
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                title.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 1.2),
                              ),
                            ),
                            const SizedBox(height: Insets.x8),
                            Center(
                              child: Container(width: 56, height: 2, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: Insets.x24),
                            for (final question in questions) ...[
                              _DocumentLine(
                                label: question.fieldName,
                                value: (answers[question.fieldId] ?? '').trim(),
                              ),
                              const SizedBox(height: Insets.x16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// One clause of the paper document. A filled value crossfades in over its
/// blank placeholder the moment the answer lands, then briefly glows
/// brighter than the resting highlight before settling - so a clause that
/// was *just* confirmed reads differently from one that filled in a while
/// ago, even though both are now "done".
class _DocumentLine extends StatefulWidget {
  const _DocumentLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  State<_DocumentLine> createState() => _DocumentLineState();
}

class _DocumentLineState extends State<_DocumentLine> with SingleTickerProviderStateMixin {
  late final AnimationController _highlight = AnimationController(vsync: this, duration: 1100.ms);

  @override
  void didUpdateWidget(covariant _DocumentLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.isEmpty && widget.value.isNotEmpty) {
      _highlight.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _highlight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = widget.value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: Insets.x4),
        AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.curve,
          child: filled
              ? AnimatedBuilder(
                  key: const ValueKey('value'),
                  animation: _highlight,
                  builder: (context, child) {
                    final restingTint = theme.colorScheme.primaryContainer.withValues(alpha: 0.45);
                    final freshTint = theme.colorScheme.primary.withValues(alpha: 0.35);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.x4 + 2, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color.lerp(freshTint, restingTint, Curves.easeOut.transform(_highlight.value)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: child,
                    );
                  },
                  child: Text(widget.value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                )
              : Container(
                  key: const ValueKey('blank'),
                  width: 180,
                  height: 12,
                  margin: const EdgeInsets.symmetric(vertical: Insets.x4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
        ),
      ],
    );
  }
}
