import 'package:flutter/material.dart';

import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/questionnaire/domain/question.dart';

/// One full-screen question: large readable label, requirement hint, and a
/// spacious answer field.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  final Question question;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x20, Insets.x24, Insets.x20, Insets.x24),
      children: [
        Text(
          question.required ? 'Required' : 'Optional',
          style: theme.textTheme.labelLarge?.copyWith(
            color: question.required ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Insets.x8),
        Text(question.fieldName, style: theme.textTheme.headlineSmall?.copyWith(height: 1.3)),
        const SizedBox(height: Insets.x24),
        TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          minLines: 1,
          maxLines: 6,
          style: theme.textTheme.bodyLarge,
          decoration: const InputDecoration(hintText: 'Type your answer…'),
        ),
      ],
    );
  }
}
