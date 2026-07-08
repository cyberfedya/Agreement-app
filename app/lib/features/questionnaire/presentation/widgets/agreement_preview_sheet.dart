import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/domain/question.dart';

/// Full-document preview: every field the questionnaire will fill in, with
/// answered fields shown and empty ones highlighted — so the user always
/// sees *why* the current question is being asked.
class AgreementPreviewSheet extends StatelessWidget {
  const AgreementPreviewSheet({super.key, required this.questions, required this.answers});

  final List<Question> questions;
  final Map<int, String> answers;

  static Future<void> show(
    BuildContext context, {
    required List<Question> questions,
    required Map<int, String> answers,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgreementPreviewSheet(questions: questions, answers: answers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(Corners.xl)),
          ),
          child: Column(
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
                padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x16, Insets.x20, Insets.x8),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: Insets.x8),
                    Text('Предпросмотр договора', style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(Insets.x20),
                  itemCount: questions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Insets.x16),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final answer = answers[question.fieldId]?.trim() ?? '';
                    final filled = answer.isNotEmpty;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          filled ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 18,
                          color: filled ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: Insets.x12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.fieldName,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: Insets.x4),
                              Text(
                                filled ? answer : 'Пока не заполнено',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: filled ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                                  fontStyle: filled ? FontStyle.normal : FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
