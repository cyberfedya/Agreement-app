import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/presentation/widgets/edit_field_dialog.dart';
import 'package:app/features/questionnaire/providers/questionnaire_provider.dart';
import 'package:app/l10n/app_localizations.dart';

/// One already-answered field: enough to render a chip and let the user
/// correct it without re-deriving anything from raw provider state.
typedef AnsweredEntry = ({int fieldId, String label, String value});

/// "Вы уже сообщили: ✓ Chevrolet Cobalt ✓ 2023" - a small collapsed bubble
/// that expands to what's been answered so far, each entry tappable to fix
/// it on the spot - so the interview reads as one continuous conversation
/// the assistant remembers, not a sequence of unrelated questions.
/// [answeredFields] is already-ordered, backend-sourced data - this widget
/// only formats, animates, and wires up the edit action.
class ConversationRecap extends StatefulWidget {
  const ConversationRecap({super.key, required this.answeredFields});

  final List<AnsweredEntry> answeredFields;

  @override
  State<ConversationRecap> createState() => _ConversationRecapState();
}

class _ConversationRecapState extends State<ConversationRecap> {
  bool _expanded = false;

  Future<void> _edit(BuildContext context, AnsweredEntry entry) async {
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => EditFieldDialog(label: entry.label, initialValue: entry.value),
    );
    if (newValue == null || newValue.trim().isEmpty || !context.mounted) return;
    if (newValue.trim() == entry.value) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<QuestionnaireProvider>();
    final ok = await provider.editAnswer(entry.fieldId, entry.label, newValue);
    if (ok) {
      HapticFeedback.selectionClick();
    } else if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.reviewEditSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.answeredFields.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final count = widget.answeredFields.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: Corners.lgRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x16, vertical: Insets.x12),
              child: Row(
                children: [
                  Icon(Icons.forum_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: Insets.x8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.questionnaireAlreadyTold(count),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: Motion.fast,
                    child: Icon(Icons.expand_more_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.normal,
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(Insets.x16, 0, Insets.x16, Insets.x12),
                    child: Wrap(
                      spacing: Insets.x8,
                      runSpacing: Insets.x8,
                      children: [
                        for (final (index, entry) in widget.answeredFields.indexed)
                          _RecapChip(entry: entry, onTap: () => _edit(context, entry)).animate().fadeIn(
                            duration: 200.ms,
                            delay: (index * 30).ms,
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _RecapChip extends StatelessWidget {
  const _RecapChip({required this.entry, required this.onTap});

  final AnsweredEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.x12, vertical: Insets.x4 + 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: Insets.x4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(entry.value, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: Insets.x4),
              Icon(Icons.edit_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: Insets.x4 - 2),
              Text(
                l10n.questionnaireEditAnswer,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
