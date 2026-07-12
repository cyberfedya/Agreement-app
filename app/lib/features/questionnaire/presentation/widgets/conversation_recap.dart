import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:app/core/theme/app_tokens.dart';

/// "Вы уже сообщили: ✓ Марка ✓ Модель ✓ VIN" - a small collapsed bubble
/// that expands to the labels of everything answered so far, so the
/// interview reads as one continuous conversation the assistant
/// remembers, not a sequence of unrelated questions. [answeredLabels] is
/// already-ordered, backend-sourced field labels - this widget only
/// formats and animates them.
class ConversationRecap extends StatefulWidget {
  const ConversationRecap({super.key, required this.answeredLabels});

  final List<String> answeredLabels;

  @override
  State<ConversationRecap> createState() => _ConversationRecapState();
}

class _ConversationRecapState extends State<ConversationRecap> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.answeredLabels.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final count = widget.answeredLabels.length;

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
                      'Вы уже сообщили: $count',
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
                        for (final (index, label) in widget.answeredLabels.indexed)
                          _RecapChip(label: label).animate().fadeIn(
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
  const _RecapChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x12, vertical: Insets.x4 + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: Insets.x4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
