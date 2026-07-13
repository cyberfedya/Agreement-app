import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/domain/question.dart';

/// One assistant turn: a short emotional beat ("Отлично."), then the
/// question as large calm typography - spoken language, not a form label.
/// No question numbers, no "required field" chrome.
class AssistantQuestionView extends StatelessWidget {
  const AssistantQuestionView({
    super.key,
    required this.question,
    this.acknowledgment,
    this.onSpeak,
    this.onWhy,
    this.documentHint,
    this.recap,
  });

  final Question question;

  /// Micro-emotion shown above the question; null on the very first one
  /// (there is nothing to acknowledge yet).
  final String? acknowledgment;
  final VoidCallback? onSpeak;

  /// Opens the "Зачем это нужно?" explanation.
  final VoidCallback? onWhy;

  /// The optional "upload instead of typing" nudge ([DocumentHintCard]),
  /// shown below the question when this field is document-friendly. Kept
  /// in the same scrollable block as the question itself so it reads as
  /// one assistant turn, not a separate interruption.
  final Widget? documentHint;

  /// The "Вы уже сообщили: …" bubble ([ConversationRecap]), shown above
  /// the acknowledgment once at least one answer has been given.
  final Widget? recap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Insets.x24, Insets.x32, Insets.x24, Insets.x24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recap != null) ...[
            recap!.animate().fadeIn(duration: 250.ms, curve: Curves.easeOut),
            const SizedBox(height: Insets.x16),
          ],
          if (acknowledgment != null) ...[
            Text(
              acknowledgment!,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
            ).animate().fadeIn(duration: 250.ms, curve: Curves.easeOut),
            const SizedBox(height: Insets.x12),
          ],
          _ImportanceChip(required: question.required)
              .animate(delay: acknowledgment == null ? 0.ms : 100.ms)
              .fadeIn(duration: 250.ms),
          const SizedBox(height: Insets.x8),
          // The question arrives a beat after the acknowledgment, like a
          // person finishing one thought before starting the next.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question.fieldName,
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.3, fontWeight: FontWeight.w600),
                ),
              ),
              if (onSpeak != null)
                IconButton(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                  tooltip: 'Озвучить',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ).animate(delay: acknowledgment == null ? 0.ms : 180.ms).fadeIn(duration: 320.ms, curve: Curves.easeOut).slideY(begin: 0.05, end: 0, duration: 320.ms, curve: Curves.easeOut),
          if (onWhy != null) ...[
            const SizedBox(height: Insets.x12),
            GestureDetector(
              onTap: onWhy,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Insets.x4),
                  Text(
                    'Зачем это нужно?',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 350.ms).fadeIn(duration: 250.ms),
          ],
          if (documentHint != null) ...[
            const SizedBox(height: Insets.x20),
            documentHint!,
          ],
        ],
      ),
    );
  }
}

/// The only two importance states the backend actually exposes
/// ([Question.required]) - styled to feel like a gentle label, not a
/// form-validation warning: required uses the calm primary tint, optional
/// stays neutral. There is no "recommended" tier because the backend
/// doesn't send one - inventing a third state here would be exactly the
/// kind of local business logic this screen must not have.
class _ImportanceChip extends StatelessWidget {
  const _ImportanceChip({required this.required});

  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = required ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x8 + 2, vertical: 3),
      decoration: BoxDecoration(
        color: required ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        required ? 'Обязательно' : 'Необязательно',
        style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
